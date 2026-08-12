import Foundation

enum MomentEditDraftMapper {
    static func draft(from moment: MomentCardModel) -> NewMomentDraft {
        NewMomentDraft(
            selectedPair: moment.pairID.map { pairID in
                .init(
                    id: pairID,
                    displayName: moment.pairName,
                    nickname: moment.pairName,
                    member1Name: moment.pairMemberNames.first ?? moment.pairName,
                    member2Name: moment.pairMemberNames.dropFirst().first
                )
            },
            selectedSource: moment.sourceID.map { sourceID in
                .init(
                    id: sourceID,
                    displayName: moment.sourceName,
                    helperText: "",
                    mediaType: moment.mediaType ?? SourceLocatorSchema.fallbackMediaType
                )
            },
            selectedEpisode: moment.episodeID.map { episodeID in
                .init(
                    id: episodeID,
                    sourceID: moment.sourceID ?? "",
                    locatorValues: moment.episodeLocatorValues,
                    displayName: (
                        SourceLocatorSchema.schema(
                            for: moment.mediaType ?? SourceLocatorSchema.fallbackMediaType
                        ) ?? .fallback
                    ).episodeDisplayName(for: moment.episodeLocatorValues)
                )
            },
            contextValues: moment.contextValues.map {
                .init(key: $0.key, value: $0.value)
            },
            momentTitle: moment.title ?? "",
            sceneSummary: moment.sceneText,
            heartScream: moment.heartText,
            selectedReactions: reactions(from: moment),
            momentDate: moment.momentDate,
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
    let episodeID: String?
    let mediaType: String?
    let contextValues: [NewMomentDraft.ContextValue]
    let momentTitle: String
    let sceneSummary: String
    let heartScream: String
    let reactionIDs: [String]
    let momentDate: MomentDate

    init(draft: NewMomentDraft) {
        pairID = draft.selectedPairID
        sourceID = draft.selectedSourceID
        episodeID = draft.selectedEpisodeID
        mediaType = draft.selectedSource?.mediaType
        contextValues = draft.contextValues
        momentTitle = draft.momentTitle
        sceneSummary = draft.sceneSummary
        heartScream = draft.heartScream
        reactionIDs = draft.selectedReactions.map(\.id)
        momentDate = draft.momentDate
    }
}
