import Foundation

struct SourceSummary: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let helperText: String
    let mediaType: String
    let streamingPlatform: StreamingPlatform?
    let relatedURL: URL
    let momentCount: Int
    let updatedAt: Date

    init(
        id: String,
        displayName: String,
        helperText: String,
        mediaType: String,
        streamingPlatform: StreamingPlatform? = nil,
        relatedURL: URL,
        momentCount: Int = 0,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.helperText = helperText
        self.mediaType = mediaType
        self.streamingPlatform = streamingPlatform
        self.relatedURL = relatedURL
        self.momentCount = momentCount
        self.updatedAt = updatedAt
    }

    var contextualHelperText: String {
        guard let streamingPlatform else { return helperText }
        return "\(helperText) · \(streamingPlatform.displayName)"
    }
}

struct SourceCreateRequest: Hashable {
    let displayName: String
    let helperText: String
    let mediaType: String
    let streamingPlatform: StreamingPlatform?
    let relatedURL: URL

    init(
        displayName: String,
        helperText: String,
        mediaType: String,
        streamingPlatform: StreamingPlatform? = nil,
        relatedURL: URL
    ) {
        self.displayName = displayName
        self.helperText = helperText
        self.mediaType = mediaType
        self.streamingPlatform = streamingPlatform
        self.relatedURL = relatedURL
    }
}

struct SourceUpdateRequest: Hashable {
    let displayName: String
    let streamingPlatform: StreamingPlatform?
    let relatedURL: URL

    init(
        displayName: String,
        streamingPlatform: StreamingPlatform? = nil,
        relatedURL: URL
    ) {
        self.displayName = displayName
        self.streamingPlatform = streamingPlatform
        self.relatedURL = relatedURL
    }
}

struct SourceDetail: Identifiable, Hashable, Codable {
    let summary: SourceSummary
    let episodes: [EpisodeSummary]

    var id: String { summary.id }
}

struct EpisodeSummary: Identifiable, Hashable, Codable {
    let id: String
    let locatorValues: [LocatorValue]
    let relatedURL: URL?
    let momentCount: Int
    let viewedCount: Int
    let updatedAt: Date
    let progress: Double?
    let displayTitle: String?
    let watchingSessions: [WatchingSessionSummary]

    init(
        id: String,
        locatorValues: [LocatorValue],
        relatedURL: URL?,
        momentCount: Int,
        viewedCount: Int,
        updatedAt: Date,
        progress: Double?,
        displayTitle: String? = nil,
        watchingSessions: [WatchingSessionSummary] = []
    ) {
        self.id = id
        self.locatorValues = locatorValues
        self.relatedURL = relatedURL
        self.momentCount = momentCount
        self.viewedCount = viewedCount
        self.updatedAt = updatedAt
        self.progress = progress
        self.displayTitle = EpisodeDisplayTitlePolicy.normalized(displayTitle)
        self.watchingSessions = watchingSessions
    }
}

struct WatchingSessionSummary: Identifiable, Hashable, Codable {
    let id: String
    let startedAt: Date
    let durationSeconds: Int
    let momentCount: Int
    let reactionCount: Int
    let events: [WatchingSessionEvent]

    init(
        id: String,
        startedAt: Date,
        durationSeconds: Int,
        momentCount: Int,
        reactionCount: Int,
        events: [WatchingSessionEvent] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.momentCount = momentCount
        self.reactionCount = reactionCount
        self.events = events
    }
}

struct WatchingSessionReaction: Hashable, Codable {
    let reactionID: String
    let displayText: String
    let count: Int

    init(reactionID: String, displayText: String, count: Int = 1) {
        self.reactionID = reactionID
        self.displayText = displayText
        self.count = max(1, count)
    }
}

struct WatchingSessionEvent: Identifiable, Hashable, Codable {
    enum Kind: Hashable, Codable {
        case reaction(WatchingSessionReaction)
        case voiceNote(String)
        case liveHeartScream(momentID: String?, comment: String, pairID: String?)
    }

    let id: String
    let elapsedSeconds: Int
    let kind: Kind
}

struct WatchingSessionCreateRequest: Hashable {
    let startedAt: Date
    let durationSeconds: Int
    let createdMomentCount: Int
    let reactionCount: Int
    let events: [WatchingSessionEvent]
}

struct EpisodeCreateRequest: Hashable {
    let locatorValues: [LocatorValue]
    let relatedURL: URL?
    let displayTitle: String?
    let updatesDisplayTitle: Bool

