import Combine
import Foundation

@MainActor
final class NewMomentStep3ViewModel: ObservableObject {
    @Published private(set) var draft: NewMomentDraft

    init(draft: NewMomentDraft) {
        self.draft = draft
    }

    var chooseSummary: String {
        let pairName = draft.selectedPairDisplayName ?? AppStrings.newMomentStep2NoPair
        let sourceName = draft.selectedSourceDisplayName ?? AppStrings.newMomentStep2NoSource
        return "\(pairName) · \(sourceName)"
    }

    var contextSummary: String {
        NewMomentContextSummaryFormatter.summary(for: draft)
    }

    var canContinue: Bool {
        draft.hasMomentBody
    }

    func updateSceneSummary(_ value: String) {
        draft.updateSceneSummary(value)
    }

    func updateHeartScream(_ value: String) {
        draft.updateHeartScream(value)
    }
}
