import Foundation
import Testing
@testable import TouToiMoment

@MainActor
struct NewMomentCreationViewModelTests {
    @Test func flowStartsWithRequiredHeartScreamAndKeepsDraftAcrossAllPhases() {
        let viewModel = makeViewModel()

        #expect(viewModel.phase == .heartScream)
        #expect(!viewModel.canAdvanceHeartScream)

        viewModel.updateHeartScream(" \n ")
        #expect(!viewModel.canAdvanceHeartScream)

        viewModel.updateHeartScream("尊い……！")
        viewModel.advanceFromHeartScream()
        #expect(viewModel.phase == .scene)

        viewModel.updateScene("再会した瞬間")
        viewModel.advanceFromScene()
        #expect(viewModel.phase == .details)
        #expect(viewModel.draft.heartScream == "尊い……！")
        #expect(viewModel.draft.sceneSummary == "再会した瞬間")
    }

    @Test func optionalSceneCanBeSkipped() {
        let viewModel = makeViewModel()
        viewModel.updateHeartScream("好き")
        viewModel.advanceFromHeartScream()
        viewModel.advanceFromScene()

        #expect(viewModel.phase == .details)
        #expect(viewModel.draft.sceneSummary.isEmpty)
    }

    @Test func saveRequiresTrimmedHeartScreamButPairIsOptional() async throws {
        let viewModel = makeViewModel()
        await viewModel.loadOptionsIfNeeded()

        viewModel.updateHeartScream("尊い")
        #expect(viewModel.canSave)

        let pairID = try #require(viewModel.pairOptions.first?.id)
        viewModel.selectPair(id: pairID)
        #expect(viewModel.canSave)

        viewModel.selectPair(id: nil)
        #expect(viewModel.draft.selectedPairID == nil)
        #expect(viewModel.canSave)

        viewModel.updateHeartScream(" \n")
        #expect(!viewModel.canSave)
    }

    @Test func initialPairIsSelectedAfterOptionsLoad() async {
        let pairID = "kirito-asuna"
        let viewModel = NewMomentCreationViewModel(
            pairRepository: InMemoryPairRepository(),
            sourceRepository: InMemorySourceRepository(),
            initialPairID: pairID
        )

        await viewModel.loadOptionsIfNeeded()

        #expect(viewModel.draft.selectedPairID == pairID)
        #expect(viewModel.draft.selectedPair?.displayName == "きりあす")
    }

    @Test func editingCaptureFromDetailsReturnsToDetailsAndKeepsOtherValues() async throws {
        let viewModel = makeViewModel()
        await viewModel.loadOptionsIfNeeded()
        let pairID = try #require(viewModel.pairOptions.first?.id)

        viewModel.updateHeartScream("最初の叫び")
        viewModel.advanceFromHeartScream()
        viewModel.updateScene("場面")
        viewModel.advanceFromScene()
        viewModel.selectPair(id: pairID)

        viewModel.editHeartScream()
        viewModel.updateHeartScream("編集後の叫び")
        viewModel.advanceFromHeartScream()

        #expect(viewModel.phase == .details)
        #expect(viewModel.draft.sceneSummary == "場面")
        #expect(viewModel.draft.selectedPairID == pairID)
        #expect(viewModel.draft.heartScream == "編集後の叫び")
    }

    @Test func episodeDetailsStartCollapsedAndTogglingDoesNotClearDraft() {
        let draft = NewMomentDraft(
            selectedSource: .init(
                id: "source-anime",
                displayName: "作品名 第2期",
                helperText: "アニメ",
                mediaType: "anime"
            ),
            contextValues: [.init(key: "timestamp", value: "00:12:34")],
            heartScream: "尊い",
            contextMediaType: "anime"
        )
        let viewModel = makeViewModel(draft: draft)

        #expect(!viewModel.isSourceDetailExpanded)
        viewModel.isSourceDetailExpanded = true
        viewModel.isSourceDetailExpanded = false
        #expect(viewModel.draft.contextValues.first?.value == "00:12:34")
    }

    @Test func episodeCreationUsesTheSelectedSourceSchemaAndAutoSelectsIt() async throws {
        let viewModel = makeViewModel()
        await viewModel.loadOptionsIfNeeded()
        viewModel.selectSource(id: "solo-leveling")

        let created = try await viewModel.createEpisode(
            EpisodeCreateRequest(
                locatorValues: [
                    .init(key: "episode_kind", value: "special"),
                    .init(key: "episode", value: "9.5"),
                ],
                relatedURL: URL(string: "https://example.com/special-9-5")
            )
        )

        #expect(viewModel.draft.selectedEpisodeID == created.id)
        #expect(viewModel.draft.selectedEpisode?.displayName == "特別編 9.5")
        #expect(viewModel.draft.selectedEpisode?.locatorValues == created.locatorValues)

        viewModel.selectSource(id: "one-piece")
        #expect(viewModel.draft.selectedEpisode == nil)
        #expect(viewModel.contextFields.map(\.key) == ["page"])
    }