    init(
        locatorValues: [LocatorValue],
        relatedURL: URL?,
        displayTitle: String? = nil,
        updatesDisplayTitle: Bool = false
    ) {
        self.locatorValues = locatorValues
        self.relatedURL = relatedURL
        self.displayTitle = EpisodeDisplayTitlePolicy.normalized(displayTitle)
        self.updatesDisplayTitle = updatesDisplayTitle
    }
}

struct MomentReferenceCounts: Equatable {
    let bySourceID: [String: Int]
    let byEpisodeID: [String: Int]

    static func make(from moments: [MomentCardModel]) -> MomentReferenceCounts {
        var sourceCounts: [String: Int] = [:]
        var episodeCounts: [String: Int] = [:]
        for moment in moments {
            if let sourceID = moment.sourceID {
                sourceCounts[sourceID, default: 0] += 1
            }
            if let episodeID = moment.episodeID {
                episodeCounts[episodeID, default: 0] += 1
            }
        }
        return MomentReferenceCounts(
            bySourceID: sourceCounts,
            byEpisodeID: episodeCounts
        )
    }
}

enum SourceRepositoryError: Error, Equatable {
    case invalidSource
    case invalidURL
    case invalidStreamingPlatform
    case invalidEpisode
    case duplicateEpisode
    case sourceNotFound
    case unsupported
}

enum SourceRelatedURLPolicy {
    static func normalizedURL(from rawValue: String) -> URL? {
        guard RelatedURLInputPolicy.isWithinLimits(rawValue) else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmed),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host?.isEmpty == false,
            url.user == nil,
            url.password == nil
        else {
            return nil
        }

        return url
    }

    static func isValid(_ url: URL) -> Bool {
        guard RelatedURLInputPolicy.isWithinLimits(url.absoluteString) else { return false }
        guard
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.user == nil,
            url.password == nil
        else {
            return false
        }

        return url.host?.isEmpty == false
    }
}

protocol SourceRepository {
    func reloadFromPersistence() throws
    func fetchSources() async throws -> [SourceSummary]
    func fetchSourceDetail(id: String) async throws -> SourceDetail?
    func createSource(request: SourceCreateRequest) async throws -> SourceSummary
    func updateSource(id: String, request: SourceUpdateRequest) async throws -> SourceSummary
    func deleteSource(id: String) async throws
    func createEpisode(sourceID: String, request: EpisodeCreateRequest) async throws -> EpisodeSummary
    func updateEpisode(
        sourceID: String,
        episodeID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary
    func deleteEpisode(sourceID: String, episodeID: String) async throws
    func deleteWatchingSession(
        sourceID: String,
        episodeID: String,
        sessionID: String
    ) async throws
    func createWatchingSession(
        sourceID: String,
        episodeID: String,
        request: WatchingSessionCreateRequest
    ) async throws -> WatchingSessionSummary
    func saveLiveHeartScreamAsMoment(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        eventID: String,
        momentID: String
    ) async throws -> WatchingSessionSummary
    func synchronizeMomentCounts(_ counts: MomentReferenceCounts) async throws
}

extension SourceRepository {
    func reloadFromPersistence() throws {}
    func synchronizeMomentCounts(_: MomentReferenceCounts) async throws {}
    func updateSource(id: String, request: SourceUpdateRequest) async throws -> SourceSummary {
        throw SourceRepositoryError.unsupported
    }

    func deleteSource(id: String) async throws {
        throw SourceRepositoryError.unsupported
    }

    func createEpisode(
        sourceID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary {
        throw SourceRepositoryError.unsupported
    }

    func updateEpisode(
        sourceID: String,
        episodeID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary {
        throw SourceRepositoryError.unsupported
    }

    func createWatchingSession(
        sourceID: String,
        episodeID: String,
        request: WatchingSessionCreateRequest
    ) async throws -> WatchingSessionSummary {
        throw SourceRepositoryError.unsupported
    }

    func deleteEpisode(sourceID: String, episodeID: String) async throws {
        throw SourceRepositoryError.unsupported
    }

    func deleteWatchingSession(
        sourceID: String,
        episodeID: String,
        sessionID: String
    ) async throws {
        throw SourceRepositoryError.unsupported
    }

    func saveLiveHeartScreamAsMoment(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        eventID: String,
        momentID: String
    ) async throws -> WatchingSessionSummary {
        throw SourceRepositoryError.unsupported
    }
}
