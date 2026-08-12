import Combine
import Foundation

enum WatchHistoryDetailLoadState: Equatable {
    case idle
    case loading
    case loaded
    case missing
    case failed
}

struct WatchHistoryDetailContent: Equatable {
    let source: SourceSummary
    let episode: EpisodeSummary
    let session: WatchingSessionSummary
    let locatorDisplayName: String
}

@MainActor
final class WatchHistoryDetailViewModel: ObservableObject {
    @Published private(set) var content: WatchHistoryDetailContent?
    @Published private(set) var loadState: WatchHistoryDetailLoadState = .idle
    @Published private(set) var savingEventID: String?
    @Published var saveMomentErrorMessage: String?
    @Published private(set) var isDeleting = false
    @Published private(set) var deleteErrorMessage: String?

    let sourceID: String
    let episodeID: String
    let sessionID: String

    private let repository: any SourceRepository

    init(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        repository: any SourceRepository
    ) {
        self.sourceID = sourceID
        self.episodeID = episodeID
        self.sessionID = sessionID
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    func saveLiveHeartScreamAsMoment(
        eventID: String,
        pairRepository: any PairRepository,
        momentStore: MomentStore
    ) async {
        guard
            savingEventID == nil,
            let content,
            let event = content.session.events.first(where: { $0.id == eventID }),
            case let .liveHeartScream(momentID, comment, pairID) = event.kind,
            momentID == nil
        else {
            return
        }

        savingEventID = eventID
        defer { savingEventID = nil }
        do {
            let pair: PairSummary?
            if let pairID {
                let pairs = try await pairRepository.fetchPairs()
                guard let resolvedPair = pairs.first(where: { $0.id == pairID }) else {
                    throw SourceRepositoryError.unsupported
                }
                pair = resolvedPair
            } else {
                pair = nil
            }
            let newMomentID = UUID().uuidString
            let draft = makeMomentDraft(
                content: content,
                event: event,
                comment: comment,
                pair: pair
            )
            momentStore.add(draft: draft, id: newMomentID)
            let updatedSession: WatchingSessionSummary
            do {
                updatedSession = try await repository.saveLiveHeartScreamAsMoment(
                    sourceID: sourceID,
                    episodeID: episodeID,
                    sessionID: sessionID,
                    eventID: eventID,
                    momentID: newMomentID
                )
            } catch {
                _ = try? await momentStore.delete(id: newMomentID)
                throw error
            }
            let updatedEpisode = EpisodeSummary(
                id: content.episode.id,
                locatorValues: content.episode.locatorValues,
                relatedURL: content.episode.relatedURL,
                momentCount: content.episode.momentCount + 1,
                viewedCount: content.episode.viewedCount,
                updatedAt: .now,
                progress: content.episode.progress,
                displayTitle: content.episode.displayTitle,
                watchingSessions: content.episode.watchingSessions.map {
                    $0.id == updatedSession.id ? updatedSession : $0
                }
            )
            self.content = WatchHistoryDetailContent(
                source: content.source,
                episode: updatedEpisode,
                session: updatedSession,
                locatorDisplayName: content.locatorDisplayName
            )
            saveMomentErrorMessage = nil
        } catch {
            saveMomentErrorMessage = AppStrings.watchHistoryDetailSaveMomentError
        }
    }

    func clearSaveMomentError() {
        saveMomentErrorMessage = nil
    }

    func deleteSession() async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await repository.deleteWatchingSession(
                sourceID: sourceID,
                episodeID: episodeID,
                sessionID: sessionID
            )
            deleteErrorMessage = nil
            return true
        } catch {
            deleteErrorMessage = AppStrings.watchHistoryDeleteError
            return false
        }
    }

    func clearDeleteError() {
        deleteErrorMessage = nil
    }

    private func load() async {
        loadState = .loading

        do {
            guard
                let detail = try await repository.fetchSourceDetail(id: sourceID),
                let episode = detail.episodes.first(where: { $0.id == episodeID }),
                let session = episode.watchingSessions.first(where: { $0.id == sessionID })
            else {
                content = nil
                loadState = .missing
                return
            }

            let schema = SourceLocatorSchema.schema(for: detail.summary.mediaType)
                ?? SourceLocatorSchema.fallback
            content = WatchHistoryDetailContent(
                source: detail.summary,
                episode: episode,
                session: session,
                locatorDisplayName: schema.episodeDisplayName(for: episode.locatorValues)
            )
            loadState = .loaded
        } catch {
            content = nil
            loadState = .failed
        }
    }

    private func makeMomentDraft(
        content: WatchHistoryDetailContent,
        event: WatchingSessionEvent,
        comment: String,
        pair: PairSummary?
    ) -> NewMomentDraft {
        let schema = SourceLocatorSchema.schema(for: content.source.mediaType)
            ?? SourceLocatorSchema.fallback
        var draft = NewMomentDraft()
        draft.selectSource(
            id: content.source.id,
            displayName: content.source.displayName,
            helperText: content.source.helperText,
            mediaType: content.source.mediaType
        )
        draft.selectEpisode(content.episode, schema: schema)
        if let pair {
            draft.selectPair(
                id: pair.id,
                displayName: pair.displayName,
                nickname: pair.nickname,
                member1Name: pair.member1Name,
                member2Name: pair.member2Name,
                leadingColorHex: pair.leadingColorHex,
                trailingColorHex: pair.trailingColorHex
            )
        }
        draft.configureContext(using: schema)
        if let timestampField = schema.momentLocationFields.first(
            where: { $0.inputKind == .timestamp }
        ) {
            draft.updateContextValue(
                key: timestampField.key,
                value: WatchingModeViewModel.timestampText(event.elapsedSeconds)
            )
        }
        draft.updateHeartScream(comment)
        return draft
    }
}

struct WatchingSessionEventFormatter {
    func elapsedTimeText(seconds: Int) -> String {
        let clamped = max(0, seconds)
        let hours = clamped / 3_600
        let minutes = (clamped % 3_600) / 60
        let seconds = clamped % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
