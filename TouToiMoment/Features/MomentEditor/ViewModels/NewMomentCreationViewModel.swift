import Combine
import Foundation

enum NewMomentCreationPhase: Hashable {
    case heartScream
    case scene
    case details
}

@MainActor
final class NewMomentCreationViewModel: ObservableObject {
    @Published private(set) var draft: NewMomentDraft
    @Published private(set) var phase: NewMomentCreationPhase = .heartScream
    @Published private(set) var pairOptions: [NewMomentSelectableOption] = []
    @Published private(set) var sourceOptions: [NewMomentSelectableOption] = []
    @Published private(set) var episodes: [EpisodeSummary] = []
    @Published private(set) var reactionSelectionIDs: Set<String> = []
    @Published var isSourceDetailExpanded = false
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingEpisodes = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var episodeErrorMessage: String?

    private let pairRepository: any PairRepository
    private let sourceRepository: any SourceRepository
    private let initialPairID: String?
    private let initialSourceID: String?
    private let initialEpisodeID: String?
    private var didApplyInitialContext = false
    private var captureReturnPhase: NewMomentCreationPhase?
    private var episodeLoadGeneration = 0

    init(
        draft: NewMomentDraft = NewMomentDraft(),
        pairRepository: any PairRepository,
        sourceRepository: any SourceRepository,
        initialPairID: String? = nil,
        initialSourceID: String? = nil,
        initialEpisodeID: String? = nil
    ) {
        self.draft = draft
        self.pairRepository = pairRepository
        self.sourceRepository = sourceRepository
        self.initialPairID = initialPairID
        self.initialSourceID = initialSourceID
        self.initialEpisodeID = initialEpisodeID
        self.reactionSelectionIDs = Set(draft.selectedReactions.map(\.id))
        configureContextForCurrentSource()
    }

    var canAdvanceHeartScream: Bool {
        draft.hasRequiredHeartScream
    }

    var canSave: Bool {
        draft.hasRequiredHeartScream
            && draft.isWithinTextLimits
            && hasValidMomentLocation
    }

    var hasEnteredContent: Bool {
        draft.hasAnyCreationInput
    }

    var contextFields: [MomentLocationField] {
        sourceSchema.momentLocationFields.map(MomentLocationField.init)
    }

    var sourceSchema: SourceLocatorSchema {
        let mediaType = draft.selectedSource?.mediaType ?? SourceLocatorSchema.fallbackMediaType
        return SourceLocatorSchema.schema(for: mediaType) ?? .fallback
    }

    var hasValidMomentLocation: Bool {
        sourceSchema.momentLocationFields.allSatisfy { field in
            LocatorValuePolicy.isValid(draft.contextValue(for: field.key), for: field)
        }
    }

    func updateHeartScream(_ value: String) {
        draft.updateHeartScream(value)
    }

    func updateScene(_ value: String) {
        draft.updateSceneSummary(value)
    }

    func updateMomentTitle(_ value: String) {
        draft.updateMomentTitle(value)
    }

    func updateMomentDate(_ value: Date) {
        draft.updateMomentDate(value)
    }

    func advanceFromHeartScream() {
        guard canAdvanceHeartScream else { return }
        if captureReturnPhase == .details {
            captureReturnPhase = nil
            phase = .details
        } else {
            phase = .scene
        }
    }

    func advanceFromScene() {
        captureReturnPhase = nil
        phase = .details
    }

    func returnFromScene() {
        phase = .heartScream
    }

    func editHeartScream() {
        captureReturnPhase = .details
        phase = .heartScream
    }

    func editScene() {
        captureReturnPhase = .details
        phase = .scene
    }

    func cancelCaptureEdit() {
        guard captureReturnPhase == .details else { return }
        captureReturnPhase = nil
        phase = .details
    }

