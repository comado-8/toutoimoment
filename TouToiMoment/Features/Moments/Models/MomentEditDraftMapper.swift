import Foundation

enum MomentEditDraftMapper {
    static func draft(from moment: MomentCardModel) -> NewMomentDraft {
        NewMomentDraft(
            selectedPair: moment.pairID.map { pairID in
                .init(
                    id: pairID,
                    displayName: moment.pairName,
                    nickname: moment.pairName
                )
            },
            selectedSource: moment.sourceID.map { sourceID in
                .init(
                    id: sourceID,
                    displayName: moment.sourceName,
                    helperText: "",
                    mediaType: moment.mediaType ?? SourceLocatorSchema.fallbackMediaType,
                    totalCount: nil,
                    isFavorite: false
                )
            },
            contextValues: moment.contextValues.map {
                .init(key: $0.key, value: $0.value)
            },
            sceneSummary: moment.sceneText,
            heartScream: moment.heartText,
            selectedReactions: reactions(from: moment),
            contextMediaType: moment.mediaType
        )
    }

    private static func reactions(
        from moment: MomentCardModel
    ) -> [NewMomentDraft.SelectedReaction] {
        moment.reactionIDs.enumerated().map { index, id in
            if let catalogReaction = ReactionCatalog.reaction(withID: id) {
                return catalogReaction
            }

            let displayText = moment.reactionLabels.indices.contains(index)
                ? moment.reactionLabels[index]
                : id
            let parts = displayText.split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
            let emoji = parts.first.map(String.init) ?? ""
            let label = parts.count > 1 ? String(parts[1]) : displayText
            return .init(id: id, section: "legacy", emoji: emoji, label: label)
        }
    }
}

struct MomentEditableSnapshot: Equatable {
    let pairID: String?
    let sourceID: String?
    let mediaType: String?
    let contextValues: [NewMomentDraft.ContextValue]
    let sceneSummary: String
    let heartScream: String
    let reactionIDs: [String]

    init(draft: NewMomentDraft) {
        pairID = draft.selectedPairID
        sourceID = draft.selectedSourceID
        mediaType = draft.selectedSource?.mediaType
        contextValues = draft.contextValues
        sceneSummary = draft.sceneSummary
        heartScream = draft.heartScream
        reactionIDs = draft.selectedReactions.map(\.id)
    }
}
