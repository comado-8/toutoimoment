import Combine
import SwiftUI

@MainActor
final class NewMomentStep1ViewModel: ObservableObject {
    @Published private(set) var draft: NewMomentDraft
    @Published private(set) var pairOptions: [NewMomentSelectableOption] = []
    @Published private(set) var sourceOptions: [NewMomentSelectableOption] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let pairRepository: any PairRepository
    private let sourceRepository: any SourceRepository

    init(
        draft: NewMomentDraft = NewMomentDraft(),
        pairRepository: any PairRepository,
        sourceRepository: any SourceRepository
    ) {
        self.draft = draft
        self.pairRepository = pairRepository
        self.sourceRepository = sourceRepository
    }

    var pairFieldValue: String {
        draft.selectedPairDisplayName ?? AppStrings.newMomentStep1PairPlaceholder
    }

    var sourceFieldValue: String {
        draft.selectedSourceDisplayName ?? AppStrings.newMomentStep1SourcePlaceholder
    }

    var pairDropdownOptions: [NewMomentSelectableOption] { pairOptions }

    func loadIfNeeded() async {
        guard pairOptions.isEmpty, sourceOptions.isEmpty, !isLoading else {
            return
        }

        await loadOptions()
    }

    func retry() async {
        await loadOptions()
    }

    func selectPair(id: String) {
        guard let option = pairOptions.first(where: { $0.id == id }) else {
            return
        }

        draft.selectPair(
            id: option.id,
            displayName: option.title,
            nickname: option.subtitle ?? ""
        )
    }

    func selectSource(id: String) {
        guard let option = sourceOptions.first(where: { $0.id == id }) else {
            return
        }

        draft.selectSource(
            id: option.id,
            displayName: option.title,
            helperText: option.subtitle ?? option.helperText ?? "",
            mediaType: option.sourceMediaType ?? "",
            totalCount: option.sourceTotalCount,
            isFavorite: option.sourceIsFavorite ?? false
        )
    }

    func createPair(
        displayName: String,
        nickname: String,
        leadingColorHex: String,
        trailingColorHex: String?
    ) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        let resolvedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let option = NewMomentSelectableOption(
            id: UUID().uuidString,
            title: trimmedName,
            subtitle: resolvedNickname.isEmpty ? trimmedName : resolvedNickname,
            helperText: AppStrings.newMomentStep1MomentCount(count: 0),
            leadingColorHex: leadingColorHex,
            trailingColorHex: trailingColorHex
        )

        pairOptions.insert(option, at: 0)
        draft.selectPair(
            id: option.id,
            displayName: option.title,
            nickname: option.subtitle ?? option.title
        )
    }

    func createSource(
        displayName: String,
        helperText: String,
        mediaType: String,
        totalCount: Int?,
        isFavorite: Bool
    ) async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        do {
            let source = try await sourceRepository.createSource(
                displayName: trimmedName,
                helperText: helperText,
                mediaType: mediaType,
                totalCount: totalCount,
                isFavorite: isFavorite
            )

            let option = NewMomentSelectableOption(source: source)
            sourceOptions.insert(option, at: 0)
            selectSource(id: option.id)
        } catch {
            errorMessage = AppStrings.newMomentStep1LoadError
        }
    }

    private func loadOptions() async {
        isLoading = true
        errorMessage = nil

        do {
            async let pairsTask = pairRepository.fetchPairs()
            async let sourcesTask = sourceRepository.fetchSources()

            let (pairs, sources) = try await (pairsTask, sourcesTask)
            pairOptions = pairs.map {
                NewMomentSelectableOption(
                    id: $0.id,
                    title: $0.displayName,
                    subtitle: $0.nickname,
                    helperText: AppStrings.newMomentStep1MomentCount(count: $0.momentCount),
                    leadingColorHex: $0.leadingColorHex,
                    trailingColorHex: $0.trailingColorHex
                )
            }
            sourceOptions = sources.map {
                NewMomentSelectableOption(source: $0)
            }
        } catch {
            errorMessage = AppStrings.newMomentStep1LoadError
        }

        isLoading = false
    }
}

struct NewMomentSelectableOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let helperText: String?
    let leadingColorHex: String?
    let trailingColorHex: String?
    let sourceMediaType: String?
    let sourceTotalCount: Int?
    let sourceIsFavorite: Bool?

    init(
        id: String,
        title: String,
        subtitle: String?,
        helperText: String?,
        leadingColorHex: String?,
        trailingColorHex: String?,
        sourceMediaType: String? = nil,
        sourceTotalCount: Int? = nil,
        sourceIsFavorite: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.helperText = helperText
        self.leadingColorHex = leadingColorHex
        self.trailingColorHex = trailingColorHex
        self.sourceMediaType = sourceMediaType
        self.sourceTotalCount = sourceTotalCount
        self.sourceIsFavorite = sourceIsFavorite
    }

    init(source: SourceSummary) {
        self.init(
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
}