    @Test func staleEpisodeLoadDoesNotReplaceEpisodesForNewSource() async {
        let repository = ControlledEpisodeRepository()
        let viewModel = NewMomentCreationViewModel(
            pairRepository: InMemoryPairRepository(),
            sourceRepository: repository
        )
        await viewModel.loadOptionsIfNeeded()

        viewModel.selectSource(id: "source-a")
        let firstLoad = Task { await viewModel.loadEpisodes() }
        await repository.waitForDetailRequest(id: "source-a")

        viewModel.selectSource(id: "source-b")
        let secondLoad = Task { await viewModel.loadEpisodes() }
        await repository.waitForDetailRequest(id: "source-b")
        repository.resolveDetail(id: "source-b", episodes: [Self.episode(id: "episode-b")])
        await secondLoad.value
        repository.resolveDetail(id: "source-a", episodes: [Self.episode(id: "episode-a")])
        await firstLoad.value

        #expect(viewModel.draft.selectedSourceID == "source-b")
        #expect(viewModel.episodes.map(\.id) == ["episode-b"])
    }

    @Test func episodeCreatedForOldSourceIsNotInsertedIntoCurrentSelection() async throws {
        let repository = ControlledEpisodeRepository()
        let viewModel = NewMomentCreationViewModel(
            pairRepository: InMemoryPairRepository(),
            sourceRepository: repository
        )
        await viewModel.loadOptionsIfNeeded()
        viewModel.selectSource(id: "source-a")

        let creation = Task {
            try await viewModel.createEpisode(
                EpisodeCreateRequest(
                    locatorValues: [
                        .init(key: "episode_kind", value: "regular"),
                        .init(key: "episode", value: "1"),
                    ],
                    relatedURL: nil
                )
            )
        }
        await repository.waitForCreateRequest()
        viewModel.selectSource(id: "source-b")
        repository.resolveCreate(with: Self.episode(id: "created-for-a"))
        _ = try await creation.value

        #expect(viewModel.draft.selectedSourceID == "source-b")
        #expect(viewModel.episodes.isEmpty)
        #expect(viewModel.draft.selectedEpisodeID == nil)
    }

    @Test func refreshingEpisodesDoesNotClearExistingListWhileRequestIsPending() async {
        let repository = ControlledEpisodeRepository()
        let viewModel = NewMomentCreationViewModel(
            pairRepository: InMemoryPairRepository(),
            sourceRepository: repository
        )
        await viewModel.loadOptionsIfNeeded()
        viewModel.selectSource(id: "source-a")

        let initialLoad = Task { await viewModel.loadEpisodes() }
        await repository.waitForDetailRequest(id: "source-a")
        repository.resolveDetail(id: "source-a", episodes: [Self.episode(id: "existing")])
        await initialLoad.value

        let refresh = Task { await viewModel.loadEpisodes() }
        await repository.waitForDetailRequest(id: "source-a")
        #expect(viewModel.episodes.map(\.id) == ["existing"])
        repository.resolveDetail(id: "source-a", episodes: [Self.episode(id: "updated")])
        await refresh.value
        #expect(viewModel.episodes.map(\.id) == ["updated"])
    }

    private static func episode(id: String) -> EpisodeSummary {
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

    private func makeViewModel(
        draft: NewMomentDraft = NewMomentDraft()
    ) -> NewMomentCreationViewModel {
        NewMomentCreationViewModel(
            draft: draft,
            pairRepository: InMemoryPairRepository(),
            sourceRepository: InMemorySourceRepository()
        )
    }
}

@MainActor
final class ControlledEpisodeRepository: SourceRepository {
    private var detailContinuations: [String: [CheckedContinuation<SourceDetail?, any Error>]] = [:]
    private var createContinuation: CheckedContinuation<EpisodeSummary, any Error>?

    func fetchSources() async throws -> [SourceSummary] {
        ["source-a", "source-b"].map { id in
            SourceSummary(
                id: id,
                displayName: id,
                helperText: "Anime",
                mediaType: "anime",
                relatedURL: URL(string: "https://example.com/\(id)")!
            )
        }
    }

    func fetchSourceDetail(id: String) async throws -> SourceDetail? {
        try await withCheckedThrowingContinuation { continuation in
            detailContinuations[id, default: []].append(continuation)
        }
    }

    func createSource(request: SourceCreateRequest) async throws -> SourceSummary {
        throw SourceRepositoryError.unsupported
    }

    func createEpisode(
        sourceID: String,
        request: EpisodeCreateRequest
    ) async throws -> EpisodeSummary {
        try await withCheckedThrowingContinuation { continuation in
            createContinuation = continuation
        }
    }

    func waitForDetailRequest(id: String) async {
        while detailContinuations[id]?.isEmpty != false {
            await Task.yield()
        }
    }

    func resolveDetail(id: String, episodes: [EpisodeSummary]) {
        guard var continuations = detailContinuations[id], !continuations.isEmpty else { return }
        let continuation = continuations.removeFirst()
        detailContinuations[id] = continuations
        let source = SourceSummary(
            id: id,
            displayName: id,
            helperText: "Anime",
            mediaType: "anime",
            relatedURL: URL(string: "https://example.com/\(id)")!
        )
        continuation.resume(returning: SourceDetail(summary: source, episodes: episodes))
    }

    func waitForCreateRequest() async {
        while createContinuation == nil {
            await Task.yield()
        }
    }

    func resolveCreate(with episode: EpisodeSummary) {
        createContinuation?.resume(returning: episode)
        createContinuation = nil
    }
}
