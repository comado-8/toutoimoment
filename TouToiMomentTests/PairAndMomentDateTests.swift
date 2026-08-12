import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import TouToiMoment

@MainActor
struct PairAndMomentDateTests {
    @Test func persistentPairRepositoryMigratesMomentSnapshotsAndPersistsNewPairs() async throws {
        let container = try ModelContainer(
            for: PersistedPairState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let moment = MomentCardModel(
            id: "moment-pair-migration",
            sceneText: "Scene",
            heartText: "Heart",
            caption: "",
            pairID: "pair-migrated",
            pairName: "A ・ B",
            sourceID: nil,
            sourceName: "—",
            mediaType: nil,
            contextValues: [],
            reactionIDs: [],
            reactionLabels: [],
            leadingDotColor: Color(hex: "#112233"),
            trailingDotColor: Color(hex: "#445566"),
            createdAt: Date(timeIntervalSince1970: 1),
            isFavorite: false
        )
        let repository = try PersistentPairRepository(
            context: container.mainContext,
            moments: [moment]
        )
        let migrated = try #require(
            await repository.fetchPairs().first(where: { $0.id == "pair-migrated" })
        )
        #expect(migrated.momentCount == 1)
        #expect(migrated.leadingColorHex == "#112233")

        let created = try await repository.createPair(
            request: PairCreateRequest(
                member1Name: "C",
                member2Name: "D",
                nickname: "CD",
                leadingColorHex: "#123456",
                trailingColorHex: "#654321"
            )
        )
        let reloaded = try PersistentPairRepository(context: container.mainContext, moments: [])
        #expect(try await reloaded.fetchPairs().contains(where: { $0.id == created.id }))
    }