    func loadOptionsIfNeeded() async {
        guard pairOptions.isEmpty, sourceOptions.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let pairsTask = pairRepository.fetchPairs()
            async let sourcesTask = sourceRepository.fetchSources()
            let (pairs, sources) = try await (pairsTask, sourcesTask)
            pairOptions = pairs.map {
                NewMomentSelectableOption(
                    id: $0.id,
                    title: $0.displayName,
                    subtitle: $0.subtitle,
                    helperText: AppStrings.newMomentStep1MomentCount(count: $0.momentCount),
                    leadingColorHex: $0.leadingColorHex,
                    trailingColorHex: $0.trailingColorHex,
                    pairMember1Name: $0.member1Name,
                    pairMember2Name: $0.member2Name
                )
            }
            sourceOptions = sources.map(NewMomentSelectableOption.init(source:))
            await applyInitialContextIfNeeded()
            errorMessage = nil
        } catch {
            errorMessage = AppStrings.newMomentStep1LoadError
        }
    }

    func retryOptions() async {
        pairOptions = []
        sourceOptions = []
        await loadOptionsIfNeeded()
    }

    func selectPair(id: String?) {
        guard let id else {
            draft.clearPair()
            return
        }
        guard let option = pairOptions.first(where: { $0.id == id }) else { return }
        draft.selectPair(
            id: option.id,
            displayName: option.title,
            nickname: option.subtitle ?? option.title,
            member1Name: option.pairMember1Name,
            member2Name: option.pairMember2Name,
            leadingColorHex: option.leadingColorHex,
            trailingColorHex: option.trailingColorHex
        )
    }

    func createPair(member1: String, member2: String, displayName: String) async throws {
        let first = PairTextPolicy.limitedMember(member1)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let second = PairTextPolicy.limitedMember(member2)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty else { throw PairRepositoryError.invalidPair }
        let customName = PairTextPolicy.limitedDisplayName(displayName)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let pair = try await pairRepository.createPair(
            request: PairCreateRequest(
                member1Name: first,
                member2Name: second.isEmpty ? nil : second,
                nickname: customName,
                leadingColorHex: "#3B82F6",
                trailingColorHex: second.isEmpty ? nil : "#F472B6"
            )
        )
        let option = NewMomentSelectableOption(
            id: pair.id,
            title: pair.displayName,
            subtitle: pair.subtitle,
            helperText: AppStrings.newMomentStep1MomentCount(count: 0),
            leadingColorHex: pair.leadingColorHex,
            trailingColorHex: pair.trailingColorHex,
            pairMember1Name: pair.member1Name,
            pairMember2Name: pair.member2Name
        )
        pairOptions.insert(option, at: 0)
        selectPair(id: option.id)
    }

    func createPair(request: PairCreateRequest) async throws -> PairSummary {
        let pair = try await pairRepository.createPair(request: request)
        let option = NewMomentSelectableOption(
            id: pair.id,
            title: pair.displayName,
            subtitle: pair.subtitle,
            helperText: AppStrings.newMomentStep1MomentCount(count: pair.momentCount),
            leadingColorHex: pair.leadingColorHex,
            trailingColorHex: pair.trailingColorHex,
            pairMember1Name: pair.member1Name,
            pairMember2Name: pair.member2Name
        )
        pairOptions.removeAll { $0.id == option.id }
        pairOptions.insert(option, at: 0)
        selectPair(id: option.id)
        return pair
    }

    func selectSource(id: String?) {
        guard let id else {
            draft.clearSource()
            episodes = []
            configureContextForCurrentSource()
            return
        }
        guard let option = sourceOptions.first(where: { $0.id == id }) else { return }
        let changed = draft.selectedSourceID != id
        draft.selectSource(
            id: option.id,
            displayName: option.title,
            helperText: option.subtitle ?? option.helperText ?? "",
            mediaType: option.sourceMediaType ?? SourceLocatorSchema.fallbackMediaType
        )
        if changed {
            episodeLoadGeneration += 1
            isLoadingEpisodes = false
            episodes = []
            configureContextForCurrentSource()
        }
    }

    func createSource(_ request: SourceCreateRequest) async throws -> SourceSummary {
        let source = try await sourceRepository.createSource(request: request)
        let option = NewMomentSelectableOption(source: source)
        sourceOptions.removeAll { $0.id == option.id }
        sourceOptions.insert(option, at: 0)
        selectSource(id: option.id)
        errorMessage = nil
        return source
    }

    func loadEpisodes() async {
        guard let sourceID = draft.selectedSourceID else {
            episodeLoadGeneration += 1
            isLoadingEpisodes = false
            episodes = []
            return
        }
        episodeLoadGeneration += 1
        let generation = episodeLoadGeneration
        isLoadingEpisodes = true
        defer {
            if episodeLoadGeneration == generation {
                isLoadingEpisodes = false
            }
        }
        do {
            let loadedEpisodes = try await sourceRepository.fetchSourceDetail(id: sourceID)?.episodes ?? []
            guard episodeLoadGeneration == generation, draft.selectedSourceID == sourceID else {
                return
            }
            episodes = loadedEpisodes
            episodeErrorMessage = nil
        } catch {
            guard episodeLoadGeneration == generation, draft.selectedSourceID == sourceID else {
                return
            }
            episodeErrorMessage = AppStrings.newEpisodeLoadError
        }
    }

    func selectEpisode(id: String?) {
        guard let id else {
            draft.clearEpisode()
            return
        }
        guard let episode = episodes.first(where: { $0.id == id }) else { return }
        draft.selectEpisode(episode, schema: sourceSchema)
    }

    func createEpisode(_ request: EpisodeCreateRequest) async throws -> EpisodeSummary {
        guard let sourceID = draft.selectedSourceID else {
            throw SourceRepositoryError.sourceNotFound
        }
        let episode = try await sourceRepository.createEpisode(sourceID: sourceID, request: request)
        guard draft.selectedSourceID == sourceID else { return episode }
        episodes.removeAll { $0.id == episode.id }
        episodes.insert(episode, at: 0)
        draft.selectEpisode(episode, schema: sourceSchema)
        episodeErrorMessage = nil
        return episode
    }

    func value(for key: String) -> String {
        draft.contextValue(for: key)
    }

    func updateValue(for field: MomentLocationField, value: String) {
        guard let schemaField = sourceSchema.momentLocationFields.first(
            where: { $0.key == field.key }
        ) else { return }
        draft.updateContextValue(
            key: field.key,
            value: LocatorValuePolicy.normalized(value, for: schemaField)
        )
    }

    func timestampComponents(for key: String) -> (Int, Int, Int) {
        let values = draft.contextValue(for: key).split(separator: ":").compactMap { Int($0) }
        if values.count == 3 { return (values[0], values[1], values[2]) }
        if values.count == 2 { return (0, values[0], values[1]) }
        return (0, 0, 0)
    }

    func updateTimestamp(key: String, hour: Int, minute: Int, second: Int) {
        draft.updateContextValue(
            key: key,
            value: String(
                format: "%02d:%02d:%02d",
                min(max(hour, 0), 99),
                min(max(minute, 0), 59),
                min(max(second, 0), 59)
            )
        )
    }

    func beginReactionEditing() {
        reactionSelectionIDs = Set(draft.selectedReactions.map(\.id))
    }

    func toggleReaction(_ reaction: NewMomentDraft.SelectedReaction) {
        if reactionSelectionIDs.contains(reaction.id) {
            reactionSelectionIDs.remove(reaction.id)
        } else {
            reactionSelectionIDs.insert(reaction.id)
        }
    }

    func cancelReactionEditing() {
        reactionSelectionIDs = Set(draft.selectedReactions.map(\.id))
    }

    func commitReactionEditing() {
        let selected = ReactionCatalog.allReactions.filter {
            reactionSelectionIDs.contains($0.id)
        }
        draft.updateSelectedReactions(selected)
    }

    private func configureContextForCurrentSource() {
        draft.configureContext(using: sourceSchema)
    }

    private func applyInitialContextIfNeeded() async {
        guard !didApplyInitialContext else { return }
        didApplyInitialContext = true

        if let initialPairID,
           pairOptions.contains(where: { $0.id == initialPairID }) {
            selectPair(id: initialPairID)
        }

        guard let initialSourceID,
              sourceOptions.contains(where: { $0.id == initialSourceID }) else {
            return
        }
        selectSource(id: initialSourceID)
        isSourceDetailExpanded = true
        await loadEpisodes()
        if let initialEpisodeID,
           episodes.contains(where: { $0.id == initialEpisodeID }) {
            selectEpisode(id: initialEpisodeID)
        }
    }
}
