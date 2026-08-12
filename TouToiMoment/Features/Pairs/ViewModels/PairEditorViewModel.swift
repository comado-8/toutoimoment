import Combine
import Foundation

@MainActor
final class PairEditorViewModel: ObservableObject {
    typealias SaveAction = @MainActor (PairEditorDraft) async throws -> PairSummary

    enum SaveState: Equatable {
        case idle
        case saving
        case failed
    }

    @Published var draft: PairEditorDraft
    @Published private(set) var saveState: SaveState = .idle

    private let initialDraft: PairEditorDraft
    private let saveAction: SaveAction

    init(saveAction: @escaping SaveAction) {
        self.draft = PairEditorDraft()
        self.initialDraft = PairEditorDraft()
        self.saveAction = saveAction
    }

    init(draft: PairEditorDraft, saveAction: @escaping SaveAction) {
        self.draft = draft
        self.initialDraft = draft
        self.saveAction = saveAction
    }

    var canSave: Bool {
        draft.isValid && draft != initialDraft && saveState != .saving
    }

    var isSaving: Bool { saveState == .saving }

    var errorMessage: String? {
        saveState == .failed ? AppStrings.pairEditorSaveError : nil
    }

    func save() async -> PairSummary? {
        guard canSave else { return nil }
        saveState = .saving
        do {
            let pair = try await saveAction(draft)
            saveState = .idle
            return pair
        } catch {
            saveState = .failed
            return nil
        }
    }
}
