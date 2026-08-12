import Combine
import Foundation

@MainActor
final class WatchingModeViewModel: ObservableObject {
    @Published private(set) var phase: WatchingPlaybackPhase = .idle
    @Published private(set) var events: [WatchingSessionEvent] = []
    @Published private(set) var reactionCount = 0
    @Published private(set) var createdMomentCount = 0
    @Published private(set) var momentCandidates: [WatchingMomentCandidate] = []
    @Published private(set) var saveErrorMessage: String?
    @Published var selection: WatchingModeSelection

    private let repository: any SourceRepository
    private let now: () -> Date
    private var sessionStartedAt: Date?
    private var runningStartedAt: Date?
    private var accumulatedSeconds: TimeInterval = 0
    private var lastReactionTapAt: Date?
    private var wasRunningBeforeFinishPrompt = false

    init(
        selection: WatchingModeSelection,
        repository: any SourceRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.selection = selection
        self.repository = repository
        self.now = now
    }

    var hasStarted: Bool { phase.hasStarted }
    var allowsLogging: Bool { phase.allowsLogging }
    var historySaveReason: WatchingHistorySaveReason {
        if !events.isEmpty || reactionCount > 0 {
            return .activity
        }
        if elapsedSeconds() >= 60 {
            return .duration
        }
        return .insufficient
    }
    var shouldSaveHistory: Bool { historySaveReason.shouldSave }

    func elapsedTimeInterval(at date: Date? = nil) -> TimeInterval {
        let reference = date ?? now()
        let currentRun = runningStartedAt.map { max(0, reference.timeIntervalSince($0)) } ?? 0
        return max(0, accumulatedSeconds + currentRun)
    }

    func elapsedSeconds(at date: Date? = nil) -> Int {
        Int(elapsedTimeInterval(at: date))
    }

    func start() {
        guard phase == .idle else { return }
        let date = now()
        sessionStartedAt = date
        runningStartedAt = date
        phase = .running
        saveErrorMessage = nil
    }

    func pause() {
        guard phase == .running else { return }
        freezeElapsed(at: now())
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        runningStartedAt = now()
        phase = .running
    }

    func prepareToFinish() {
        if phase == .running {
            wasRunningBeforeFinishPrompt = true
            freezeElapsed(at: now())
        }
        if phase != .idle {
            phase = .paused
        }
    }

    func cancelFinish() {
        guard phase == .paused else { return }
        if wasRunningBeforeFinishPrompt {
            runningStartedAt = now()
            phase = .running
        }
        wasRunningBeforeFinishPrompt = false
    }

    func clearSaveError() {
        saveErrorMessage = nil
    }

    func recordReaction(_ reaction: NewMomentDraft.SelectedReaction) {
        guard allowsLogging else { return }
        let tapDate = now()
        let elapsed = elapsedSeconds(at: tapDate)
        reactionCount += 1

        if
            let last = events.last,
            case let .reaction(existing) = last.kind,
            existing.reactionID == reaction.id,
            let lastReactionTapAt,
            tapDate.timeIntervalSince(lastReactionTapAt) <= 2
        {
            events[events.count - 1] = WatchingSessionEvent(
                id: last.id,
                elapsedSeconds: last.elapsedSeconds,
                kind: .reaction(
                    WatchingSessionReaction(
                        reactionID: existing.reactionID,
                        displayText: existing.displayText,
                        count: existing.count + 1
                    )
                )
            )
        } else {
            events.append(
                WatchingSessionEvent(
                    id: UUID().uuidString,
                    elapsedSeconds: elapsed,
                    kind: .reaction(
                        WatchingSessionReaction(
                            reactionID: reaction.id,
                            displayText: reaction.displayText
                        )
                    )
                )
            )
        }
        lastReactionTapAt = tapDate
    }

