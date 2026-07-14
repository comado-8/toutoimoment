import Foundation

struct NewMomentDraft: Hashable {
    struct ContextValue: Hashable, Identifiable {
        let key: String
        var value: String

        var id: String { key }
    }

    struct SelectedPair: Hashable {
        let id: String
        let displayName: String
        let nickname: String
    }

    struct SelectedSource: Hashable {
        let id: String
        let displayName: String
        let helperText: String
        let mediaType: String
        let totalCount: Int?
        let isFavorite: Bool
    }

    struct SelectedReaction: Hashable, Identifiable {
        let id: String
        let section: String
        let emoji: String
        let label: String

        var displayText: String {
            "\(emoji) \(label)"
        }
    }

    var selectedPair: SelectedPair?
    var selectedSource: SelectedSource?
    var contextValues: [ContextValue]
    var sceneSummary: String
    var heartScream: String
    var selectedReactions: [SelectedReaction]
    private var contextMediaType: String?

    nonisolated init(
        selectedPair: SelectedPair? = nil,
        selectedSource: SelectedSource? = nil,
        contextValues: [ContextValue] = [],
        sceneSummary: String = "",
        heartScream: String = "",
        selectedReactions: [SelectedReaction] = [],
        contextMediaType: String? = nil
    ) {
        self.selectedPair = selectedPair
        self.selectedSource = selectedSource
        self.contextValues = contextValues
        self.sceneSummary = sceneSummary
        self.heartScream = heartScream
        self.selectedReactions = selectedReactions
        self.contextMediaType = contextMediaType
    }

    var selectedPairID: String? {
        selectedPair?.id
    }

    var selectedPairDisplayName: String? {
        selectedPair?.displayName
    }

    var selectedSourceID: String? {
        selectedSource?.id
    }

    var selectedSourceDisplayName: String? {
        selectedSource?.displayName
    }

    var selectedSourceHelperText: String? {
        selectedSource?.helperText
    }

    var hasMomentBody: Bool {
        !sceneSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !heartScream.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    mutating func selectPair(id: String, displayName: String, nickname: String) {
        selectedPair = SelectedPair(
            id: id,
            displayName: displayName,
            nickname: nickname
        )
    }

    mutating func clearPair() {
        selectedPair = nil
    }

    mutating func selectSource(
        id: String,
        displayName: String,
        helperText: String,
        mediaType: String,
        totalCount: Int?,
        isFavorite: Bool
    ) {
        if selectedSource?.id != id {
            contextValues = []
            contextMediaType = nil
        }

        selectedSource = SelectedSource(
            id: id,
            displayName: displayName,
            helperText: helperText,
            mediaType: mediaType,
            totalCount: totalCount,
            isFavorite: isFavorite
        )
    }

    mutating func clearSource() {
        selectedSource = nil
        contextValues = []
        contextMediaType = nil
    }

    mutating func configureContext(using schema: SourceLocatorSchema) {
        let existingValues = contextMediaType == schema.mediaType
            ? Dictionary(uniqueKeysWithValues: contextValues.map { ($0.key, $0.value) })
            : [:]
        let fields = schema.contextFieldRows.flatMap { $0 }
        contextValues = fields.map { field in
            ContextValue(key: field.key, value: existingValues[field.key] ?? "")
        }
        contextMediaType = schema.mediaType
    }

    func contextValue(for key: String) -> String {
        contextValues.first(where: { $0.key == key })?.value ?? ""
    }

    mutating func updateContextValue(key: String, value: String) {
        guard let index = contextValues.firstIndex(where: { $0.key == key }) else {
            return
        }

        contextValues[index].value = value
    }

    mutating func updateSceneSummary(_ value: String) {
        sceneSummary = value
    }

    mutating func updateHeartScream(_ value: String) {
        heartScream = value
    }

    mutating func updateSelectedReactions(_ reactions: [SelectedReaction]) {
        selectedReactions = reactions
    }
}
