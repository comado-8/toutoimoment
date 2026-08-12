import Combine
import Foundation

@MainActor
final class NewEpisodeSheetViewModel: ObservableObject {
    typealias SaveAction = @MainActor (EpisodeCreateRequest) async throws -> EpisodeSummary

    enum SaveState: Equatable {
        case idle
        case saving
        case failed
    }

    @Published var draft: NewEpisodeDraft
    @Published private(set) var saveState: SaveState = .idle

    private let saveAction: SaveAction

    init(
        schema: SourceLocatorSchema,
        episode: EpisodeSummary? = nil,
        saveAction: @escaping SaveAction
    ) {
        self.draft = episode.map { NewEpisodeDraft(schema: schema, episode: $0) }
            ?? NewEpisodeDraft(schema: schema)
        self.saveAction = saveAction
    }

    var canSave: Bool {
        draft.isValid && saveState != .saving
    }

    var isSaving: Bool {
        saveState == .saving
    }

    var errorMessage: String? {
        saveState == .failed ? AppStrings.newEpisodeSaveError : nil
    }

    func updateValue(_ value: String, for field: LocatorField) {
        draft.updateValue(value, for: field)
    }

    func save() async -> EpisodeSummary? {
        guard canSave, let request = draft.request else { return nil }
        saveState = .saving

        do {
            let episode = try await saveAction(request)
            saveState = .idle
            return episode
        } catch {
            saveState = .failed
            return nil
        }
    }
}
