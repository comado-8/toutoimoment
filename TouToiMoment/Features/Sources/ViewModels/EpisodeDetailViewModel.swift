import Combine
import Foundation

enum EpisodeDetailLoadState: Equatable {
    case idle
    case loading
    case loaded
    case missing
    case failed
}

struct EpisodeDetailContent: Equatable {
    let source: SourceSummary
    let episode: EpisodeSummary
    let locatorDisplayName: String
}

@MainActor
final class EpisodeDetailViewModel: ObservableObject {
    @Published private(set) var content: EpisodeDetailContent?
    @Published private(set) var loadState: EpisodeDetailLoadState = .idle
    @Published private(set) var refreshErrorMessage: String?
    @Published private(set) var isDeleting = false
    @Published private(set) var deleteErrorMessage: String?

    let sourceID: String
    let episodeID: String

    private let repository: any SourceRepository

    init(
        sourceID: String,
        episodeID: String,
        repository: any SourceRepository
    ) {
        self.sourceID = sourceID
        self.episodeID = episodeID
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await load(preservingCurrentContent: false)
    }

    func retry() async {
        await load(preservingCurrentContent: false)
    }

    func refresh() async {
        await load(preservingCurrentContent: content != nil)
    }

    func retryRefresh() async {
        await refresh()
    }

    func clearRefreshError() {
        refreshErrorMessage = nil
    }

    func updateEpisode(_ request: EpisodeCreateRequest) async throws -> EpisodeSummary {
        let updated = try await repository.updateEpisode(
            sourceID: sourceID,
            episodeID: episodeID,
            request: request
        )
        guard let current = content else { return updated }
        let schema = SourceLocatorSchema.schema(for: current.source.mediaType)
            ?? SourceLocatorSchema.fallback
        content = EpisodeDetailContent(
            source: current.source,
            episode: updated,
            locatorDisplayName: schema.episodeDisplayName(for: updated.locatorValues)
        )
        return updated
    }

    func deleteEpisode() async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await repository.deleteEpisode(sourceID: sourceID, episodeID: episodeID)
            deleteErrorMessage = nil
            return true
        } catch {
            deleteErrorMessage = AppStrings.episodeDeleteError
            return false
        }
    }

    func clearDeleteError() {
        deleteErrorMessage = nil
    }

    private func load(preservingCurrentContent: Bool) async {
        if !preservingCurrentContent {
            loadState = .loading
        }

        do {
            guard
                let detail = try await repository.fetchSourceDetail(id: sourceID),
                let episode = detail.episodes.first(where: { $0.id == episodeID })
            else {
                content = nil
                loadState = .missing
                refreshErrorMessage = nil
                return
            }

            let schema = SourceLocatorSchema.schema(for: detail.summary.mediaType)
                ?? SourceLocatorSchema.fallback
            content = EpisodeDetailContent(
                source: detail.summary,
                episode: episode,
                locatorDisplayName: schema.episodeDisplayName(for: episode.locatorValues)
            )
            loadState = .loaded
            refreshErrorMessage = nil
        } catch {
            if preservingCurrentContent {
                loadState = .loaded
                refreshErrorMessage = AppStrings.episodeDetailRefreshErrorMessage
            } else {
                content = nil
                loadState = .failed
            }
        }
    }
}

struct EpisodeWatchHistoryFormatter {
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    init(
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) {
        dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeZone = timeZone
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
    }

    func dateTimeText(for date: Date) -> String {
        "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
    }

    func durationText(seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60

        if hours > 0 {
            return AppStrings.episodeDetailDuration(hours: hours, minutes: minutes)
        }
        return AppStrings.episodeDetailDuration(minutes: minutes)
    }
}
