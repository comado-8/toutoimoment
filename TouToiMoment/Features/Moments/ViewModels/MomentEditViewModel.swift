import Combine
import Foundation

struct MomentImageEditItem: Identifiable {
    let id: String
    let existingImage: MomentImage?
    let pendingData: Data?
    let createdAt: Date

    init(existingImage: MomentImage) {
        id = existingImage.id
        self.existingImage = existingImage
        pendingData = nil
        createdAt = existingImage.createdAt
    }

    init(id: String = UUID().uuidString, data: Data, createdAt: Date = Date()) {
        self.id = id
        existingImage = nil
        pendingData = data
        self.createdAt = createdAt
    }
}

@MainActor
final class MomentEditViewModel: ObservableObject {
    @Published private(set) var draft: NewMomentDraft
    @Published private(set) var pairOptions: [NewMomentSelectableOption]
    @Published private(set) var sourceOptions: [NewMomentSelectableOption]
    @Published private(set) var episodes: [EpisodeSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var reactionSelectionIDs: Set<String>
    @Published private(set) var imageItems: [MomentImageEditItem]
    @Published private(set) var episodeErrorMessage: String?

    let momentID: String

    private let pairRepository: any PairRepository
    private let sourceRepository: any SourceRepository
    private let originalSnapshot: MomentEditableSnapshot
    private let originalImageIDs: [String]

    init(
        moment: MomentCardModel,
        pairRepository: any PairRepository,
        sourceRepository: any SourceRepository
    ) {
        let draft = MomentEditDraftMapper.draft(from: moment)
        self.momentID = moment.id
        self.draft = draft
        self.originalSnapshot = MomentEditableSnapshot(draft: draft)
        self.pairRepository = pairRepository
        self.sourceRepository = sourceRepository
        self.reactionSelectionIDs = Set(draft.selectedReactions.map(\.id))
        self.imageItems = moment.images
            .sorted { $0.order < $1.order }
            .map(MomentImageEditItem.init(existingImage:))
        self.originalImageIDs = moment.images
            .sorted { $0.order < $1.order }
            .map(\.id)
        self.pairOptions = Self.fallbackPairOption(from: draft).map { [$0] } ?? []
        self.sourceOptions = Self.fallbackSourceOption(from: draft).map { [$0] } ?? []
    }

    var hasChanges: Bool {
        MomentEditableSnapshot(draft: draft) != originalSnapshot || hasImageChanges
    }

    var canSave: Bool {
        draft.hasRequiredHeartScream
            && draft.isWithinTextLimits
            && hasValidMomentLocation
            && hasChanges
    }

    var hasImageChanges: Bool {
        imageItems.map(\.id) != originalImageIDs
            || imageItems.contains(where: { $0.pendingData != nil })
    }

    var imageChangeSet: MomentImageChangeSet {
        MomentImageChangeSet(
            retainedImageIDs: imageItems.compactMap { $0.existingImage?.id },
            additions: imageItems.compactMap { item in
                guard let data = item.pendingData else { return nil }
                return MomentImageChangeSet.Addition(
                    id: item.id,
                    data: data,
                    createdAt: item.createdAt
                )
            }
        )
    }

    var sourceSchema: SourceLocatorSchema {
        let mediaType = draft.selectedSource?.mediaType ?? SourceLocatorSchema.fallbackMediaType
        return SourceLocatorSchema.schema(for: mediaType) ?? .fallback
    }

    var contextFields: [MomentLocationField] {
        sourceSchema.momentLocationFields.map(MomentLocationField.init)
    }

    var hasValidMomentLocation: Bool {
        sourceSchema.momentLocationFields.allSatisfy { field in
            LocatorValuePolicy.isValid(draft.contextValue(for: field.key), for: field)
        }
    }

    func updateMomentDate(_ value: Date) {
        draft.updateMomentDate(value)
    }

    func loadOptionsIfNeeded() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let pairResult = pairRepository.fetchPairs()
            async let sourceResult = sourceRepository.fetchSources()
            let (pairs, sources) = try await (pairResult, sourceResult)

            pairOptions = mergeCurrentOption(
                Self.fallbackPairOption(from: draft),
                into: pairs.map {
                    NewMomentSelectableOption(
                        id: $0.id,
                        title: PairDisplayNameFormatter.normalized($0.displayName),
                        subtitle: $0.subtitle,
                        helperText: AppStrings.newMomentStep1MomentCount(count: $0.momentCount),
                        leadingColorHex: $0.leadingColorHex,
                        trailingColorHex: $0.trailingColorHex,
                        pairMember1Name: $0.member1Name,
                        pairMember2Name: $0.member2Name
                    )
                }
            )
            sourceOptions = mergeCurrentOption(
                Self.fallbackSourceOption(from: draft),
                into: sources.map(NewMomentSelectableOption.init(source:))
            )
            errorMessage = nil
        } catch {
            errorMessage = AppStrings.momentEditLoadError
        }
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

