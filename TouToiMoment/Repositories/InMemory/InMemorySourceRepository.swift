import Foundation

@MainActor
final class InMemorySourceRepository: SourceRepository {
    private var sources: [SourceSummary]
    private var details: [String: SourceDetail]
    private let onChange: ([SourceDetail]) throws -> Void

    init() {
        let fixtures = Self.fixtureDetails
        sources = fixtures.map(\.summary)
        details = Dictionary(uniqueKeysWithValues: fixtures.map { ($0.id, $0) })
        onChange = { _ in }
    }

    init(
        sources: [SourceSummary],
        details: [SourceDetail] = [],
        onChange: @escaping ([SourceDetail]) throws -> Void = { _ in }
    ) {
        self.sources = sources
        self.details = Dictionary(uniqueKeysWithValues: details.map { ($0.id, $0) })
        self.onChange = onChange
        for source in sources where self.details[source.id] == nil {
            self.details[source.id] = SourceDetail(summary: source, episodes: [])
        }
    }

    func fetchSources() async throws -> [SourceSummary] {
        sources
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? {
        details[id]
    }

    func replaceAllForReload(_ newDetails: [SourceDetail]) {
        sources = newDetails.map(\.summary)
        details = Dictionary(uniqueKeysWithValues: newDetails.map { ($0.id, $0) })
    }

    func createSource(request: SourceCreateRequest) async throws -> SourceSummary {
        let normalizedDisplayName = SourceNamePolicy.normalized(request.displayName)
        guard !normalizedDisplayName.isEmpty else {
            throw SourceRepositoryError.invalidSource
        }
        guard SourceRelatedURLPolicy.isValid(request.relatedURL) else {
            throw SourceRepositoryError.invalidURL
        }
        guard Self.isValidStreamingPlatform(
            request.streamingPlatform,
            mediaType: request.mediaType
        ) else {
            throw SourceRepositoryError.invalidStreamingPlatform
        }

        let source = SourceSummary(
            id: UUID().uuidString,
            displayName: normalizedDisplayName,
            helperText: request.helperText,
            mediaType: request.mediaType,
            streamingPlatform: request.streamingPlatform,
            relatedURL: request.relatedURL
        )
        let originalSources = sources
        let originalDetails = details
        sources.insert(source, at: 0)
        details[source.id] = SourceDetail(summary: source, episodes: [])
        do {
            try persist()
        } catch {
            sources = originalSources
            details = originalDetails
            throw error
        }
        return source
    }

    func updateSource(id: String, request: SourceUpdateRequest) async throws -> SourceSummary {
        let normalizedDisplayName = SourceNamePolicy.normalized(request.displayName)
        guard !normalizedDisplayName.isEmpty else {
            throw SourceRepositoryError.invalidSource
        }
        guard SourceRelatedURLPolicy.isValid(request.relatedURL) else {
            throw SourceRepositoryError.invalidURL
        }
        guard let sourceIndex = sources.firstIndex(where: { $0.id == id }) else {
            throw SourceRepositoryError.sourceNotFound
        }

        let original = sources[sourceIndex]
        guard Self.isValidStreamingPlatform(
            request.streamingPlatform,
            mediaType: original.mediaType
        ) else {
            throw SourceRepositoryError.invalidStreamingPlatform
        }
        let updated = SourceSummary(
            id: original.id,
            displayName: normalizedDisplayName,
            helperText: original.helperText,
            mediaType: original.mediaType,
            streamingPlatform: request.streamingPlatform,
            relatedURL: request.relatedURL,
            momentCount: original.momentCount,
            updatedAt: .now
        )
        let originalSources = sources
        let originalDetails = details
        sources[sourceIndex] = updated
        let episodes = details[id]?.episodes ?? []
        details[id] = SourceDetail(summary: updated, episodes: episodes)
        do {
            try persist()
        } catch {
            sources = originalSources
            details = originalDetails
            throw error
        }
        return updated
    }

    func deleteSource(id: String) async throws {
        guard sources.contains(where: { $0.id == id }) else {
            throw SourceRepositoryError.sourceNotFound
        }
        let originalSources = sources
        let originalDetails = details
        sources.removeAll { $0.id == id }
        details[id] = nil
        do {
            try persist()
        } catch {
            sources = originalSources
            details = originalDetails
            throw error
        }
    }

    func createEpisode(
        sourceID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary {
        guard
            let source = sources.first(where: { $0.id == sourceID }),
            let detail = details[sourceID]
        else {
            throw SourceRepositoryError.sourceNotFound
        }
        guard
            let schema = SourceLocatorSchema.schema(for: source.mediaType),
            schema.isValidEpisodeValues(request.locatorValues),
            request.relatedURL.map(SourceRelatedURLPolicy.isValid) ?? true
        else {
            throw SourceRepositoryError.invalidEpisode
        }

        let normalizedValues = schema.normalizedEpisodeValues(request.locatorValues)
        guard !detail.episodes.contains(where: { $0.locatorValues == normalizedValues }) else {
            throw SourceRepositoryError.duplicateEpisode
        }

        let episode = EpisodeSummary(
            id: UUID().uuidString,
            locatorValues: normalizedValues,
            relatedURL: request.relatedURL,
            momentCount: 0,
            viewedCount: 0,
            updatedAt: .now,
            progress: nil,
            displayTitle: request.displayTitle
        )
        details[sourceID] = SourceDetail(
            summary: source,
            episodes: [episode] + detail.episodes
        )
        try persist()
        return episode
    }

    func updateEpisode(
        sourceID: String,
        episodeID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary {
        guard
            let source = sources.first(where: { $0.id == sourceID }),
            let detail = details[sourceID],
            let episodeIndex = detail.episodes.firstIndex(where: { $0.id == episodeID })
        else {
            throw SourceRepositoryError.sourceNotFound
        }
        guard
            let schema = SourceLocatorSchema.schema(for: source.mediaType),
            schema.isValidEpisodeValues(request.locatorValues),
            request.relatedURL.map(SourceRelatedURLPolicy.isValid) ?? true
        else {
            throw SourceRepositoryError.invalidEpisode
        }

        let normalizedValues = schema.normalizedEpisodeValues(request.locatorValues)
        guard !detail.episodes.enumerated().contains(where: { index, episode in
            index != episodeIndex && episode.locatorValues == normalizedValues
        }) else {
            throw SourceRepositoryError.duplicateEpisode
        }

        let original = detail.episodes[episodeIndex]
        let updated = EpisodeSummary(
            id: original.id,
            locatorValues: normalizedValues,
            relatedURL: request.relatedURL,
            momentCount: original.momentCount,
            viewedCount: original.viewedCount,
            updatedAt: .now,
            progress: original.progress,
            displayTitle: request.updatesDisplayTitle
                ? request.displayTitle
                : original.displayTitle,
            watchingSessions: original.watchingSessions
        )
        var episodes = detail.episodes
        episodes[episodeIndex] = updated
        details[sourceID] = SourceDetail(summary: source, episodes: episodes)
        try persist()
        return updated
    }

    func deleteEpisode(sourceID: String, episodeID: String) async throws {
        guard
            let source = sources.first(where: { $0.id == sourceID }),
            let detail = details[sourceID],
            detail.episodes.contains(where: { $0.id == episodeID })
        else {
            throw SourceRepositoryError.sourceNotFound
        }
        let episodes = detail.episodes.filter { $0.id != episodeID }
        details[sourceID] = SourceDetail(summary: source, episodes: episodes)
        try persist()
    }

    func deleteWatchingSession(
        sourceID: String,
        episodeID: String,
        sessionID: String
    ) async throws {
        guard
            let source = sources.first(where: { $0.id == sourceID }),
            let detail = details[sourceID],
            let episodeIndex = detail.episodes.firstIndex(where: { $0.id == episodeID }),
            detail.episodes[episodeIndex].watchingSessions.contains(where: { $0.id == sessionID })
        else {
            throw SourceRepositoryError.sourceNotFound
        }
        let original = detail.episodes[episodeIndex]
        let sessions = original.watchingSessions.filter { $0.id != sessionID }
        let updated = EpisodeSummary(
            id: original.id,
            locatorValues: original.locatorValues,
            relatedURL: original.relatedURL,
            momentCount: original.momentCount,
            viewedCount: max(0, original.viewedCount - 1),
            updatedAt: .now,
            progress: original.progress,
            displayTitle: original.displayTitle,
            watchingSessions: sessions
        )
        var episodes = detail.episodes
        episodes[episodeIndex] = updated
        details[sourceID] = SourceDetail(summary: source, episodes: episodes)
        try persist()
    }

    func synchronizeMomentCounts(_ counts: MomentReferenceCounts) async throws {
        let originalDetails = details
        var synchronizedSources: [SourceSummary] = []
        synchronizedSources.reserveCapacity(sources.count)

        for source in sources {
            let synchronizedSummary = SourceSummary(
                id: source.id,
                displayName: source.displayName,
                helperText: source.helperText,
                mediaType: source.mediaType,
                streamingPlatform: source.streamingPlatform,
                relatedURL: source.relatedURL,
                momentCount: counts.bySourceID[source.id, default: 0],
                updatedAt: source.updatedAt
            )
            synchronizedSources.append(synchronizedSummary)

            guard let detail = details[source.id] else { continue }
            let episodes = detail.episodes.map { episode in
                EpisodeSummary(
                    id: episode.id,
                    locatorValues: episode.locatorValues,
                    relatedURL: episode.relatedURL,
                    momentCount: counts.byEpisodeID[episode.id, default: 0],
                    viewedCount: episode.viewedCount,
                    updatedAt: episode.updatedAt,
                    progress: episode.progress,
                    displayTitle: episode.displayTitle,
                    watchingSessions: episode.watchingSessions
                )
            }
            details[source.id] = SourceDetail(
                summary: synchronizedSummary,
                episodes: episodes
            )
        }

        guard synchronizedSources != sources || details != originalDetails else { return }
        sources = synchronizedSources
        try persist()
    }

    func createWatchingSession(
        sourceID: String,
        episodeID: String,
        request: WatchingSessionCreateRequest
    ) async throws -> WatchingSessionSummary {
        guard
            let source = sources.first(where: { $0.id == sourceID }),
            let detail = details[sourceID],
            let episodeIndex = detail.episodes.firstIndex(where: { $0.id == episodeID })
        else {
            throw SourceRepositoryError.sourceNotFound
        }

        let session = WatchingSessionSummary(
            id: UUID().uuidString,
            startedAt: request.startedAt,
            durationSeconds: max(0, request.durationSeconds),
            momentCount: max(0, request.createdMomentCount),
            reactionCount: max(0, request.reactionCount),
            events: request.events
        )
        let original = detail.episodes[episodeIndex]
        let updated = EpisodeSummary(
            id: original.id,
            locatorValues: original.locatorValues,
            relatedURL: original.relatedURL,
            momentCount: original.momentCount + max(0, request.createdMomentCount),
            viewedCount: original.viewedCount + 1,
            updatedAt: .now,
            progress: original.progress,
            displayTitle: original.displayTitle,
            watchingSessions: [session] + original.watchingSessions
        )
        var episodes = detail.episodes
        episodes[episodeIndex] = updated
        details[sourceID] = SourceDetail(summary: source, episodes: episodes)
        try persist()
        return session
    }

    func saveLiveHeartScreamAsMoment(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        eventID: String,
        momentID: String
    ) async throws -> WatchingSessionSummary {
        guard
            let source = sources.first(where: { $0.id == sourceID }),
            let detail = details[sourceID],
            let episodeIndex = detail.episodes.firstIndex(where: { $0.id == episodeID }),
            let sessionIndex = detail.episodes[episodeIndex].watchingSessions.firstIndex(
                where: { $0.id == sessionID }
            )
        else {
            throw SourceRepositoryError.sourceNotFound
        }

        let originalEpisode = detail.episodes[episodeIndex]
        let originalSession = originalEpisode.watchingSessions[sessionIndex]
        guard let eventIndex = originalSession.events.firstIndex(where: { $0.id == eventID }) else {
            throw SourceRepositoryError.unsupported
        }
        guard case let .liveHeartScream(existingMomentID, comment, pairID) =
            originalSession.events[eventIndex].kind
        else {
            throw SourceRepositoryError.unsupported
        }
        if existingMomentID != nil {
            return originalSession
        }

        var events = originalSession.events
        events[eventIndex] = WatchingSessionEvent(
            id: eventID,
            elapsedSeconds: events[eventIndex].elapsedSeconds,
            kind: .liveHeartScream(
                momentID: momentID,
                comment: comment,
                pairID: pairID
            )
        )
        let updatedSession = WatchingSessionSummary(
            id: originalSession.id,
            startedAt: originalSession.startedAt,
            durationSeconds: originalSession.durationSeconds,
            momentCount: originalSession.momentCount + 1,
            reactionCount: originalSession.reactionCount,
            events: events
        )
        var sessions = originalEpisode.watchingSessions
        sessions[sessionIndex] = updatedSession
        let updatedEpisode = EpisodeSummary(
            id: originalEpisode.id,
            locatorValues: originalEpisode.locatorValues,
            relatedURL: originalEpisode.relatedURL,
            momentCount: originalEpisode.momentCount + 1,
            viewedCount: originalEpisode.viewedCount,
            updatedAt: .now,
            progress: originalEpisode.progress,
            displayTitle: originalEpisode.displayTitle,
            watchingSessions: sessions
        )
        var episodes = detail.episodes
        episodes[episodeIndex] = updatedEpisode
        details[sourceID] = SourceDetail(summary: source, episodes: episodes)
        try persist()
        return updatedSession
    }

    static let fixtureDetails: [SourceDetail] = [
        makeDetail(
            id: "solo-leveling",
            displayName: "Solo Leveling 第2期",
            helperText: "Anime",
            mediaType: "anime",
            relatedURL: "https://example.com/solo-leveling",
            momentCount: 13,
            updatedAt: date(daysAgo: 2),
            episodes: [
                episode(
                    "solo-leveling-ep08",
                    ["episode_kind": "regular", "episode": "8"],
                    12,
                    5,
                    1,
                    displayTitle: "The Monarch Awakens",
                    watchingSessions: [
                        watchingSession(
                            "solo-ep08-session-1",
                            year: 2026,
                            month: 7,
                            day: 3,
                            hour: 22,
                            minute: 32,
                            durationSeconds: 4_980,
                            momentCount: 12,
                            reactionCount: 47
                        ),
                        watchingSession(
                            "solo-ep08-session-2",
                            year: 2026,
                            month: 6,
                            day: 28,
                            hour: 21,
                            minute: 15,
                            durationSeconds: 4_980,
                            momentCount: 12,
                            reactionCount: 47
                        ),
                        watchingSession(
                            "solo-ep08-session-3",
                            year: 2026,
                            month: 6,
                            day: 15,
                            hour: 23,
                            minute: 5,
                            durationSeconds: 4_740,
                            momentCount: 8,
                            reactionCount: 31
                        ),
                        watchingSession(
                            "solo-ep08-session-4",
                            year: 2026,
                            month: 5,
                            day: 30,
                            hour: 20,
                            minute: 47,
                            durationSeconds: 5_100,
                            momentCount: 5,
                            reactionCount: 22
                        ),
                    ]
                ),
                episode("solo-leveling-ep07", ["episode_kind": "regular", "episode": "7"], 9, 3, 3),
                episode("solo-leveling-ep06", ["episode_kind": "regular", "episode": "6"], 15, 4, 7, progress: 1),
                episode("solo-leveling-ep05", ["episode_kind": "regular", "episode": "5"], 7, 2, 14, progress: 1),
            ]
        ),
        makeDetail(
            id: "one-piece",
            displayName: "One Piece",
            helperText: "Manga",
            mediaType: "manga",
            relatedURL: "https://example.com/one-piece",
            momentCount: 842,
            updatedAt: date(hoursAgo: 5)
        ),
        makeDetail(
            id: "attack-on-titan",
            displayName: "Attack on Titan",
            helperText: "Anime",
            mediaType: "anime",
            relatedURL: "https://example.com/attack-on-titan",
            momentCount: 48,
            updatedAt: date(daysAgo: 7)
        ),
        makeDetail(
            id: "silent-voice",
            displayName: "Silent Voice",
            helperText: "Movie",
            mediaType: "movie",
            relatedURL: "https://example.com/silent-voice",
            momentCount: 5,
            updatedAt: date(daysAgo: 30)
        ),
        makeDetail(
            id: "spy-family-ep5",
            displayName: "SPY×FAMILY",
            helperText: "Drama",
            mediaType: "tv_drama",
            relatedURL: "https://example.com/spy-family",
            momentCount: 6,
            updatedAt: date(daysAgo: 4)
        ),
        makeDetail(
            id: "frieren-ep14",
            displayName: "Frieren",
            helperText: "Novel",
            mediaType: "novel",
            relatedURL: "https://example.com/frieren",
            momentCount: 28,
            updatedAt: date(daysAgo: 6)
        ),
        makeDetail(
            id: "aot-s3e17",
            displayName: "Attack on Titan",
            helperText: "アニメ",
            mediaType: "anime",
            relatedURL: "https://example.com/aot-s3e17",
            momentCount: 0,
            updatedAt: date(daysAgo: 8)
        ),
        makeDetail(
            id: "yt-live-2026-07-01",
            displayName: "YouTube Live",
            helperText: "配信全般",
            mediaType: "streaming",
            streamingPlatform: StreamingPlatform(id: .youtube),
            relatedURL: "https://youtube.com/",
            momentCount: 0,
            updatedAt: date(daysAgo: 10)
        ),
        makeDetail(
            id: "haikyu-s2e24",
            displayName: "Haikyu!!",
            helperText: "アニメ",
            mediaType: "anime",
            relatedURL: "https://example.com/haikyu",
            momentCount: 0,
            updatedAt: date(daysAgo: 12)
        ),
        makeDetail(
            id: "blue-lock-ep19",
            displayName: "Blue Lock",
            helperText: "アニメ",
            mediaType: "anime",
            relatedURL: "https://example.com/blue-lock",
            momentCount: 0,
            updatedAt: date(daysAgo: 15)
        ),
        makeDetail(
            id: "special-event-2026",
            displayName: "Special Event",
            helperText: "イベント・ファンミ",
            mediaType: "event_fanmeeting",
            relatedURL: "https://example.com/special-event",
            momentCount: 1,
            updatedAt: date(daysAgo: 20)
        ),
        makeDetail(
            id: "source-school-trip",
            displayName: "修学旅行で仲良くないグループに...",
            helperText: "Anime",
            mediaType: "anime",
            relatedURL: "https://example.com/school-trip",
            momentCount: 4,
            updatedAt: date(daysAgo: 20)
        ),
        makeDetail(
            id: "source-summer-drama",
            displayName: "真夏のドラマ",
            helperText: "Drama",
            mediaType: "tv_drama",
            relatedURL: "https://example.com/summer-drama",
            momentCount: 1,
            updatedAt: date(daysAgo: 20)
        ),
        makeDetail(
            id: "source-live",
            displayName: "Anniversary Live",
            helperText: "Live",
            mediaType: "live_concert",
            relatedURL: "https://example.com/anniversary-live",
            momentCount: 1,
            updatedAt: date(daysAgo: 20)
        ),
    ]

    private static func makeDetail(
        id: String,
        displayName: String,
        helperText: String,
        mediaType: String,
        streamingPlatform: StreamingPlatform? = nil,
        relatedURL: String,
        momentCount: Int,
        updatedAt: Date,
        episodes: [EpisodeSummary] = []
    ) -> SourceDetail {
        SourceDetail(
            summary: SourceSummary(
                id: id,
                displayName: displayName,
                helperText: helperText,
                mediaType: mediaType,
                streamingPlatform: streamingPlatform,
                relatedURL: URL(string: relatedURL)!,
                momentCount: momentCount,
                updatedAt: updatedAt
            ),
            episodes: episodes
        )
    }

    private static func episode(
        _ id: String,
        _ values: [String: String],
        _ momentCount: Int,
        _ viewedCount: Int,
        _ daysAgo: Int,
        progress: Double? = nil,
        displayTitle: String? = nil,
        watchingSessions: [WatchingSessionSummary] = []
    ) -> EpisodeSummary {
        EpisodeSummary(
            id: id,
            locatorValues: SourceLocatorSchema.schema(for: "anime")?.normalizedEpisodeValues(
                values.map { LocatorValue(key: $0.key, value: $0.value) }
            ) ?? [],
            relatedURL: URL(string: "https://example.com/episodes/\(id)"),
            momentCount: momentCount,
            viewedCount: viewedCount,
            updatedAt: date(daysAgo: daysAgo),
            progress: progress,
            displayTitle: displayTitle,
            watchingSessions: watchingSessions
        )
    }

    private static func watchingSession(
        _ id: String,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        durationSeconds: Int,
        momentCount: Int,
        reactionCount: Int
    ) -> WatchingSessionSummary {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startedAt = calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        ) ?? .now

        return WatchingSessionSummary(
            id: id,
            startedAt: startedAt,
            durationSeconds: durationSeconds,
            momentCount: momentCount,
            reactionCount: reactionCount,
            events: watchingSessionEvents(sessionID: id)
        )
    }

    private static func watchingSessionEvents(
        sessionID: String
    ) -> [WatchingSessionEvent] {
        [
            WatchingSessionEvent(
                id: "\(sessionID)-reaction-1",
                elapsedSeconds: 5 * 60 + 12,
                kind: .reaction(
                    WatchingSessionReaction(
                        reactionID: "emotional.naita",
                        displayText: "😭 Strong reaction"
                    )
                )
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-voice-1",
                elapsedSeconds: 8 * 60 + 45,
                kind: .voiceNote("This is getting insane…")
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-reaction-2",
                elapsedSeconds: 12 * 60 + 5,
                kind: .reaction(
                    WatchingSessionReaction(
                        reactionID: "positive.toutoi",
                        displayText: "♥ Amazing scene"
                    )
                )
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-moment",
                elapsedSeconds: 18 * 60 + 22,
                kind: .liveHeartScream(
                    momentID: nil,
                    comment: "That eye contact—every rewatch hits different.",
                    pairID: "kirito-asuna"
                )
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-reaction-3",
                elapsedSeconds: 25 * 60 + 40,
                kind: .reaction(
                    WatchingSessionReaction(
                        reactionID: "excited.kamikai",
                        displayText: "🔥 Peak fiction"
                    )
                )
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-voice-2",
                elapsedSeconds: 32 * 60 + 15,
                kind: .voiceNote("How did he survive that?")
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-reaction-4",
                elapsedSeconds: 44 * 60 + 9,
                kind: .reaction(
                    WatchingSessionReaction(
                        reactionID: "excited.shougeki",
                        displayText: "😮 Shocking twist"
                    )
                )
            ),
            WatchingSessionEvent(
                id: "\(sessionID)-reaction-5",
                elapsedSeconds: 68 * 60 + 44,
                kind: .reaction(
                    WatchingSessionReaction(
                        reactionID: "excited.hakushu",
                        displayText: "👏 Bravo"
                    )
                )
            ),
        ]
    }

    private static func isValidStreamingPlatform(
        _ platform: StreamingPlatform?,
        mediaType: String
    ) -> Bool {
        if mediaType == "streaming" {
            return platform?.isValid == true
        }
        return platform == nil
    }

    private func persist() throws {
        try onChange(sources.compactMap { details[$0.id] })
    }

    private static func date(daysAgo: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            byAdding: .day,
            value: -daysAgo,
            to: .now
        ) ?? .now
    }

    private static func date(hoursAgo: Int) -> Date {
        Calendar(identifier: .gregorian).date(
            byAdding: .hour,
            value: -hoursAgo,
            to: .now
        ) ?? .now
    }
}
