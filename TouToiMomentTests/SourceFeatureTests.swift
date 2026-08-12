import Foundation
import SwiftUI
import Testing
@testable import TouToiMoment

@MainActor
struct SourceFeatureTests {
    @Test func repositoryReturnsFixtureSourcesAndExactEpisodeCount() async throws {
        let repository = InMemorySourceRepository()

        let sources = try await repository.fetchSources()
        let detail = try await repository.fetchSourceDetail(id: "solo-leveling")

        #expect(sources.prefix(4).map(\.displayName) == [
            "Solo Leveling 第2期",
            "One Piece",
            "Attack on Titan",
            "Silent Voice",
        ])
        #expect(detail?.summary.id == "solo-leveling")
        #expect(detail?.summary.relatedURL.absoluteString == "https://example.com/solo-leveling")
        #expect(detail?.episodes.count == 4)
        let schema = try #require(SourceLocatorSchema.schema(for: "anime"))
        #expect(detail?.episodes.map { schema.episodeDisplayName(for: $0.locatorValues) }
            == ["第8話", "第7話", "第6話", "第5話"])

        let streaming = try #require(
            await repository.fetchSourceDetail(id: "yt-live-2026-07-01")
        )
        #expect(streaming.summary.mediaType == "streaming")
        #expect(streaming.summary.streamingPlatform == StreamingPlatform(id: .youtube))
    }

    @Test func repositoryReturnsNilForMissingSource() async throws {
        let repository = InMemorySourceRepository()
        #expect(try await repository.fetchSourceDetail(id: "missing") == nil)
    }

    @Test func watchingSetupKeepsInitialEpisodeAndReloadsEpisodesAfterSourceChange() async throws {
        let repository = InMemorySourceRepository()
        let viewModel = WatchingModeSetupViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            sourceRepository: repository,
            pairRepository: InMemoryPairRepository()
        )

        await viewModel.loadIfNeeded()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.selectedSourceID == "solo-leveling")
        #expect(viewModel.selectedEpisodeID == "solo-leveling-ep08")
        #expect(viewModel.canContinue)
        #expect(viewModel.selectedPairID == nil)

        await viewModel.selectSource("one-piece")
        #expect(viewModel.selectedSourceID == "one-piece")
        #expect(viewModel.episodes.isEmpty)
        #expect(viewModel.selectedEpisodeID == nil)
        #expect(!viewModel.canContinue)
    }

    @Test func watchingSetupDoesNotApplyStaleEpisodesAfterSourceChange() async {
        let repository = ControlledEpisodeRepository()
        let viewModel = WatchingModeSetupViewModel(
            sourceID: "source-a",
            episodeID: "episode-a",
            sourceRepository: repository,
            pairRepository: InMemoryPairRepository()
        )

        let initialLoad = Task { await viewModel.loadIfNeeded() }
        await repository.waitForDetailRequest(id: "source-a")
        let sourceChange = Task { await viewModel.selectSource("source-b") }
        await repository.waitForDetailRequest(id: "source-b")
        repository.resolveDetail(
            id: "source-b",
            episodes: [Self.regressionEpisode(id: "episode-b")]
        )
        await sourceChange.value
        repository.resolveDetail(
            id: "source-a",
            episodes: [Self.regressionEpisode(id: "episode-a")]
        )
        await initialLoad.value

        #expect(viewModel.selectedSourceID == "source-b")
        #expect(viewModel.episodes.map(\.id) == ["episode-b"])
        #expect(viewModel.selectedEpisodeID == "episode-b")
    }

    @Test func watchingTimerExcludesPausedTimeAndAggregatesRapidMatchingReactions() async throws {
        let repository = InMemorySourceRepository()
        let detail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let episode = try #require(
            detail.episodes.first(where: { $0.id == "solo-leveling-ep08" })
        )
        var currentDate = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: "#TouToiMoment"
            ),
            repository: repository,
            now: { currentDate }
        )
        let reaction = try #require(
            ReactionCatalog.reaction(withID: "excited.kamikai")
        )

        viewModel.start()
        currentDate.addTimeInterval(0.5)
        #expect(viewModel.elapsedTimeInterval() == 0.5)
        currentDate.addTimeInterval(9.5)
        viewModel.recordReaction(reaction)
        currentDate.addTimeInterval(1)
        viewModel.recordReaction(reaction)
        viewModel.pause()
        currentDate.addTimeInterval(20)
        #expect(viewModel.elapsedSeconds() == 11)
        viewModel.resume()
        currentDate.addTimeInterval(4)

        #expect(viewModel.elapsedSeconds() == 15)
        #expect(viewModel.reactionCount == 2)
        #expect(viewModel.events.count == 1)
        guard case let .reaction(savedReaction) = viewModel.events[0].kind else {
            Issue.record("Expected an aggregated reaction event")
            return
        }
        #expect(savedReaction.reactionID == "excited.kamikai")
        #expect(savedReaction.count == 2)
    }

    @Test func emptyWatchingSessionRequiresSixtyActiveSecondsToSave() async throws {
        let repository = InMemorySourceRepository()
        let detail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let episode = try #require(
            detail.episodes.first(where: { $0.id == "solo-leveling-ep08" })
        )
        var currentDate = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: ""
            ),
            repository: repository,
            now: { currentDate }
        )

        viewModel.start()
        currentDate.addTimeInterval(59)
        #expect(viewModel.historySaveReason == .insufficient)
        #expect(!viewModel.shouldSaveHistory)
        #expect(await viewModel.finish() == nil)

        let after = try #require(
            await repository.fetchSourceDetail(id: detail.summary.id)
        )
        let unchangedEpisode = try #require(
            after.episodes.first(where: { $0.id == episode.id })
        )
        #expect(unchangedEpisode.watchingSessions.count == episode.watchingSessions.count)
        #expect(unchangedEpisode.viewedCount == episode.viewedCount)
    }

    @Test func emptyWatchingSessionSavesAtSixtyActiveSecondsAndExcludesPauseTime() async throws {
        let repository = InMemorySourceRepository()
        let detail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let episode = try #require(
            detail.episodes.first(where: { $0.id == "solo-leveling-ep08" })
        )
        var currentDate = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: ""
            ),
            repository: repository,
            now: { currentDate }
        )

        viewModel.start()
        currentDate.addTimeInterval(30)
        viewModel.pause()
        currentDate.addTimeInterval(120)
        #expect(!viewModel.shouldSaveHistory)
        viewModel.resume()
        currentDate.addTimeInterval(30)
        #expect(viewModel.historySaveReason == .duration)
        #expect(viewModel.shouldSaveHistory)

        let saved = try #require(await viewModel.finish())
        #expect(saved.durationSeconds == 60)
        #expect(saved.events.isEmpty)
    }

    @Test func momentOrReactionMakesShortWatchingSessionSaveable() async throws {
        let reactionRepository = InMemorySourceRepository()
        let detail = try #require(
            await reactionRepository.fetchSourceDetail(id: "solo-leveling")
        )
        let episode = try #require(
            detail.episodes.first(where: { $0.id == "solo-leveling-ep08" })
        )
        let reaction = try #require(ReactionCatalog.reaction(withID: "excited.kamikai"))
        var currentDate = Date(timeIntervalSince1970: 1_800_000_000)
        let reactionViewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: ""
            ),
            repository: reactionRepository,
            now: { currentDate }
        )
        reactionViewModel.start()
        currentDate.addTimeInterval(1)
        reactionViewModel.recordReaction(reaction)
        #expect(reactionViewModel.historySaveReason == .activity)
        #expect(reactionViewModel.shouldSaveHistory)
        #expect(await reactionViewModel.finish() != nil)

        let momentRepository = InMemorySourceRepository()
        let momentViewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: ""
            ),
            repository: momentRepository,
            now: { currentDate }
        )
        momentViewModel.start()
        let pair = try #require(await InMemoryPairRepository().fetchPairs().first)
        let draft = momentViewModel.makeMomentDraft(
            heartScream: "尊い",
            pair: pair,
            timestampSeconds: 0
        )
        momentViewModel.recordMomentCandidate(
            draft: draft,
            comment: "尊い",
            elapsedSeconds: 0
        )
        #expect(momentViewModel.historySaveReason == .activity)
        #expect(momentViewModel.shouldSaveHistory)
        #expect(await momentViewModel.finish() != nil)
    }

    @Test func watchingMomentCandidatesOnlyStageSelectedMomentsAndKeepEveryLiveLogEntry() async throws {
        let repository = InMemorySourceRepository()
        let detail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let episode = try #require(
            detail.episodes.first(where: { $0.id == "solo-leveling-ep08" })
        )
        let pair = try #require(await InMemoryPairRepository().fetchPairs().first)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: pair,
                autoHashtags: ""
            ),
            repository: repository
        )
        viewModel.start()

        let firstDraft = viewModel.makeMomentDraft(
            heartScream: "残したい",
            pair: pair,
            timestampSeconds: 12
        )
        let secondDraft = viewModel.makeMomentDraft(
            heartScream: "ログだけ残す",
            pair: pair,
            timestampSeconds: 24
        )
        let first = try #require(viewModel.recordMomentCandidate(
            draft: firstDraft,
            comment: "残したい",
            elapsedSeconds: 12
        ))
        _ = viewModel.recordMomentCandidate(
            draft: secondDraft,
            comment: "ログだけ残す",
            elapsedSeconds: 24
        )

        viewModel.stageMomentCandidates(selectedIDs: [first.id])

        #expect(viewModel.createdMomentCount == 1)
        #expect(viewModel.events.count == 2)
        guard
            case let .liveHeartScream(firstMomentID, _, _) = viewModel.events[0].kind,
            case let .liveHeartScream(secondMomentID, _, _) = viewModel.events[1].kind
        else {
            Issue.record("Expected two Moment Live Log entries")
            return
        }
        #expect(firstMomentID != nil)
        #expect(secondMomentID == nil)

        let reservedID = firstMomentID
        viewModel.stageMomentCandidates(selectedIDs: [first.id])
        guard case let .liveHeartScream(retryMomentID, _, _) = viewModel.events[0].kind else {
            Issue.record("Expected the staged Moment entry")
            return
        }
        #expect(retryMomentID == reservedID)
    }

    @Test func watchingLiveHeartScreamCanBeRecordedWithoutPair() async throws {
        let repository = InMemorySourceRepository()
        let detail = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        let episode = try #require(detail.episodes.first)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: ""
            ),
            repository: repository
        )

        viewModel.start()
        let draft = viewModel.makeMomentDraft(
            heartScream: "Pairなしでも残したい",
            pair: nil,
            timestampSeconds: 8
        )
        let candidate = try #require(viewModel.recordMomentCandidate(
            draft: draft,
            comment: draft.heartScream,
            elapsedSeconds: 8
        ))

        #expect(candidate.draft.selectedPairID == nil)
        guard case let .liveHeartScream(momentID, comment, pairID) = viewModel.events.first?.kind else {
            Issue.record("Expected a Live HeartScream event")
            return
        }
        #expect(momentID == nil)
        #expect(comment == "Pairなしでも残したい")
        #expect(pairID == nil)
    }

    @Test func reactionFlightQueueCapsOnlyVisualEventsAndCyclesDeterministicLanes() {
        var queue = ReactionFlightQueue()
        let origin = CGPoint(x: 196, y: 620)
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        for index in 0..<(ReactionFlightQueue.maximumActiveCount + 4) {
            queue.enqueue(
                emoji: "🔥",
                origin: origin,
                at: start.addingTimeInterval(Double(index) * 0.01),
                reducesMotion: false
            )
        }

        #expect(queue.events.count == ReactionFlightQueue.maximumActiveCount)
        #expect(queue.nextSequence == ReactionFlightQueue.maximumActiveCount + 4)
        #expect(queue.events.first?.lane == 4)
        #expect(queue.events.last?.lane == 3)
        #expect(queue.events.allSatisfy { $0.origin == origin })
    }

    @Test func reactionFlightQueueUsesShortFadeForReduceMotion() {
        var queue = ReactionFlightQueue()
        let event = queue.enqueue(
            emoji: "😭",
            origin: CGPoint(x: 120, y: 600),
            at: Date(timeIntervalSince1970: 1_800_000_000),
            reducesMotion: true
        )

        #expect(event.duration == ReactionFlightPath.reducedMotionDuration)
        queue.remove(id: event.id)
        #expect(queue.events.isEmpty)
    }

    @Test func watchingReactionCatalogContainsAllDocumentedCategoriesAndReactions() {
        #expect(ReactionCatalog.sections.count == 5)
        #expect(ReactionCatalog.sections.flatMap(\.reactions).count == 35)
        #expect(ReactionCatalog.reaction(withID: "positive.toutoi")?.displayText == "❤️ 尊い")
        #expect(ReactionCatalog.reaction(withID: "excited.hakushu") != nil)
    }

    @Test func finishingWatchingSessionPrependsHistoryAndUpdatesEpisodeCounts() async throws {
        let repository = InMemorySourceRepository()
        let before = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let episode = try #require(
            before.episodes.first(where: { $0.id == "solo-leveling-ep08" })
        )
        var currentDate = Date(timeIntervalSince1970: 1_800_000_000)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: before.summary,
                episode: episode,
                episodeDisplayName: "第8話",
                pair: nil,
                autoHashtags: ""
            ),
            repository: repository,
            now: { currentDate }
        )

        viewModel.start()
        currentDate.addTimeInterval(42)
        let pair = try #require(await InMemoryPairRepository().fetchPairs().first)
        let draft = viewModel.makeMomentDraft(
            heartScream: "最高",
            pair: pair,
            timestampSeconds: 42
        )
        let candidate = try #require(viewModel.recordMomentCandidate(
            draft: draft,
            comment: "最高",
            elapsedSeconds: 42
        ))
        viewModel.stageMomentCandidates(selectedIDs: [candidate.id])
        let saved = try #require(await viewModel.finish())
        let after = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let updatedEpisode = try #require(
            after.episodes.first(where: { $0.id == episode.id })
        )

        #expect(saved.durationSeconds == 42)
        #expect(saved.momentCount == 1)
        #expect(viewModel.momentCandidates.first?.savedMomentID != nil)
        #expect(updatedEpisode.watchingSessions.first?.id == saved.id)
        #expect(updatedEpisode.viewedCount == episode.viewedCount + 1)
        #expect(updatedEpisode.momentCount == episode.momentCount + 1)

        #expect(await viewModel.finish() == nil)
        let afterDuplicateAttempt = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let episodeAfterDuplicateAttempt = try #require(
            afterDuplicateAttempt.episodes.first(where: { $0.id == episode.id })
        )
        #expect(
            episodeAfterDuplicateAttempt.watchingSessions.count
                == updatedEpisode.watchingSessions.count
        )
    }

    @Test func createSourceKeepsRelatedURLAndCreatesEmptyDetail() async throws {
        let repository = InMemorySourceRepository(sources: [])
        let url = URL(string: "https://example.com/new-work")!

        let created = try await repository.createSource(
            request: SourceCreateRequest(
                displayName: "New Work",
                helperText: "アニメ",
                mediaType: "anime",
                relatedURL: url
            )
        )
        let sources = try await repository.fetchSources()
        let detail = try await repository.fetchSourceDetail(id: created.id)

        #expect(sources == [created])
        #expect(created.relatedURL == url)
        #expect(created.momentCount == 0)
        #expect(detail?.summary == created)
        #expect(detail?.episodes.isEmpty == true)
    }

    @Test func repositoryRejectsNonWebRelatedURL() async {
        let repository = InMemorySourceRepository(sources: [])
        let request = SourceCreateRequest(
            displayName: "Invalid",
            helperText: "アニメ",
            mediaType: "anime",
            relatedURL: URL(fileURLWithPath: "/tmp/source")
        )

        await #expect(throws: SourceRepositoryError.invalidURL) {
            try await repository.createSource(request: request)
        }
    }

    @Test func streamingSourceRequiresAndPreservesOneValidPlatform() async throws {
        let repository = InMemorySourceRepository(sources: [])
        let url = URL(string: "https://example.com/live")!
        let missingPlatform = SourceCreateRequest(
            displayName: "Live",
            helperText: "配信全般",
            mediaType: "streaming",
            relatedURL: url
        )

        await #expect(throws: SourceRepositoryError.invalidStreamingPlatform) {
            try await repository.createSource(request: missingPlatform)
        }

        let created = try await repository.createSource(
            request: SourceCreateRequest(
                displayName: "Live",
                helperText: "配信全般",
                mediaType: "streaming",
                streamingPlatform: StreamingPlatform(id: .youtube),
                relatedURL: url
            )
        )
        #expect(created.streamingPlatform == StreamingPlatform(id: .youtube))
        #expect(created.contextualHelperText == "配信全般 · YouTube")
        #expect(NewMomentSelectableOption(source: created).subtitle == "配信全般 · YouTube")

        let updated = try await repository.updateSource(
            id: created.id,
            request: SourceUpdateRequest(
                displayName: "Updated Live",
                streamingPlatform: StreamingPlatform(id: .other, customName: "  Kick  "),
                relatedURL: url
            )
        )
        #expect(updated.streamingPlatform?.id == .other)
        #expect(updated.streamingPlatform?.customName == "Kick")
        #expect(
            try await repository.fetchSourceDetail(id: created.id)?.summary.streamingPlatform
                == updated.streamingPlatform
        )
    }

    @Test func nonStreamingSourceRejectsStreamingPlatformMetadata() async {
        let repository = InMemorySourceRepository(sources: [])
        let request = SourceCreateRequest(
            displayName: "Video",
            helperText: "YouTube動画",
            mediaType: "youtube_video",
            streamingPlatform: StreamingPlatform(id: .youtube),
            relatedURL: URL(string: "https://youtube.com/watch?v=1")!
        )

        await #expect(throws: SourceRepositoryError.invalidStreamingPlatform) {
            try await repository.createSource(request: request)
        }
    }

    @Test func updateSourceChangesDisplayValuesAndPreservesEpisodes() async throws {
        let repository = InMemorySourceRepository()
        let before = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        let url = URL(string: "https://example.org/updated")!

        let updated = try await repository.updateSource(
            id: "solo-leveling",
            request: SourceUpdateRequest(
                displayName: "俺だけレベルアップな件",
                relatedURL: url
            )
        )
        let after = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))

        #expect(updated.displayName == "俺だけレベルアップな件")
        #expect(updated.mediaType == before.summary.mediaType)
        #expect(updated.helperText == before.summary.helperText)
        #expect(updated.relatedURL == url)
        #expect(after.episodes == before.episodes)
        #expect(after.summary.momentCount == before.summary.momentCount)
    }

    @Test func episodeCreationNormalizesValuesKeepsURLAndInsertsAtBeginning() async throws {
        let repository = InMemorySourceRepository()
        let before = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))

        let episode = try await repository.createEpisode(
            sourceID: "solo-leveling",
            request: EpisodeCreateRequest(
                locatorValues: [
                    .init(key: "episode_kind", value: "regular"),
                    .init(key: "episode", value: "９"),
                ],
                relatedURL: URL(string: "https://example.com/solo/9")
            )
        )
        let after = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))

        let schema = try #require(SourceLocatorSchema.schema(for: "anime"))
        #expect(schema.episodeDisplayName(for: episode.locatorValues) == "第9話")
        #expect(episode.relatedURL?.absoluteString == "https://example.com/solo/9")
        #expect(after.episodes.count == before.episodes.count + 1)
        #expect(after.episodes.first == episode)
    }

    @Test func episodeUpdatePreservesHistoryAndCounts() async throws {
        let repository = InMemorySourceRepository()
        let beforeDetail = try #require(
            await repository.fetchSourceDetail(id: "solo-leveling")
        )
        let before = try #require(
            beforeDetail.episodes.first { $0.id == "solo-leveling-ep08" }
        )
        let updatedURL = URL(string: "https://example.com/solo/episode-8")!

        let updated = try await repository.updateEpisode(
            sourceID: "solo-leveling",
            episodeID: before.id,
            request: EpisodeCreateRequest(
                locatorValues: [
                    .init(key: "episode_kind", value: "regular"),
                    .init(key: "episode", value: "８"),
                ],
                relatedURL: updatedURL
            )
        )

        #expect(updated.id == before.id)
        #expect(updated.relatedURL == updatedURL)
        #expect(updated.momentCount == before.momentCount)
        #expect(updated.viewedCount == before.viewedCount)
        #expect(updated.displayTitle == before.displayTitle)
        #expect(updated.watchingSessions == before.watchingSessions)
    }

    @Test func episodeRequiresItsSchemaNumber() async {
        let repository = InMemorySourceRepository()

        await #expect(throws: SourceRepositoryError.invalidEpisode) {
            try await repository.createEpisode(
                sourceID: "solo-leveling",
                request: EpisodeCreateRequest(
                    locatorValues: [.init(key: "episode_kind", value: "regular")],
                    relatedURL: nil
                )
            )
        }
    }

    @Test func deletingSourceAlsoDeletesItsEpisodes() async throws {
        let repository = InMemorySourceRepository()

        try await repository.deleteSource(id: "solo-leveling")

        #expect(try await repository.fetchSourceDetail(id: "solo-leveling") == nil)
        #expect(try await repository.fetchSources().contains { $0.id == "solo-leveling" } == false)
    }

    @Test func newSourceDraftUsesExistingMediumSchemaAndValidatesRelatedURL() {
        var draft = NewSourceDraft()

        #expect(draft.mediaType == "anime")
        #expect(!draft.isValid)

        draft.displayName = "  Solo Leveling  "
        draft.mediaType = "manga"
        draft.relatedURLText = "  https://example.com/solo  "

        #expect(draft.isValid)
        #expect(draft.makeRequest()?.displayName == "Solo Leveling")
        #expect(draft.makeRequest()?.helperText == "漫画・コミック")
        #expect(draft.makeRequest()?.relatedURL.absoluteString == "https://example.com/solo")

        draft.relatedURLText = "ftp://example.com/solo"
        #expect(!draft.isValid)
    }

    @Test func streamingDraftRequiresPresetOrTrimmedOtherAndOmitsItForOtherMedia() {
        var draft = NewSourceDraft()
        draft.displayName = "Live"
        draft.mediaType = "streaming"
        draft.relatedURLText = "https://example.com/live"

        #expect(!draft.isValid)

        draft.streamingPlatformID = .youtube
        #expect(draft.isValid)
        #expect(draft.makeRequest()?.streamingPlatform == StreamingPlatform(id: .youtube))

        draft.streamingPlatformID = .other
        draft.customStreamingPlatformName = "   "
        #expect(!draft.isValid)

        draft.customStreamingPlatformName = "  Kick  "
        #expect(draft.makeRequest()?.streamingPlatform?.customName == "Kick")

        draft.mediaType = "youtube_video"
        #expect(draft.isValid)
        #expect(draft.makeRequest()?.streamingPlatform == nil)
    }

    @Test func listCreationReturnsToAllAndInsertsTheCreatedSourceFirst() async throws {
        let viewModel = SourceListViewModel(repository: InMemorySourceRepository())
        await viewModel.loadIfNeeded()
        viewModel.selectedFilter = .manga

        let created = try await viewModel.createSource(
            SourceCreateRequest(
                displayName: "New Anime",
                helperText: "アニメ",
                mediaType: "anime",
                relatedURL: URL(string: "https://example.com/new-anime")!
            )
        )

        #expect(viewModel.selectedFilter == .all)
        #expect(viewModel.displayedSources.first?.id == created.id)
    }

    @Test func sourceSheetRetainsInputAfterFailureAndCanRetry() async {
        var attempts = 0
        let viewModel = NewSourceSheetViewModel { request in
            attempts += 1
            if attempts == 1 {
                throw TestError.expected
            }
            return SourceSummary(
                id: "retry-created",
                displayName: request.displayName,
                helperText: request.helperText,
                mediaType: request.mediaType,
                streamingPlatform: request.streamingPlatform,
                relatedURL: request.relatedURL
            )
        }
        viewModel.draft.displayName = "Retry Source"
        viewModel.draft.relatedURLText = "https://example.com/retry"

        #expect(await viewModel.save() == nil)
        #expect(viewModel.saveState == .failed)
        #expect(viewModel.draft.displayName == "Retry Source")
        #expect(viewModel.draft.relatedURLText == "https://example.com/retry")

        #expect(await viewModel.save()?.id == "retry-created")
        #expect(viewModel.saveState == .idle)
        #expect(attempts == 2)
    }

    @Test func episodeSheetUsesStructuredFieldsAndRetainsInputForRetry() async throws {
        var attempts = 0
        let schema = try #require(SourceLocatorSchema.schema(for: "anime"))
        let viewModel = NewEpisodeSheetViewModel(schema: schema) { request in
            attempts += 1
            if attempts == 1 {
                throw TestError.expected
            }
            return EpisodeSummary(
                id: "episode",
                locatorValues: request.locatorValues,
                relatedURL: request.relatedURL,
                momentCount: 0,
                viewedCount: 0,
                updatedAt: .now,
                progress: nil
            )
        }
        #expect(!viewModel.canSave)
        let episodeField = try #require(schema.episodeFields.first { $0.key == "episode" })
        viewModel.updateValue("９", for: episodeField)
        viewModel.draft.relatedURLText = "https://example.com/9"
        #expect(viewModel.canSave)

        #expect(await viewModel.save() == nil)
        #expect(viewModel.draft.value(for: "episode") == "9")
        #expect(await viewModel.save()?.relatedURL?.host == "example.com")
        #expect(attempts == 2)
    }

    @Test func listFilterIsSingleSelectionAndAllRestoresEverySource() async {
        let viewModel = SourceListViewModel(repository: InMemorySourceRepository())
        await viewModel.loadIfNeeded()

        let allCount = viewModel.displayedSources.count
        viewModel.selectedFilter = .anime
        #expect(!viewModel.displayedSources.isEmpty)
        #expect(viewModel.displayedSources.allSatisfy { $0.mediaType == "anime" })

        viewModel.selectedFilter = .manga
        #expect(viewModel.displayedSources.map(\.id) == ["one-piece"])

        viewModel.selectedFilter = .all
        #expect(viewModel.displayedSources.count == allCount)
    }

    @Test func listViewModelExposesFailureAndRetry() async {
        let repository = FlakySourceRepository()
        let viewModel = SourceListViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        #expect(viewModel.loadState == .failed)

        await viewModel.retry()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.displayedSources.map(\.id) == ["recovered"])
    }

    @Test func sourceRefreshFailureKeepsExistingSourcesAndPublishesError() async {
        let repository = SuccessfulThenFailingSourceRepository()
        let viewModel = SourceListViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        let existing = viewModel.sources
        await viewModel.refresh()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.sources == existing)
        #expect(viewModel.refreshErrorMessage != nil)
    }

    @Test func failedWatchingSaveCanResumeThePreviouslyRunningSession() async throws {
        let repository = FailingMutationSourceRepository()
        let detail = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        let episode = try #require(detail.episodes.first)
        let viewModel = WatchingModeViewModel(
            selection: WatchingModeSelection(
                source: detail.summary,
                episode: episode,
                episodeDisplayName: "Episode",
                pair: nil,
                autoHashtags: ""
            ),
            repository: repository
        )
        let reaction = try #require(ReactionCatalog.allReactions.first)
        viewModel.start()
        viewModel.recordReaction(reaction)

        #expect(await viewModel.finish() == nil)
        #expect(viewModel.phase == .paused)
        #expect(viewModel.saveErrorMessage != nil)
        viewModel.cancelFinish()
        #expect(viewModel.phase == .running)
    }

    @Test func savedMomentCountDoesNotDependOnMatchingEvents() {
        let candidate = WatchingMomentCandidate(
            id: "candidate",
            eventID: "missing-event",
            elapsedSeconds: 1,
            comment: "Heart",
            draft: NewMomentDraft(heartScream: "Heart"),
            savedMomentID: "saved-moment"
        )

        #expect(WatchingModeViewModel.savedMomentCount(in: [candidate]) == 1)
    }

    @Test func failedHistoryLinkRemovesTheMomentCreatedBeforeLinking() async throws {
        let repository = FailingMutationSourceRepository()
        let detail = try #require(await repository.fetchSourceDetail(id: "solo-leveling"))
        let episode = try #require(detail.episodes.first)
        let session = try #require(
            episode.watchingSessions.first { session in
                session.events.contains { event in
                    if case let .liveHeartScream(momentID, _, _) = event.kind {
                        return momentID == nil
                    }
                    return false
                }
            }
        )
        let event = try #require(session.events.first { event in
            if case let .liveHeartScream(momentID, _, _) = event.kind {
                return momentID == nil
            }
            return false
        })
        let viewModel = WatchHistoryDetailViewModel(
            sourceID: detail.id,
            episodeID: episode.id,
            sessionID: session.id,
            repository: repository
        )
        let momentStore = MomentStore(moments: [])
        await viewModel.loadIfNeeded()

        await viewModel.saveLiveHeartScreamAsMoment(
            eventID: event.id,
            pairRepository: InMemoryPairRepository(),
            momentStore: momentStore
        )

        #expect(momentStore.moments.isEmpty)
        #expect(viewModel.saveMomentErrorMessage != nil)
    }

    @Test func detailViewModelCreatesEpisodeAndUpdatesExactCount() async throws {
        let viewModel = SourceDetailViewModel(
            sourceID: "solo-leveling",
            repository: InMemorySourceRepository()
        )
        await viewModel.loadIfNeeded()
        let before = try #require(viewModel.detail?.episodes.count)

        let episode = try await viewModel.createEpisode(
            EpisodeCreateRequest(
                locatorValues: [
                    .init(key: "episode_kind", value: "regular"),
                    .init(key: "episode", value: "9"),
                ],
                relatedURL: nil
            )
        )

        #expect(viewModel.detail?.episodes.count == before + 1)
        #expect(viewModel.detail?.episodes.first?.id == episode.id)
    }

    @Test func relativeDateFormatterUsesTheRequestedReferenceDate() {
        let formatter = SourceRelativeDateFormatter(locale: Locale(identifier: "en_US"))
        let reference = Date(timeIntervalSince1970: 1_000_000)
        let date = reference.addingTimeInterval(-2 * 24 * 60 * 60)

        let value = formatter.string(for: date, relativeTo: reference)
        #expect(value.contains("2"))
        #expect(value.lowercased().contains("ago"))
    }

    @Test func sourceDetailRouteKeepsBottomTabBarVisible() {
        let route = AppRoute.sourceDetail("solo-leveling")
        #expect(route == .sourceDetail("solo-leveling"))
        #expect(!route.hidesBottomTabBar)
    }

    @Test func episodeDetailViewModelLoadsExactEpisodeAndOptionalMetadata() async throws {
        let viewModel = EpisodeDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            repository: InMemorySourceRepository()
        )

        await viewModel.loadIfNeeded()

        let content = try #require(viewModel.content)
        #expect(viewModel.loadState == .loaded)
        #expect(content.source.id == "solo-leveling")
        #expect(content.episode.id == "solo-leveling-ep08")
        #expect(content.episode.displayTitle == "The Monarch Awakens")
        #expect(content.episode.watchingSessions.count == 4)
        #expect(content.locatorDisplayName == "第8話")
    }

    @Test func episodeDetailRefreshesNewWatchHistoryWithoutDroppingCurrentContent() async throws {
        let repository = InMemorySourceRepository()
        let viewModel = EpisodeDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            repository: repository
        )
        await viewModel.loadIfNeeded()
        let initialContent = try #require(viewModel.content)

        let created = try await repository.createWatchingSession(
            sourceID: initialContent.source.id,
            episodeID: initialContent.episode.id,
            request: WatchingSessionCreateRequest(
                startedAt: Date(timeIntervalSince1970: 1_900_000_000),
                durationSeconds: 60,
                createdMomentCount: 0,
                reactionCount: 0,
                events: []
            )
        )
        await viewModel.refresh()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.content?.episode.watchingSessions.first?.id == created.id)
        #expect(
            viewModel.content?.episode.watchingSessions.count
                == initialContent.episode.watchingSessions.count + 1
        )
    }

    @Test func episodeDetailViewModelHandlesMissingSourceAndEpisode() async {
        let missingSource = EpisodeDetailViewModel(
            sourceID: "missing",
            episodeID: "episode",
            repository: InMemorySourceRepository()
        )
        await missingSource.loadIfNeeded()
        #expect(missingSource.loadState == .missing)
        #expect(missingSource.content == nil)

        let missingEpisode = EpisodeDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "missing",
            repository: InMemorySourceRepository()
        )
        await missingEpisode.loadIfNeeded()
        #expect(missingEpisode.loadState == .missing)
        #expect(missingEpisode.content == nil)
    }

    @Test func episodeDetailViewModelAllowsEpisodeWithoutDisplayTitle() async throws {
        let viewModel = EpisodeDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep07",
            repository: InMemorySourceRepository()
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.loadState == .loaded)
        #expect(try #require(viewModel.content).episode.displayTitle == nil)
    }

    @Test func episodeDetailViewModelExposesRepositoryFailure() async {
        let viewModel = EpisodeDetailViewModel(
            sourceID: "source",
            episodeID: "episode",
            repository: ThrowingEpisodeDetailRepository()
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.loadState == .failed)
        #expect(viewModel.content == nil)
    }

    @Test func watchHistoryDetailLoadsExactSessionAndLiveLog() async throws {
        let viewModel = WatchHistoryDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            sessionID: "solo-ep08-session-2",
            repository: InMemorySourceRepository()
        )

        await viewModel.loadIfNeeded()

        let content = try #require(viewModel.content)
        #expect(viewModel.loadState == .loaded)
        #expect(content.source.id == "solo-leveling")
        #expect(content.episode.id == "solo-leveling-ep08")
        #expect(content.session.id == "solo-ep08-session-2")
        #expect(content.session.events.count == 8)
        #expect(content.session.events.map(\.elapsedSeconds) == [
            312, 525, 725, 1_102, 1_540, 1_935, 2_649, 4_124,
        ])
    }

    @Test func watchHistorySavesAnUnselectedLiveHeartScreamAsMomentOnlyOnce() async throws {
        let repository = InMemorySourceRepository()
        let momentStore = MomentStore(moments: [])
        let viewModel = WatchHistoryDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            sessionID: "solo-ep08-session-2",
            repository: repository
        )
        await viewModel.loadIfNeeded()
        let before = try #require(viewModel.content)
        let event = try #require(before.session.events.first(where: {
            if case let .liveHeartScream(momentID, _, _) = $0.kind {
                return momentID == nil
            }
            return false
        }))

        await viewModel.saveLiveHeartScreamAsMoment(
            eventID: event.id,
            pairRepository: InMemoryPairRepository(),
            momentStore: momentStore
        )

        let after = try #require(viewModel.content)
        #expect(viewModel.saveMomentErrorMessage == nil)
        #expect(after.session.momentCount == before.session.momentCount + 1)
        #expect(momentStore.moments.count == 1)
        #expect(momentStore.moments[0].sourceID == "solo-leveling")
        #expect(momentStore.moments[0].episodeID == "solo-leveling-ep08")
        #expect(momentStore.moments[0].pairID == "kirito-asuna")
        guard case let .liveHeartScream(savedMomentID, _, _) =
            after.session.events.first(where: { $0.id == event.id })?.kind
        else {
            Issue.record("Expected the Live HeartScream event to remain in the Live Log")
            return
        }
        #expect(savedMomentID == momentStore.moments[0].id)

        await viewModel.saveLiveHeartScreamAsMoment(
            eventID: event.id,
            pairRepository: InMemoryPairRepository(),
            momentStore: momentStore
        )
        #expect(viewModel.content?.session.momentCount == after.session.momentCount)
        #expect(momentStore.moments.count == 1)
    }

    @Test func watchHistoryDetailHandlesMissingSessionAndRepositoryFailure() async {
        let missing = WatchHistoryDetailViewModel(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            sessionID: "missing",
            repository: InMemorySourceRepository()
        )
        await missing.loadIfNeeded()
        #expect(missing.loadState == .missing)
        #expect(missing.content == nil)

        let failed = WatchHistoryDetailViewModel(
            sourceID: "source",
            episodeID: "episode",
            sessionID: "session",
            repository: ThrowingEpisodeDetailRepository()
        )
        await failed.loadIfNeeded()
        #expect(failed.loadState == .failed)
        #expect(failed.content == nil)
    }

    @Test func watchHistoryRouteKeepsIDsAndBottomTabBarVisible() {
        let route = AppRoute.watchHistoryDetail(
            sourceID: "source",
            episodeID: "episode",
            sessionID: "session"
        )

        #expect(
            route == .watchHistoryDetail(
                sourceID: "source",
                episodeID: "episode",
                sessionID: "session"
            )
        )
        #expect(!route.hidesBottomTabBar)

        let savedResultRoute = AppRoute.watchHistoryDetail(
            sourceID: "source",
            episodeID: "episode",
            sessionID: "session",
            showsSavedConfirmation: true
        )
        #expect(savedResultRoute != route)
    }

    @Test func watchingSessionEventFormatterFormatsMinuteAndHourOffsets() {
        let formatter = WatchingSessionEventFormatter()

        #expect(formatter.elapsedTimeText(seconds: 5 * 60 + 12) == "05:12")
        #expect(formatter.elapsedTimeText(seconds: 68 * 60 + 44) == "1:08:44")
        #expect(formatter.elapsedTimeText(seconds: -1) == "00:00")
    }

    @Test func episodeDetailRouteKeepsBothIDsAndBottomTabBarVisible() {
        let route = AppRoute.episodeDetail(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08"
        )

        #expect(route == .episodeDetail(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08"
        ))
        #expect(!route.hidesBottomTabBar)
        #expect(AppChromeVisibility.shouldShowBottomTabBar(
            navigationHidesBottomTabBar: route.hidesBottomTabBar,
            isKeyboardVisible: false
        ))

        let historyRoute = AppRoute.episodeDetail(
            sourceID: "solo-leveling",
            episodeID: "solo-leveling-ep08",
            initialSection: .watchHistory
        )
        #expect(historyRoute != route)
        #expect(!historyRoute.hidesBottomTabBar)
    }

    @Test func episodeMomentProjectionFiltersExactIDsAndSortsTimestampNilLast() {
        let moments = [
            makeMoment(
                id: "nil-first",
                sourceID: "source",
                episodeID: "episode"
            ),
            makeMoment(
                id: "later",
                sourceID: "source",
                episodeID: "episode",
                timestamp: "01:08:44"
            ),
            makeMoment(
                id: "other-episode",
                sourceID: "source",
                episodeID: "other",
                timestamp: "00:01:00"
            ),
            makeMoment(
                id: "earlier",
                sourceID: "source",
                episodeID: "episode",
                timestamp: "18:42"
            ),
            makeMoment(
                id: "other-source",
                sourceID: "other",
                episodeID: "episode",
                timestamp: "00:00:01"
            ),
        ]

        let result = SourceMomentProjection.episodeMoments(
            sourceID: "source",
            episodeID: "episode",
            moments: moments
        )

        #expect(result.map(\.id) == ["earlier", "later", "nil-first"])
    }

    @Test func episodeTimelineExportRendersDynamicThreeTimesImage() throws {
        let document = makeTimelineExportDocument(momentCount: 2)
        let pages = EpisodeTimelineExportRenderer.imagePages(for: document)
        let page = try #require(pages.first)
        let image = try #require(
            EpisodeTimelineExportRenderer.image(
                for: document,
                page: page,
                totalPageCount: pages.count
            )
        )

        #expect(pages.count == 1)
        #expect(image.size.width == 342)
        #expect(image.size.height >= 612)
        #expect(image.scale == 3)
        #expect(image.size.height * image.scale <= 16_384)
    }

    @Test func episodeTimelineExportSplitsLongTimelineWithoutDroppingMoments() {
        let document = makeTimelineExportDocument(
            momentCount: 24,
            heartText: Array(
                repeating: "何度見ても胸がいっぱいになる大切な瞬間。 ",
                count: 18
            ).joined()
        )
        let pages = EpisodeTimelineExportRenderer.imagePages(for: document)

        #expect(pages.count > 1)
        #expect(pages.flatMap(\.moments).map(\.id) == document.moments.map(\.id))
        #expect(
            pages.allSatisfy {
                EpisodeTimelineExportRenderer.measuredHeight(
                    document: document,
                    page: $0,
                    totalPageCount: pages.count,
                    canvasWidth: EpisodeTimelineExportRenderer.imageWidth
                ) <= EpisodeTimelineExportRenderer.maximumImageHeight
            }
        )
    }

    @Test func episodeTimelineExportCreatesA4MultipagePDF() throws {
        let document = makeTimelineExportDocument(
            momentCount: 16,
            heartText: "That final look still devastates me every time."
        )
        let pages = EpisodeTimelineExportRenderer.pdfPages(for: document)
        let data = try #require(
            EpisodeTimelineExportRenderer.pdfData(for: document, pages: pages)
        )
        let provider = try #require(CGDataProvider(data: data as CFData))
        let pdf = try #require(CGPDFDocument(provider))

        #expect(pages.count > 1)
        #expect(pdf.numberOfPages == pages.count)
        let mediaBox = pdf.page(at: 1)?.getBoxRect(.mediaBox)
        #expect(abs((mediaBox?.width ?? 0) - 595.2) < 0.5)
        #expect(abs((mediaBox?.height ?? 0) - 841.8) < 0.5)
    }

    @Test func episodeTimelinePhotoSaveUsesNumberedNamesAndReportsPartialFailure() async {
        let document = makeTimelineExportDocument(momentCount: 2)
        let pages = [
            EpisodeTimelineExportPage(index: 0, moments: [document.moments[0]]),
            EpisodeTimelineExportPage(index: 1, moments: [document.moments[1]]),
        ]
        let successSaver = FakeEpisodeTimelinePhotoSaver()
        let success = await EpisodeTimelinePhotoSaveCoordinator.save(
            document: document,
            pages: pages,
            using: successSaver
        )

        #expect(success == .success(savedCount: 2))
        #expect(successSaver.filenames.count == 2)
        #expect(successSaver.filenames[0].hasSuffix("_01.png"))
        #expect(successSaver.filenames[1].hasSuffix("_02.png"))

        let failingSaver = FakeEpisodeTimelinePhotoSaver(failAt: 1)
        let failure = await EpisodeTimelinePhotoSaveCoordinator.save(
            document: document,
            pages: pages,
            using: failingSaver
        )
        #expect(failure == .saveFailed(savedCount: 1))
    }

    @Test func episodeTimelineFilenameRemovesUnsafeCharacters() {
        let filename = EpisodeTimelineExportFilename.make(
            sourceName: "Solo / Leveling",
            episodeName: "EP:08",
            date: Date(timeIntervalSince1970: 0)
        )

        #expect(!filename.contains("/"))
        #expect(!filename.contains(":"))
        #expect(filename.contains("Timeline"))
    }

    @Test func watchHistoryLiveLogExportRendersDynamicThreeTimesImage() throws {
        let document = makeLiveLogExportDocument(eventCount: 3)
        let pages = WatchHistoryLiveLogExportRenderer.imagePages(for: document)
        let page = try #require(pages.first)
        let image = try #require(
            WatchHistoryLiveLogExportRenderer.image(
                for: document,
                page: page,
                totalPageCount: pages.count
            )
        )

        #expect(pages.count == 1)
        #expect(image.size.width == 342)
        #expect(image.size.height >= 612)
        #expect(image.scale == 3)
        #expect(image.size.height * image.scale <= 16_384)
    }

    @Test func watchHistoryLiveLogExportSplitsWithoutDroppingEvents() {
        let document = makeLiveLogExportDocument(eventCount: 36)
        let pages = WatchHistoryLiveLogExportRenderer.pdfPages(for: document)

        #expect(pages.count > 1)
        #expect(
            pages.flatMap(\.events).map(\.id)
                == document.session.events.map(\.id)
        )
    }

    @Test func watchHistoryLiveLogExportCreatesA4MultipagePDF() throws {
        let document = makeLiveLogExportDocument(eventCount: 24)
        let pages = WatchHistoryLiveLogExportRenderer.pdfPages(for: document)
        let data = try #require(
            WatchHistoryLiveLogExportRenderer.pdfData(
                for: document,
                pages: pages
            )
        )
        let provider = try #require(CGDataProvider(data: data as CFData))
        let pdf = try #require(CGPDFDocument(provider))

        #expect(pages.count > 1)
        #expect(pdf.numberOfPages == pages.count)
        let mediaBox = pdf.page(at: 1)?.getBoxRect(.mediaBox)
        #expect(abs((mediaBox?.width ?? 0) - 595.2) < 0.5)
        #expect(abs((mediaBox?.height ?? 0) - 841.8) < 0.5)
    }

    @Test func episodeWatchHistoryFormatterFormatsDuration() {
        let formatter = EpisodeWatchHistoryFormatter(
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        let hoursAndMinutes = formatter.durationText(seconds: 4_980)
        let minutes = formatter.durationText(seconds: 1_800)
        #expect(hoursAndMinutes.contains("1"))
        #expect(hoursAndMinutes.contains("23"))
        #expect(minutes.contains("30"))
        #expect(formatter.dateTimeText(
            for: Date(timeIntervalSince1970: 1_784_329_920)
        ).contains("•"))
    }

    @Test func directMomentProjectionShowsAllMomentsForEpisodeUnsupportedSource() {
        let moments = [
            makeMoment(id: "event-1", sourceID: "event", episodeID: nil),
            makeMoment(id: "event-2", sourceID: "event", episodeID: "legacy-episode"),
            makeMoment(id: "other", sourceID: "other", episodeID: nil),
        ]

        let result = SourceMomentProjection.directMoments(
            sourceID: "event",
            supportsEpisodes: false,
            moments: moments
        )

        #expect(result.map(\.id) == ["event-1", "event-2"])
    }

    @Test func directMomentProjectionShowsOnlyUnassignedMomentsForEpisodeSource() {
        let moments = [
            makeMoment(id: "unassigned-new", sourceID: "anime", episodeID: nil),
            makeMoment(id: "assigned", sourceID: "anime", episodeID: "episode-1"),
            makeMoment(id: "other-source", sourceID: "other", episodeID: nil),
            makeMoment(id: "unassigned-old", sourceID: "anime", episodeID: nil),
        ]

        let result = SourceMomentProjection.directMoments(
            sourceID: "anime",
            supportsEpisodes: true,
            moments: moments
        )

        #expect(result.map(\.id) == ["unassigned-new", "unassigned-old"])
    }

    @Test func directMomentProjectionReflectsStoreAddFavoriteAndReferenceRemoval() {
        let store = MomentStore(moments: [])
        let draft = NewMomentDraft(
            selectedPair: .init(
                id: "pair",
                displayName: "A ・ B",
                nickname: "A ・ B"
            ),
            selectedSource: .init(
                id: "event",
                displayName: "Special Event",
                helperText: "イベント・ファンミ",
                mediaType: "event_fanmeeting"
            ),
            heartScream: "忘れたくない"
        )

        store.add(draft: draft)
        let momentID = store.moments[0].id
        #expect(SourceMomentProjection.directMoments(
            sourceID: "event",
            supportsEpisodes: false,
            moments: store.moments
        ).map(\.id) == [momentID])

        store.toggleFavorite(id: momentID)
        #expect(store.moment(id: momentID)?.isFavorite == true)

        store.clearSourceReferences(id: "event")
        #expect(SourceMomentProjection.directMoments(
            sourceID: "event",
            supportsEpisodes: false,
            moments: store.moments
        ).isEmpty)
    }

    private func makeMoment(
        id: String,
        sourceID: String,
        episodeID: String?,
        timestamp: String? = nil
    ) -> MomentCardModel {
        MomentCardModel(
            id: id,
            sceneText: "Scene",
            heartText: "Heart",
            caption: "Caption",
            pairID: "pair",
            pairName: "A ・ B",
            sourceID: sourceID,
            sourceName: "Source",
            mediaType: "anime",
            episodeID: episodeID,
            contextValues: timestamp.map {
                [.init(key: "timestamp", value: $0)]
            } ?? [],
            reactionIDs: [],
            reactionLabels: [],
            leadingDotColor: .blue,
            trailingDotColor: .pink,
            createdAt: .now,
            isFavorite: false
        )
    }

    private func makeTimelineExportDocument(
        momentCount: Int,
        heartText: String = "That eye contact—every rewatch hits different."
    ) -> EpisodeTimelineExportDocument {
        EpisodeTimelineExportDocument(
            sourceName: "Solo Leveling 第2期",
            locatorDisplayName: "第8話",
            episodeDisplayTitle: "The Monarch Awakens",
            moments: (0..<momentCount).map { index in
                EpisodeTimelineMoment(
                    id: "timeline-\(index)",
                    heartText: heartText,
                    timestamp: "18:\(String(format: "%02d", index % 60))",
                    pairName: "Jinwoo ・ Cha Hae-In",
                    reactionLabels: ["🥰 キュン"],
                    isFavorite: index.isMultiple(of: 2)
                )
            }
        )
    }

    private func makeLiveLogExportDocument(
        eventCount: Int
    ) -> WatchHistoryLiveLogExportDocument {
        let events = (0..<eventCount).map { index in
            let kind: WatchingSessionEvent.Kind
            switch index % 3 {
            case 0:
                kind = .reaction(
                    WatchingSessionReaction(
                        reactionID: "emotional.naita",
                        displayText: "😭 Strong reaction"
                    )
                )
            case 1:
                kind = .voiceNote("This is getting intense...")
            default:
                kind = .liveHeartScream(
                    momentID: "moment-\(index)",
                    comment: "That eye contact—every rewatch hits different.",
                    pairID: "jinwoo-cha-haein"
                )
            }
            return WatchingSessionEvent(
                id: "live-log-\(index)",
                elapsedSeconds: index * 75,
                kind: kind
            )
        }
        return WatchHistoryLiveLogExportDocument(
            sourceName: "Solo Leveling 第2期",
            locatorDisplayName: "第8話",
            episodeDisplayTitle: "The Monarch Awakens",
            session: WatchingSessionSummary(
                id: "session",
                startedAt: Date(timeIntervalSince1970: 1_783_154_720),
                durationSeconds: 4_980,
                momentCount: 12,
                reactionCount: 47,
                events: events
            )
        )
    }

    private enum TestError: Error {
        case expected
    }

    private static func regressionEpisode(id: String) -> EpisodeSummary {
        EpisodeSummary(
            id: id,
            locatorValues: [
                .init(key: "episode_kind", value: "regular"),
                .init(key: "episode", value: "1"),
            ],
            relatedURL: nil,
            momentCount: 0,
            viewedCount: 0,
            updatedAt: .now,
            progress: nil
        )
    }
}