    @Test func persistentPairRepositoryDoesNotOverwriteCorruptState() throws {
        let container = try ModelContainer(
            for: PersistedPairState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let corruptPayload = Data("not-json".utf8)
        container.mainContext.insert(PersistedPairState(payload: corruptPayload))
        try container.mainContext.save()

        #expect(throws: DecodingError.self) {
            _ = try PersistentPairRepository(context: container.mainContext, moments: [])
        }
        let state = try #require(
            container.mainContext.fetch(FetchDescriptor<PersistedPairState>()).first
        )
        #expect(state.payload == corruptPayload)
    }

    @Test func pairRepositoryUpdatesAndDeletesPersistently() async throws {
        let container = try ModelContainer(
            for: PersistedPairState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = try PersistentPairRepository(context: container.mainContext, moments: [])
        let created = try await repository.createPair(
            request: PairCreateRequest(
                member1Name: "Alpha",
                member2Name: "Beta",
                nickname: "AB",
                leadingColorHex: "#123456",
                trailingColorHex: "#ABCDEF"
            )
        )
        let updated = try await repository.updatePair(
            id: created.id,
            request: PairUpdateRequest(
                member1Name: "Alpha",
                member2Name: "Gamma",
                nickname: "AG",
                leadingColorHex: "#654321",
                trailingColorHex: nil
            )
        )

        #expect(updated.id == created.id)
        #expect(updated.displayName == "AG")
        #expect(updated.memberDisplayName == "Alpha ・ Gamma")
        #expect(updated.nickname == "AG")
        #expect(updated.trailingColorHex == nil)

        let reloaded = try PersistentPairRepository(context: container.mainContext, moments: [])
        #expect(try await reloaded.fetchPairs().contains(updated))
        try await reloaded.deletePair(id: created.id)

        let afterDeletion = try PersistentPairRepository(context: container.mainContext, moments: [])
        #expect(try await !afterDeletion.fetchPairs().contains(where: { $0.id == created.id }))
    }

    @Test func pairEditorDraftValidatesAndBuildsRequests() throws {
        var draft = PairEditorDraft(
            member1Name: "  Alpha  ",
            member2Name: " Beta ",
            nickname: " AB ",
            leadingColorHex: "#403CF8",
            trailingColorHex: "#FCA8D9",
            usesTrailingColor: false
        )
        let request = try #require(draft.makeCreateRequest())
        #expect(request.member1Name == "Alpha")
        #expect(request.member2Name == "Beta")
        #expect(request.nickname == "AB")
        #expect(request.trailingColorHex == nil)

        draft.member1Name = "   "
        #expect(!draft.isValid)
        #expect(draft.makeUpdateRequest() == nil)
    }

    @Test func pairDisplayNameFallsBackToMembersAndLegacyJSONMigrates() throws {
        let legacyJSON = Data(##"{"id":"legacy","displayName":"Alice × Bob","nickname":"AB","momentCount":2,"leadingColorHex":"#123456","trailingColorHex":"#654321","isFavorite":false}"##.utf8)
        let pair = try JSONDecoder().decode(PairSummary.self, from: legacyJSON)

        #expect(pair.member1Name == "Alice")
        #expect(pair.member2Name == "Bob")
        #expect(pair.displayName == "AB")
        #expect(pair.memberDisplayName == "Alice ・ Bob")

        let withoutNickname = PairEditorDraft(member1Name: "Alice", member2Name: "Bob")
        #expect(withoutNickname.displayName == "Alice ・ Bob")
    }

    @Test func momentSearchIncludesMembersWhenNicknameIsDisplayed() {
        let moment = MomentCardModel(
            id: "member-search",
            sceneText: "Scene",
            heartText: "Heart",
            caption: "",
            pairID: "pair-1",
            pairName: "尊い組",
            pairMemberNames: ["Alice", "Bob"],
            sourceID: nil,
            sourceName: "—",
            mediaType: nil,
            contextValues: [],
            reactionIDs: [],
            reactionLabels: [],
            leadingDotColor: .blue,
            trailingDotColor: .pink,
            createdAt: .now,
            isFavorite: false
        )

        #expect(moment.searchableText.localizedStandardContains("Alice"))
        #expect(moment.searchableText.localizedStandardContains("Bob"))
        #expect(moment.searchableText.localizedStandardContains("尊い組"))
    }

    @Test func momentStoreUpdatesAndClearsPairSnapshots() {
        let moment = MomentCardModel(
            id: "pair-reference",
            sceneText: "Scene",
            heartText: "Heart",
            caption: "",
            pairID: "pair-1",
            pairName: "Old Pair",
            sourceID: nil,
            sourceName: "—",
            mediaType: nil,
            contextValues: [],
            reactionIDs: [],
            reactionLabels: [],
            leadingDotColor: Color(hex: "#111111"),
            trailingDotColor: Color(hex: "#222222"),
            createdAt: .now,
            isFavorite: false
        )
        let store = MomentStore(moments: [moment])

        store.updatePairReference(
            id: "pair-1",
            displayName: "New Pair",
            member1Name: "Alpha",
            member2Name: "Beta",
            leadingColorHex: "#123456",
            trailingColorHex: nil
        )
        let updated = store.moment(id: moment.id)
        #expect(updated?.pairName == "New Pair")
        #expect(updated?.pairMemberNames == ["Alpha", "Beta"])
        #expect(updated.map { PersistedMomentSnapshot.hex($0.leadingDotColor) } == "#123456")
        #expect(updated.map { PersistedMomentSnapshot.hex($0.trailingDotColor) } == "#123456")

        store.clearPairReferences(id: "pair-1")
        #expect(store.moment(id: moment.id)?.pairID == nil)
        #expect(store.moment(id: moment.id)?.pairName == "—")
    }

    @Test func legacyMomentWithoutMomentDateUsesCreatedAtDay() throws {
        let createdAt = Date(timeIntervalSince1970: 1_767_225_600)
        let moment = MomentCardModel(
            id: "legacy-date",
            sceneText: "Scene",
            heartText: "Heart",
            caption: "",
            pairID: nil,
            pairName: "—",
            sourceID: nil,
            sourceName: "—",
            mediaType: nil,
            contextValues: [],
            reactionIDs: [],
            reactionLabels: [],
            leadingDotColor: .blue,
            trailingDotColor: .pink,
            createdAt: createdAt,
            isFavorite: false
        )
        let encoded = try JSONEncoder().encode(PersistedMomentSnapshot(moment: moment))
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "momentDate")
        let legacy = try JSONDecoder().decode(
            PersistedMomentSnapshot.self,
            from: JSONSerialization.data(withJSONObject: object)
        )
        #expect(legacy.moment.momentDate == MomentDate(date: createdAt))
    }

    @Test func cardDateUsesLocaleOrderAndShowsYearOnlyForOtherYears() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 7))!
        let currentYear = MomentDate(year: 2026, month: 8, day: 7)
        let priorYear = MomentDate(year: 2025, month: 8, day: 7)

        let us = currentYear.cardText(
            relativeTo: reference,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        let gb = currentYear.cardText(
            relativeTo: reference,
            calendar: calendar,
            locale: Locale(identifier: "en_GB")
        )
        let old = priorYear.cardText(
            relativeTo: reference,
            calendar: calendar,
            locale: Locale(identifier: "ja_JP")
        )

        #expect(us != gb)
        #expect(!us.contains("2026"))
        #expect(old.contains("2025"))
    }
}
