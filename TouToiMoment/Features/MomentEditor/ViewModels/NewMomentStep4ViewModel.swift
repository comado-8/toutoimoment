import Combine
import Foundation

@MainActor
final class NewMomentStep4ViewModel: ObservableObject {
    @Published private(set) var draft: NewMomentDraft
    @Published private(set) var pickerSelectionIDs: Set<String>

    init(draft: NewMomentDraft) {
        self.draft = draft
        self.pickerSelectionIDs = Set(draft.selectedReactions.map(\.id))
    }

    var chooseSummary: String {
        let pairName = draft.selectedPairDisplayName ?? AppStrings.newMomentStep2NoPair
        let sourceName = draft.selectedSourceDisplayName ?? AppStrings.newMomentStep2NoSource
        return "\(pairName) · \(sourceName)"
    }

    var contextSummary: String {
        NewMomentContextSummaryFormatter.summary(for: draft)
    }

    var captureSummary: String {
        let summary = draft.sceneSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let scream = draft.heartScream.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (summary.isEmpty, scream.isEmpty) {
        case (false, false):
            return "\(summary) · \(scream)"
        case (false, true):
            return summary
        case (true, false):
            return scream
        case (true, true):
            return AppStrings.newMomentStepCompletedSummary("")
        }
    }

    var selectedReactions: [NewMomentDraft.SelectedReaction] {
        draft.selectedReactions
    }

    var canSave: Bool {
        draft.hasMomentBody
    }

    func beginReactionEditing() {
        pickerSelectionIDs = Set(draft.selectedReactions.map(\.id))
    }

    func toggleReaction(_ reaction: NewMomentDraft.SelectedReaction) {
        if pickerSelectionIDs.contains(reaction.id) {
            pickerSelectionIDs.remove(reaction.id)
        } else {
            pickerSelectionIDs.insert(reaction.id)
        }
    }

    func isReactionSelected(_ reaction: NewMomentDraft.SelectedReaction) -> Bool {
        pickerSelectionIDs.contains(reaction.id)
    }

    func cancelReactionEditing() {
        pickerSelectionIDs = Set(draft.selectedReactions.map(\.id))
    }

    func commitReactionEditing() {
        let selected = ReactionCatalog.allReactions.filter { pickerSelectionIDs.contains($0.id) }
        draft.updateSelectedReactions(selected)
    }
}
