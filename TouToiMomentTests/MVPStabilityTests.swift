import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import TouToiMoment

@MainActor
struct MVPStabilityTests {
    @Test func momentStoreWithPersistenceDoesNotSeedOrWritePreviewData() {
        let persistence = FailingMomentPersistence(loadResult: nil, shouldFailSave: false)

        let store = MomentStore(
            imageRepository: EmptyMomentImageRepository(),
            persistence: persistence
        )

        #expect(store.moments.isEmpty)
        #expect(persistence.savedValues.isEmpty)
    }

    @Test func momentStorePublishesPersistenceFailure() {
        let persistence = FailingMomentPersistence(loadResult: [], shouldFailSave: true)
        let store = MomentStore(
            moments: [Self.moment(id: "persist-failure")],
            imageRepository: EmptyMomentImageRepository(),
            persistence: persistence
        )

        store.toggleFavorite(id: "persist-failure")

        #expect(store.persistenceError != nil)
    }

    @Test func persistentSourceRepositoryDoesNotOverwriteCorruptState() throws {
        let container = try ModelContainer(
            for: PersistedSourceState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let corruptPayload = Data("not-json".utf8)
        container.mainContext.insert(
            PersistedSourceState(fixtureVersion: 1, payload: corruptPayload)
        )
        try container.mainContext.save()

        #expect(throws: DecodingError.self) {
            _ = try PersistentSourceRepository(context: container.mainContext)
        }
        let state = try #require(
            container.mainContext.fetch(FetchDescriptor<PersistedSourceState>()).first
        )
        #expect(state.payload == corruptPayload)
    }

    @Test func sourceCreateUpdateAndDeleteRollBackWhenPersistenceFails() async throws {
        let initial = Self.source(id: "existing", displayName: "Existing")
        let repository = InMemorySourceRepository(
            sources: [initial],
            onChange: { _ in throw MVPTestError.expected }
        )

        await #expect(throws: MVPTestError.expected) {
            _ = try await repository.createSource(
                request: SourceCreateRequest(
                    displayName: "Created",
                    helperText: "Anime",
                    mediaType: "anime",
                    relatedURL: URL(string: "https://example.com/created")!
                )
            )
        }
        #expect(try await repository.fetchSources() == [initial])

        await #expect(throws: MVPTestError.expected) {
            _ = try await repository.updateSource(
                id: initial.id,
                request: SourceUpdateRequest(
                    displayName: "Changed",
                    relatedURL: URL(string: "https://example.com/changed")!
                )
            )
        }
        #expect(try await repository.fetchSources() == [initial])

        await #expect(throws: MVPTestError.expected) {
            try await repository.deleteSource(id: initial.id)
        }
        #expect(try await repository.fetchSources() == [initial])
        #expect(try await repository.fetchSourceDetail(id: initial.id)?.summary == initial)
    }

    @Test func settingsLoadFailureDoesNotWriteDefaultsAndCanRecoverByReloading() throws {
        let repository = RecoveringSettingsRepository()
        let store = SettingsStore(repository: repository)

        #expect(!store.isLoaded)
        #expect(store.loadError != nil)
        store.setKeepScreenAwake(false)
        #expect(repository.saveCount == 0)

        repository.shouldFailLoad = false
        try store.reloadFromPersistence()
        store.setKeepScreenAwake(false)
        #expect(store.isLoaded)
        #expect(store.loadError == nil)
        #expect(repository.saveCount == 1)
        #expect(!store.settings.keepScreenAwake)
    }

    @Test func momentDateRoundTripsAcrossTimeZoneBoundariesWithGregorianCalendar() {
        for identifier in ["Pacific/Kiritimati", "America/Adak"] {
            var calendar = Calendar(identifier: .buddhist)
            calendar.timeZone = TimeZone(identifier: identifier)!
            let value = MomentDate(year: 2026, month: 1, day: 1)

            #expect(MomentDate(date: value.date(calendar: calendar), calendar: calendar) == value)
        }
    }

    @Test func streamingPlatformAppliesCustomNamePolicyWhenDecoding() throws {
        let longName = String(repeating: "A", count: StreamingPlatformNamePolicy.maximumLength + 10)
        let data = try JSONEncoder().encode(["id": "other", "customName": "  \(longName)  "])

        let decoded = try JSONDecoder().decode(StreamingPlatform.self, from: data)

        #expect((decoded.customName?.count ?? 0) <= StreamingPlatformNamePolicy.maximumLength)
        #expect(decoded.customName == decoded.customName?.trimmingCharacters(in: .whitespacesAndNewlines))
        #expect(decoded.customName?.hasPrefix("A") == true)
    }

    @Test func exportDocumentFilenameIsStableAfterInitialization() {
        let document = EpisodeTimelineExportDocument(
            sourceName: "Source",
            locatorDisplayName: "Episode 1",
            episodeDisplayTitle: nil,
            moments: []
        )
        let first = document.filename

        #expect(document.filename == first)
        #expect(document.filename == first)
    }

    private static func source(id: String, displayName: String) -> SourceSummary {
        SourceSummary(
            id: id,
            displayName: displayName,
            helperText: "Anime",
            mediaType: "anime",
            relatedURL: URL(string: "https://example.com/\(id)")!,
            updatedAt: Date(timeIntervalSince1970: 1)
        )
    }

    private static func moment(id: String) -> MomentCardModel {
        MomentCardModel(
            id: id,
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
            createdAt: .now,
            isFavorite: false
        )
    }
}

private enum MVPTestError: Error {
    case expected
}

@MainActor
private final class FailingMomentPersistence: MomentStorePersistence {
    let loadResult: [MomentCardModel]?
    let shouldFailSave: Bool
    private(set) var savedValues: [[MomentCardModel]] = []

    init(loadResult: [MomentCardModel]?, shouldFailSave: Bool) {
        self.loadResult = loadResult
        self.shouldFailSave = shouldFailSave
    }

    func load() -> [MomentCardModel]? { loadResult }

    func save(_ moments: [MomentCardModel]) throws {
        if shouldFailSave { throw MVPTestError.expected }
        savedValues.append(moments)
    }
}

private actor EmptyMomentImageRepository: MomentImageRepository {
    func images(for momentID: String) async throws -> [MomentImage] { [] }
    func imageData(for image: MomentImage, momentID: String) async throws -> Data { Data() }
    func addImage(data: Data, id: String, createdAt: Date, to momentID: String) async throws -> [MomentImage] { [] }
    func removeImage(id: String, from momentID: String) async throws -> [MomentImage] { [] }
    func commit(_ changes: MomentImageChangeSet, for momentID: String) async throws -> [MomentImage] { [] }
    func deleteImages(for momentID: String) async throws {}
    func removeOrphans(validMomentIDs: Set<String>) async throws {}
}

@MainActor
private final class RecoveringSettingsRepository: SettingsRepository {
    var shouldFailLoad = true
    private(set) var saveCount = 0
    private var value = AppSettings.initial()

    func loadSettings() throws -> AppSettings {
        if shouldFailLoad { throw MVPTestError.expected }
        return value
    }

    func saveSettings(_ settings: AppSettings) throws {
        saveCount += 1
        value = settings
    }
}
