import Foundation

struct WatchingModeSelection: Hashable {
    let source: SourceSummary
    let episode: EpisodeSummary
    let episodeDisplayName: String
    var pair: PairSummary?
    var autoHashtags: String
}

struct WatchingMomentCandidate: Identifiable, Hashable {
    let id: String
    let eventID: String
    let elapsedSeconds: Int
    let comment: String
    let draft: NewMomentDraft
    var savedMomentID: String?
}

enum WatchingPlaybackPhase: Equatable {
    case idle
    case running
    case paused
    case saving
}

enum WatchingHistorySaveReason: Equatable {
    case activity
    case duration
    case insufficient

    var shouldSave: Bool {
        self != .insufficient
    }
}

extension WatchingPlaybackPhase {
    var hasStarted: Bool {
        self != .idle
    }

    var allowsLogging: Bool {
        self == .running || self == .paused
    }
}

enum WatchingModeLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed
}
