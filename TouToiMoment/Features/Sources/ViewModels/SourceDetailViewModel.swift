import Combine
import Foundation

@MainActor
final class SourceDetailViewModel: ObservableObject {
    @Published private(set) var detail: SourceDetail?
    @Published private(set) var loadState: SourceLoadState = .idle
    @Published private(set) var mutationErrorMessage: String?

    let sourceID: String

    private let repository: any SourceRepository
    private let relativeDateFormatter: SourceRelativeDateFormatter

    init(
        sourceID: String,
        repository: any SourceRepository,
        relativeDateFormatter: SourceRelativeDateFormatter? = nil
    ) {
        self.sourceID = sourceID
        self.repository = repository
        self.relativeDateFormatter = relativeDateFormatter ?? SourceRelativeDateFormatter()
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    func relativeDateText(
        for episode: EpisodeSummary,
        relativeTo referenceDate: Date = .now
    ) -> String {
        relativeDateFormatter.string(for: episode.updatedAt, relativeTo: referenceDate)
    }

    func updateSource(_ request: SourceUpdateRequest) async throws -> SourceSummary {
        do {
            let source = try await repository.updateSource(id: sourceID, request: request)
            detail = detail.map { SourceDetail(summary: source, episodes: $0.episodes) }
            mutationErrorMessage = nil
            return source
        } catch {
            mutationErrorMessage = AppStrings.sourceDetailMutationError
            throw error
        }
    }

    func createEpisode(_ request: EpisodeCreateRequest) async throws -> EpisodeSummary {
        do {
            let episode = try await repository.createEpisode(sourceID: sourceID, request: request)
            if let detail {
                self.detail = SourceDetail(
                    summary: detail.summary,
                    episodes: [episode] + detail.episodes
                )
            }
            mutationErrorMessage = nil
            return episode
        } catch {
            mutationErrorMessage = AppStrings.newEpisodeSaveError
            throw error
        }
    }

    func deleteSource() async throws {
        do {
            try await repository.deleteSource(id: sourceID)
            mutationErrorMessage = nil
        } catch {
            mutationErrorMessage = AppStrings.sourceDetailMutationError
            throw error
        }
    }

    func clearMutationError() {
        mutationErrorMessage = nil
    }

    private func load() async {
        loadState = .loading

        do {
            detail = try await repository.fetchSourceDetail(id: sourceID)
            loadState = detail == nil ? .missing : .loaded
        } catch {
            detail = nil
            loadState = .failed
        }
    }
}
