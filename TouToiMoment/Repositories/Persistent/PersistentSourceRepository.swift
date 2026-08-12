import Foundation
import SwiftData

@MainActor
final class PersistentSourceRepository: SourceRepository {
    private static let fixtureVersion = 1
    private let context: ModelContext
    private let repository: InMemorySourceRepository

    init(context: ModelContext) throws {
        self.context = context
        let descriptor = FetchDescriptor<PersistedSourceState>()
        let state = try context.fetch(descriptor).first
        let details: [SourceDetail]
        if let state {
            details = try JSONDecoder().decode([SourceDetail].self, from: state.payload)
        } else {
            details = InMemorySourceRepository.fixtureDetails
        }

        repository = InMemorySourceRepository(
            sources: details.map(\.summary),
            details: details,
            onChange: { [weak context] details in
                guard let context else { return }
                let payload = try JSONEncoder().encode(details)
                let descriptor = FetchDescriptor<PersistedSourceState>()
                if let existing = try context.fetch(descriptor).first {
                    existing.fixtureVersion = Self.fixtureVersion
                    existing.payload = payload
                } else {
                    context.insert(
                        PersistedSourceState(
                            fixtureVersion: Self.fixtureVersion,
                            payload: payload
                        )
                    )
                }
                try context.save()
            }
        )

        if state == nil {
            let payload = try JSONEncoder().encode(details)
            context.insert(
                PersistedSourceState(
                    fixtureVersion: Self.fixtureVersion,
                    payload: payload
                )
            )
            try context.save()
        }
    }

    func fetchSources() async throws -> [SourceSummary] {
        try await repository.fetchSources()
    }

    func reloadFromPersistence() throws {
        let descriptor = FetchDescriptor<PersistedSourceState>()
        guard let state = try context.fetch(descriptor).first else {
            throw SourceRepositoryError.invalidSource
        }
        let details = try JSONDecoder().decode([SourceDetail].self, from: state.payload)
        repository.replaceAllForReload(details)
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? {
        try await repository.fetchSourceDetail(id: id)
    }

    func createSource(request: SourceCreateRequest) async throws -> SourceSummary {
        try await repository.createSource(request: request)
    }

    func updateSource(id: String, request: SourceUpdateRequest) async throws -> SourceSummary {
        try await repository.updateSource(id: id, request: request)
    }

    func deleteSource(id: String) async throws {
        try await repository.deleteSource(id: id)
    }

    func createEpisode(sourceID: String, request: EpisodeCreateRequest) async throws -> EpisodeSummary {
        try await repository.createEpisode(sourceID: sourceID, request: request)
    }

    func updateEpisode(
        sourceID: String,
        episodeID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary {
        try await repository.updateEpisode(
            sourceID: sourceID,
            episodeID: episodeID,
            request: request
        )
    }

    func deleteEpisode(sourceID: String, episodeID: String) async throws {
        try await repository.deleteEpisode(sourceID: sourceID, episodeID: episodeID)
    }

    func deleteWatchingSession(
        sourceID: String,
        episodeID: String,
        sessionID: String
    ) async throws {
        try await repository.deleteWatchingSession(
            sourceID: sourceID,
            episodeID: episodeID,
            sessionID: sessionID
        )
    }

    func createWatchingSession(
        sourceID: String,
        episodeID: String,
        request: WatchingSessionCreateRequest
    ) async throws -> WatchingSessionSummary {
        try await repository.createWatchingSession(
            sourceID: sourceID,
            episodeID: episodeID,
            request: request
        )
    }

    func saveLiveHeartScreamAsMoment(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        eventID: String,
        momentID: String
    ) async throws -> WatchingSessionSummary {
        try await repository.saveLiveHeartScreamAsMoment(
            sourceID: sourceID,
            episodeID: episodeID,
            sessionID: sessionID,
            eventID: eventID,
            momentID: momentID
        )
    }

    func synchronizeMomentCounts(_ counts: MomentReferenceCounts) async throws {
        try await repository.synchronizeMomentCounts(counts)
    }
}