    @discardableResult
    func recordMomentCandidate(
        draft: NewMomentDraft,
        comment: String,
        elapsedSeconds: Int
    ) -> WatchingMomentCandidate? {
        guard hasStarted else { return nil }
        let eventID = UUID().uuidString
        let candidate = WatchingMomentCandidate(
            id: UUID().uuidString,
            eventID: eventID,
            elapsedSeconds: max(0, elapsedSeconds),
            comment: comment,
            draft: draft,
            savedMomentID: nil
        )
        momentCandidates.append(candidate)
        events.append(
            WatchingSessionEvent(
                id: eventID,
                elapsedSeconds: max(0, elapsedSeconds),
                kind: .liveHeartScream(
                    momentID: nil,
                    comment: comment,
                    pairID: draft.selectedPairID
                )
            )
        )
        lastReactionTapAt = nil
        return candidate
    }

    func stageMomentCandidates(selectedIDs: Set<String>) {
        for index in momentCandidates.indices {
            if selectedIDs.contains(momentCandidates[index].id) {
                if momentCandidates[index].savedMomentID == nil {
                    momentCandidates[index].savedMomentID = UUID().uuidString
                }
            } else {
                momentCandidates[index].savedMomentID = nil
            }
        }

        createdMomentCount = Self.savedMomentCount(in: momentCandidates)
        for candidate in momentCandidates {
            guard let eventIndex = events.firstIndex(where: { $0.id == candidate.eventID }) else {
                continue
            }
            events[eventIndex] = WatchingSessionEvent(
                id: candidate.eventID,
                elapsedSeconds: candidate.elapsedSeconds,
                kind: .liveHeartScream(
                    momentID: candidate.savedMomentID,
                    comment: candidate.comment,
                    pairID: candidate.draft.selectedPairID
                )
            )
        }
    }

    static func savedMomentCount(in candidates: [WatchingMomentCandidate]) -> Int {
        candidates.count { $0.savedMomentID != nil }
    }

    func finish() async -> WatchingSessionSummary? {
        guard
            let startedAt = sessionStartedAt,
            phase != .idle,
            phase != .saving
        else {
            return nil
        }
        prepareToFinish()
        guard shouldSaveHistory else { return nil }
        phase = .saving
        do {
            let session = try await repository.createWatchingSession(
                sourceID: selection.source.id,
                episodeID: selection.episode.id,
                request: WatchingSessionCreateRequest(
                    startedAt: startedAt,
                    durationSeconds: elapsedSeconds(),
                    createdMomentCount: createdMomentCount,
                    reactionCount: reactionCount,
                    events: events
                )
            )
            wasRunningBeforeFinishPrompt = false
            saveErrorMessage = nil
            return session
        } catch {
            phase = .paused
            saveErrorMessage = AppStrings.watchingSaveFailed
            return nil
        }
    }

    func makeMomentDraft(
        heartScream: String,
        pair: PairSummary?,
        timestampSeconds: Int
    ) -> NewMomentDraft {
        let schema = SourceLocatorSchema.schema(for: selection.source.mediaType)
            ?? SourceLocatorSchema.fallback
        var draft = NewMomentDraft()
        draft.selectSource(
            id: selection.source.id,
            displayName: selection.source.displayName,
            helperText: selection.source.helperText,
            mediaType: selection.source.mediaType
        )
        draft.selectEpisode(selection.episode, schema: schema)
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
                value: Self.timestampText(timestampSeconds)
            )
        }
        draft.updateHeartScream(heartScream)
        return draft
    }

    static func timestampText(_ seconds: Int) -> String {
        LocatorValuePolicy.formattedTimestamp(
            hour: max(0, seconds) / 3_600,
            minute: (max(0, seconds) % 3_600) / 60,
            second: max(0, seconds) % 60
        )
    }

    private func freezeElapsed(at date: Date) {
        if let runningStartedAt {
            accumulatedSeconds += max(0, date.timeIntervalSince(runningStartedAt))
        }
        runningStartedAt = nil
    }
}
