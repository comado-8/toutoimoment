import Combine
import Foundation

@MainActor
final class NewSourceSheetViewModel: ObservableObject {
    typealias SaveAction = @MainActor (SourceCreateRequest) async throws -> SourceSummary

    enum SaveState: Equatable {
        case idle
        case saving
        case failed
    }

    @Published var draft = NewSourceDraft()
    @Published private(set) var saveState: SaveState = .idle

    private let saveAction: SaveAction

    convenience init(saveAction: @escaping SaveAction) {
        self.init(draft: NewSourceDraft(), saveAction: saveAction)
    }

    init(draft: NewSourceDraft, saveAction: @escaping SaveAction) {
        self.draft = draft
        self.saveAction = saveAction
    }

    var canSave: Bool {
        draft.isValid && saveState != .saving
    }

    var isSaving: Bool {
        saveState == .saving
    }

    var errorMessage: String? {
        saveState == .failed ? AppStrings.newSourceSaveError : nil
    }

    func save() async -> SourceSummary? {
        guard
            saveState != .saving,
            let request = draft.makeRequest()
        else {
            return nil
        }

        saveState = .saving

        do {
            let source = try await saveAction(request)
            saveState = .idle
            return source
        } catch {
            saveState = .failed
            return nil
        }
    }
}
