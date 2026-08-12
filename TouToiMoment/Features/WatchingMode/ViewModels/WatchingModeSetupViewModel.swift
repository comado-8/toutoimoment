import Combine
import Foundation

@MainActor
final class WatchingModeSetupViewModel: ObservableObject {
    @Published private(set) var loadState: WatchingModeLoadState = .idle
    @Published private(set) var sources: [SourceSummary] = []
    @Published private(set) var episodes: [EpisodeSummary] = []
    @Published private(set) var pairs: [PairSummary] = []
    @Published var selectedSourceID: String?
    @Published var selectedEpisodeID: String?
    @Published var selectedPairID: String?
    @Published var autoHashtags = "#TouToiMoment" {
        didSet {
            let limited = AutoHashtagPolicy.limitedInput(autoHashtags)
            if limited != autoHashtags { autoHashtags = limited }
        }
    }

    private let initialSourceID: String
    private let initialEpisodeID: String
    private let initialPairID: String?
    private let sourceRepository: any SourceRepository
    private let pairRepository: any PairRepository

    init(
        sourceID: String,
        episodeID: String,
        pairID: String? = nil,
        autoHashtags: String = "#TouToiMoment",
        sourceRepository: any SourceRepository,
        pairRepository: any PairRepository
    ) {
        initialSourceID = sourceID
        initialEpisodeID = episodeID
        initialPairID = pairID
        self.autoHashtags = AutoHashtagPolicy.limitedInput(autoHashtags)
        self.sourceRepository = sourceRepository
        self.pairRepository = pairRepository
    }

    var canContinue: Bool {
        selectedSource != nil && selectedEpisode != nil
    }

    var selectedSource: SourceSummary? {
        sources.first(where: { $0.id == selectedSourceID })
    }

    var selectedEpisode: EpisodeSummary? {
        episodes.first(where: { $0.id == selectedEpisodeID })
    }

    var selectedPair: PairSummary? {
        pairs.first(where: { $0.id == selectedPairID })
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        loadState = .loading
        do {
            async let sourcesTask = sourceRepository.fetchSources()
            async let pairsTask = pairRepository.fetchPairs()
            let (loadedSources, loadedPairs) = try await (sourcesTask, pairsTask)
            sources = loadedSources
            pairs = loadedPairs
            selectedPairID = loadedPairs.contains(where: { $0.id == initialPairID })
                ? initialPairID
                : nil
            selectedSourceID = loadedSources.contains(where: { $0.id == initialSourceID })
                ? initialSourceID
                : loadedSources.first?.id
            try await loadEpisodes(preferredEpisodeID: initialEpisodeID)
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }

    func retry() async {
        loadState = .idle
        await loadIfNeeded()
    }

    func selectSource(_ sourceID: String) async {
        guard sourceID != selectedSourceID else { return }
        selectedSourceID = sourceID
        selectedEpisodeID = nil
        do {
            try await loadEpisodes(preferredEpisodeID: nil)
        } catch {
            if selectedSourceID == sourceID {
                episodes = []
            }
        }
    }

    func selection() -> WatchingModeSelection? {
        guard let source = selectedSource, let episode = selectedEpisode else {
            return nil
        }
        let schema = SourceLocatorSchema.schema(for: source.mediaType)
            ?? SourceLocatorSchema.fallback
        return WatchingModeSelection(
            source: source,
            episode: episode,
            episodeDisplayName: schema.episodeDisplayName(for: episode.locatorValues),
            pair: selectedPair,
            autoHashtags: AutoHashtagPolicy.normalizedTags(autoHashtags)
                .joined(separator: " ")
        )
    }

    private func loadEpisodes(preferredEpisodeID: String?) async throws {
        guard let sourceID = selectedSourceID else {
            episodes = []
            return
        }
        let detail = try await sourceRepository.fetchSourceDetail(id: sourceID)
        guard selectedSourceID == sourceID else { return }
        episodes = detail?.episodes ?? []
        if let preferredEpisodeID,
           episodes.contains(where: { $0.id == preferredEpisodeID }) {
            selectedEpisodeID = preferredEpisodeID
        } else {
            selectedEpisodeID = episodes.first?.id
        }
    }
}