@MainActor
private final class FakeEpisodeTimelinePhotoSaver: EpisodeTimelinePhotoLibrarySaving {
    private let failAt: Int?
    private(set) var filenames: [String] = []

    init(failAt: Int? = nil) {
        self.failAt = failAt
    }

    func savePNGData(_ data: Data, filename: String) async throws {
        if filenames.count == failAt {
            throw MomentPhotoLibrarySaveError.saveFailed
        }
        filenames.append(filename)
    }
}

@MainActor
private final class ThrowingEpisodeDetailRepository: SourceRepository {
    func fetchSources() async throws -> [SourceSummary] {
        []
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? {
        throw TestError.expected
    }

    func createSource(request: SourceCreateRequest) async throws -> SourceSummary {
        throw TestError.expected
    }

    private enum TestError: Error {
        case expected
    }
}

@MainActor
private final class FlakySourceRepository: SourceRepository {
    private var fetchCount = 0

    func fetchSources() async throws -> [SourceSummary] {
        fetchCount += 1
        if fetchCount == 1 {
            throw TestError.expected
        }

        return [
            SourceSummary(
                id: "recovered",
                displayName: "Recovered",
                helperText: "Anime",
                mediaType: "anime",
                relatedURL: URL(string: "https://example.com/recovered")!
            ),
        ]
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? {
        nil
    }

    func createSource(request: SourceCreateRequest) async throws -> SourceSummary {
        SourceSummary(
            id: "created",
            displayName: request.displayName,
            helperText: request.helperText,
            mediaType: request.mediaType,
            streamingPlatform: request.streamingPlatform,
            relatedURL: request.relatedURL
        )
    }

    private enum TestError: Error {
        case expected
    }
}

@MainActor
private final class SuccessfulThenFailingSourceRepository: SourceRepository {
    private var fetchCount = 0
    private let source = SourceSummary(
        id: "existing",
        displayName: "Existing",
        helperText: "Anime",
        mediaType: "anime",
        relatedURL: URL(string: "https://example.com/existing")!
    )

    func fetchSources() async throws -> [SourceSummary] {
        fetchCount += 1
        if fetchCount > 1 { throw SourceFeatureRegressionError.expected }
        return [source]
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? { nil }
    func createSource(request: SourceCreateRequest) async throws -> SourceSummary { source }
}

@MainActor
private final class FailingMutationSourceRepository: SourceRepository {
    private let base = InMemorySourceRepository()

    func fetchSources() async throws -> [SourceSummary] {
        try await base.fetchSources()
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? {
        try await base.fetchSourceDetail(id: id)
    }

    func createSource(request: SourceCreateRequest) async throws -> SourceSummary {
        try await base.createSource(request: request)
    }

    func createWatchingSession(
        sourceID: String,
        episodeID: String,
        request: WatchingSessionCreateRequest
    ) async throws -> WatchingSessionSummary {
        throw SourceFeatureRegressionError.expected
    }

    func saveLiveHeartScreamAsMoment(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        eventID: String,
        momentID: String
    ) async throws -> WatchingSessionSummary {
        throw SourceFeatureRegressionError.expected
    }
}

private enum SourceFeatureRegressionError: Error {
    case expected
}
