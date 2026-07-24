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
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var reactionSelectionIDs: Set<String>
    @Published private(set) var imageItems: [MomentImageEditItem]

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
        draft.selectedPairID != nil && draft.hasMomentBody && hasChanges
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

    var contextFields: [NewMomentStep2ContextField] {
        let mediaType = draft.selectedSource?.mediaType ?? SourceLocatorSchema.fallbackMediaType
        let schema = SourceLocatorSchema.schema(for: mediaType) ?? SourceLocatorSchema.fallback
        return schema.contextFieldRows.flatMap { row in
            row.map {
                NewMomentStep2ContextField(
                    key: $0.key,
                    label: $0.label,
                    placeholder: $0.placeholder,
                    inputKind: $0.inputKind,
                    unit: $0.unit
                )
            }
        }
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
                        subtitle: $0.nickname,
                        helperText: AppStrings.newMomentStep1MomentCount(count: $0.momentCount),
                        leadingColorHex: $0.leadingColorHex,
                        trailingColorHex: $0.trailingColorHex
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

    func selectPair(id: String) {
        guard let option = pairOptions.first(where: { $0.id == id }) else { return }
        draft.selectPair(
            id: option.id,
            displayName: option.title,
            nickname: option.subtitle ?? option.title,
            leadingColorHex: option.leadingColorHex,
            trailingColorHex: option.trailingColorHex
        )
    }

    func selectSource(id: String?) {
        guard let id else {
            draft.clearSource()
            return
        }
        guard let option = sourceOptions.first(where: { $0.id == id }) else { return }
        draft.selectSource(
            id: option.id,
            displayName: option.title,
            helperText: option.subtitle ?? "",
            mediaType: option.sourceMediaType ?? SourceLocatorSchema.fallbackMediaType,
            totalCount: option.sourceTotalCount,
            isFavorite: option.sourceIsFavorite ?? false
        )
        configureContextForCurrentSource()
    }

    func createPair(
        member1: String,
        member2: String,
        displayName: String,
        leadingColorHex: String = "#46C1B1",
        trailingColorHex: String = "#F26767"
    ) {
        let first = member1.trimmingCharacters(in: .whitespacesAndNewlines)
        let second = member2.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty, !second.isEmpty else { return }
        let customName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = customName.isEmpty
            ? PairDisplayNameFormatter.joined(first, second)
            : PairDisplayNameFormatter.normalized(customName)
        let option = NewMomentSelectableOption(
            id: UUID().uuidString,
            title: title,
            subtitle: title,
            helperText: AppStrings.newMomentStep1MomentCount(count: 0),
            leadingColorHex: leadingColorHex,
            trailingColorHex: trailingColorHex
        )
        pairOptions.insert(option, at: 0)
        selectPair(id: option.id)
    }

    func createSource(displayName: String, mediaType: String) async -> Bool {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        do {
            let source = try await sourceRepository.createSource(
                displayName: name,
                helperText: SourceLocatorSchema.schema(for: mediaType)?.mediaLabelJa ?? mediaType,
                mediaType: mediaType,
                totalCount: nil,
                isFavorite: false
            )
            let option = NewMomentSelectableOption(source: source)
            sourceOptions.insert(option, at: 0)
            selectSource(id: option.id)
            errorMessage = nil
            return true
        } catch {
            errorMessage = AppStrings.momentEditLoadError
            return false
        }
    }

    func value(for key: String) -> String {
        draft.contextValue(for: key)
    }

    func updateContextValue(field: NewMomentStep2ContextField, value: String) {
        draft.updateContextValue(
            key: field.key,
            value: field.inputKind == .number ? Self.digitsOnly(value) : value
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
        let mediaType = draft.selectedSource?.mediaType ?? SourceLocatorSchema.fallbackMediaType
        let schema = SourceLocatorSchema.schema(for: mediaType) ?? SourceLocatorSchema.fallback
        draft.configureContext(using: schema)
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
            trailingColorHex: pair.trailingColorHex
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
            sourceMediaType: source.mediaType,
            sourceTotalCount: source.totalCount,
            sourceIsFavorite: source.isFavorite
        )
    }

    private static func digitsOnly(_ value: String) -> String {
        value.unicodeScalars.compactMap { scalar -> String? in
            switch scalar.value {
            case 0x30...0x39:
                return String(Character(String(scalar)))
            case 0xFF10...0xFF19:
                return UnicodeScalar(scalar.value - 0xFF10 + 0x30).map { String(Character(String($0))) }
            default:
                return nil
            }
        }.joined()
    }
}
