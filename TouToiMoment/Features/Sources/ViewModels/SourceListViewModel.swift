import Combine
import Foundation

@MainActor
final class SourceListViewModel: ObservableObject {
    @Published private(set) var sources: [SourceSummary] = []
    @Published private(set) var loadState: SourceLoadState = .idle
    @Published private(set) var refreshErrorMessage: String?
    @Published var selectedFilter: SourceListFilter = .all

    private let repository: any SourceRepository
    private let relativeDateFormatter: SourceRelativeDateFormatter

    init(
        repository: any SourceRepository,
        relativeDateFormatter: SourceRelativeDateFormatter? = nil
    ) {
        self.repository = repository
        self.relativeDateFormatter = relativeDateFormatter ?? SourceRelativeDateFormatter()
    }

    var displayedSources: [SourceSummary] {
        sources.filter { selectedFilter.matches(mediaType: $0.mediaType) }
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await load(isRefresh: false)
    }

    func retry() async {
        await load(isRefresh: false)
    }

    func refresh() async {
        await load(isRefresh: loadState == .loaded)
    }

    func createSource(_ request: SourceCreateRequest) async throws -> SourceSummary {
        let source = try await repository.createSource(request: request)
        sources.removeAll { $0.id == source.id }
        sources.insert(source, at: 0)
        selectedFilter = .all
        return source
    }

    func relativeDateText(
        for source: SourceSummary,
        relativeTo referenceDate: Date = .now
    ) -> String {
        relativeDateFormatter.string(for: source.updatedAt, relativeTo: referenceDate)
    }

    private func load(isRefresh: Bool) async {
        if !isRefresh {
            loadState = .loading
        }

        do {
            sources = try await repository.fetchSources()
            loadState = .loaded
            refreshErrorMessage = nil
        } catch {
            if isRefresh {
                loadState = .loaded
                refreshErrorMessage = AppStrings.sourceListRefreshErrorMessage
            } else {
                loadState = .failed
            }
        }
    }
}
