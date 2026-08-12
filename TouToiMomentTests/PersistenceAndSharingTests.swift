import SwiftData
import SwiftUI
import Testing
@testable import TouToiMoment

@MainActor
struct PersistenceAndSharingTests {
    @Test func sourceFixturesPersistOnceAndMutationsSurviveRepositoryRecreation() async throws {
        let container = try ModelContainer(
            for: PersistedSourceState.self,
            PersistedMomentState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let first = try PersistentSourceRepository(context: container.mainContext)
        let initialCount = try await first.fetchSources().count
        let created = try await first.createSource(
            request: SourceCreateRequest(
                displayName: "Persisted Source",
                helperText: "Anime",
                mediaType: "anime",
                relatedURL: URL(string: "https://example.com/persisted")!
            )
        )

        let restored = try PersistentSourceRepository(context: container.mainContext)
        let sources = try await restored.fetchSources()
        #expect(sources.count == initialCount + 1)
        #expect(sources.filter { $0.id == created.id }.count == 1)
    }

    @Test func momentMetadataPersistsAndRestoresTitleAndSceneNote() throws {
        let container = try ModelContainer(
            for: PersistedSourceState.self,
            PersistedMomentState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let persistence = SwiftDataMomentStorePersistence(context: container.mainContext)
        var draft = NewMomentDraft(
            momentTitle: "  Reunion  ",
            sceneSummary: "The door opens.",
            heartScream: "待ってた"
        )
        draft.selectSource(
            id: "source",
            displayName: "Source",
            helperText: "Anime",
            mediaType: "anime"
        )
        let first = MomentStore(moments: [], persistence: persistence)
        first.add(draft: draft, id: "persisted-moment")
        try persistence.save(first.moments)

        let restored = MomentStore(persistence: persistence)
        #expect(restored.moment(id: "persisted-moment")?.title == "Reunion")
        #expect(restored.moment(id: "persisted-moment")?.sceneNote == "The door opens.")
        #expect(restored.moment(id: "persisted-moment")?.displayHeading == "Reunion")
    }

    @Test func deletingEpisodeRemovesHistoryButSavedMomentCanBeDetached() async throws {
        let repository = InMemorySourceRepository()
        let store = MomentStore(moments: [
            MomentCardModel(
                id: "saved",
                sceneText: "Scene",
                heartText: "Heart",
                caption: "",
                pairID: nil,
                pairName: "—",
                sourceID: "solo-leveling",
                sourceName: "Solo Leveling 第2期",
                mediaType: "anime",
                episodeID: "solo-leveling-ep08",
                contextValues: [],
                reactionIDs: [],
                reactionLabels: [],
                leadingDotColor: .appPrimary,
                trailingDotColor: .appAccent,
                createdAt: .now,
                isFavorite: false
            ),
        ])

        try await repository.deleteEpisode(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08"
        )
        store.detachEpisodeReferences(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08"
        )

        let detail = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        #expect(!detail.episodes.contains { $0.id == "solo-leveling-ep08" })
        #expect(store.moment(id: "saved")?.sourceID == "solo-leveling")
        #expect(store.moment(id: "saved")?.episodeID == nil)
    }

    @Test func deletingHistoryDecrementsViewCountAndKeepsEpisodeMomentCount() async throws {
        let repository = InMemorySourceRepository()
        let beforeDetail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let before = try #require(
            beforeDetail.episodes.first { $0.id == "solo-leveling-ep08" }
        )
        let session = try #require(before.watchingSessions.first)

        try await repository.deleteWatchingSession(
            sourceID: "solo-leveling",
            episodeID: before.id,
            sessionID: session.id
        )

        let afterDetail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let after = try #require(afterDetail.episodes.first { $0.id == before.id })
        #expect(after.viewedCount == max(0, before.viewedCount - 1))
        #expect(after.momentCount == before.momentCount)
        #expect(!after.watchingSessions.contains { $0.id == session.id })
    }

    @Test func savedMomentReferencesRecalculateSourceAndEpisodeCounts() async throws {
        let repository = InMemorySourceRepository()
        try await repository.synchronizeMomentCounts(
            MomentReferenceCounts(
                bySourceID: ["solo-leveling": 2],
                byEpisodeID: ["solo-leveling-ep08": 1]
            )
        )

        let detail = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        let episode = try #require(
            detail.episodes.first { $0.id == "solo-leveling-ep08" }
        )
        #expect(detail.summary.momentCount == 2)
        #expect(episode.momentCount == 1)
    }

    @Test func episodeTitleCanBeExplicitlyClearedWithoutBreakingLegacyUpdates() async throws {
        let repository = InMemorySourceRepository()
        let detail = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        let episode = try #require(
            detail.episodes.first { $0.id == "solo-leveling-ep08" }
        )

        let cleared = try await repository.updateEpisode(
            sourceID: detail.id,
            episodeID: episode.id,
            request: EpisodeCreateRequest(
                locatorValues: episode.locatorValues,
                relatedURL: episode.relatedURL,
                displayTitle: nil,
                updatesDisplayTitle: true
            )
        )
        #expect(cleared.displayTitle == nil)
    }

    @Test func momentTitlePolicyLimitsNormalizesAndFallsBack() {
        #expect(MomentTitlePolicy.normalized("   ") == nil)
        #expect(MomentTitlePolicy.normalized(String(repeating: "a", count: 21))?.count == 20)

        let moment = MomentCardModel(
            id: "fallback",
            sceneText: "",
            heartText: "Heart fallback",
            caption: "",
            pairID: nil,
            pairName: "—",
            sourceID: nil,
            sourceName: "—",
            mediaType: nil,
            contextValues: [],
            reactionIDs: [],
            reactionLabels: [],
            leadingDotColor: .appPrimary,
            trailingDotColor: .appAccent,
            createdAt: .now,
            isFavorite: false
        )
        #expect(moment.displayHeading == "Heart fallback")
    }

    @Test func xShareNormalizesWhitespaceHashesAndDuplicates() {
        let draft = XShareDraft(
            body: "尊い",
            autoHashtags: " TouToiMoment  ##推し活, #toutoimoment "
        )
        #expect(draft.hashtags == ["#TouToiMoment", "#推し活"])
        #expect(draft.text.hasSuffix("#TouToiMoment\n\n#推し活"))
    }
}
