import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: AppSettings
    @Published private(set) var loadError: Error?
    @Published private(set) var isLoaded = false
    private let repository: any SettingsRepository

    init(repository: any SettingsRepository) {
        self.repository = repository
        do {
            settings = try repository.loadSettings()
            isLoaded = true
        } catch {
            settings = .initial()
            loadError = error
        }
    }

    func setKeepScreenAwake(_ value: Bool) { update { $0.keepScreenAwake = value } }
    func setHapticFeedbackEnabled(_ value: Bool) { update { $0.hapticFeedbackEnabled = value } }
    func setCloudSyncEnabled(_ value: Bool) { update { $0.cloudSyncEnabled = value } }
    func markSynced(at date: Date = .now) { update { $0.lastSyncedAt = date } }

    func reloadFromPersistence() throws {
        settings = try repository.loadSettings()
        loadError = nil
        isLoaded = true
    }

    private func update(_ change: (inout AppSettings) -> Void) {
        guard isLoaded else { return }
        var updated = settings
        change(&updated)
        updated.updatedAt = .now
        do {
            try repository.saveSettings(updated)
            settings = updated
        } catch {
            assertionFailure("Unable to persist app settings: \(error)")
        }
    }
}