    func selectSource(id: String?) {
        guard let id else {
            draft.clearSource()
            episodes = []
            return
        }
        guard let option = sourceOptions.first(where: { $0.id == id }) else { return }
        let isSameSource = draft.selectedSourceID == id
        draft.selectSource(
            id: option.id,
            displayName: option.title,
            helperText: option.subtitle ?? "",
            mediaType: option.sourceMediaType ?? SourceLocatorSchema.fallbackMediaType
        )
        if !isSameSource {
            episodes = []
            configureContextForCurrentSource()
        }
    }

    func createPair(
        member1: String,
        member2: String,
        displayName: String,
        leadingColorHex: String = "#46C1B1",
        trailingColorHex: String = "#F26767"
    ) async throws {
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
                leadingColorHex: leadingColorHex,
                trailingColorHex: second.isEmpty ? nil : trailingColorHex
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
            episodes = []
            episodeErrorMessage = nil
            return
        }
        do {
            episodes = try await sourceRepository.fetchSourceDetail(id: sourceID)?.episodes ?? []
            episodeErrorMessage = nil
        } catch {
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
        let episode = try await sourceRepository.createEpisode(
            sourceID: sourceID,
            request: request
        )
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

    func updateContextValue(field: MomentLocationField, value: String) {
        guard let schemaField = sourceSchema.momentLocationFields.first(
            where: { $0.key == field.key }
        ) else { return }
        draft.updateContextValue(
            key: field.key,
            value: LocatorValuePolicy.normalized(value, for: schemaField)
        )
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

    func timestampComponents(for key: String) -> (Int, Int, Int) {
        let values = draft.contextValue(for: key).split(separator: ":").compactMap { Int($0) }
        if values.count == 3 { return (values[0], values[1], values[2]) }
        if values.count == 2 { return (0, values[0], values[1]) }
        return (0, 0, 0)
    }

    func updateScene(_ value: String) {
        draft.updateSceneSummary(value)
    }

    func updateMomentTitle(_ value: String) {
        draft.updateMomentTitle(value)
    }

    func updateHeart(_ value: String) {
        draft.updateHeartScream(value)
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
        let legacy = draft.selectedReactions.filter {
            ReactionCatalog.reaction(withID: $0.id) == nil && reactionSelectionIDs.contains($0.id)
        }
        let catalog = ReactionCatalog.allReactions.filter { reactionSelectionIDs.contains($0.id) }
        draft.updateSelectedReactions(catalog + legacy)
    }

    @discardableResult
    func addImage(data: Data) -> Bool {
        guard
            !data.isEmpty,
            imageItems.count < LocalMomentImageRepository.maximumImageCount
        else {
            return false
        }
        imageItems.append(MomentImageEditItem(data: data))
        return true
    }

    func removeImage(id: String) {
        imageItems.removeAll { $0.id == id }
    }

    func showSaveError() {
        errorMessage = AppStrings.momentEditSaveError
    }

    private func configureContextForCurrentSource() {
        draft.configureContext(using: sourceSchema)
    }

    private func mergeCurrentOption(
        _ current: NewMomentSelectableOption?,
        into options: [NewMomentSelectableOption]
    ) -> [NewMomentSelectableOption] {
        guard let current, !options.contains(where: { $0.id == current.id }) else {
            return options
        }
        return [current] + options
    }

    private static func fallbackPairOption(from draft: NewMomentDraft) -> NewMomentSelectableOption? {
        guard let pair = draft.selectedPair else { return nil }
        return NewMomentSelectableOption(
            id: pair.id,
            title: pair.displayName,
            subtitle: pair.nickname,
            helperText: nil,
            leadingColorHex: pair.leadingColorHex,
            trailingColorHex: pair.trailingColorHex,
            pairMember1Name: pair.member1Name,
            pairMember2Name: pair.member2Name
        )
    }

    private static func fallbackSourceOption(from draft: NewMomentDraft) -> NewMomentSelectableOption? {
        guard let source = draft.selectedSource else { return nil }
        return NewMomentSelectableOption(
            id: source.id,
            title: source.displayName,
            subtitle: source.helperText,
            helperText: nil,
            leadingColorHex: nil,
            trailingColorHex: nil,
            sourceMediaType: source.mediaType
        )
    }

}
