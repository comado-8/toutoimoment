import Foundation
import Combine

@MainActor
final class ManualBackupSettingsViewModel: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var isInspecting = false
    @Published private(set) var isRestoring = false
    @Published private(set) var lastExportAt: Date?
    @Published private(set) var lastRestoreAt: Date?
    @Published private(set) var pendingPreview: ManualBackupPreview?
    @Published var errorMessage: String?

    private let service: any BackupServicing
    private let metadataStore: any ManualBackupMetadataStoring
    private var pendingURL: URL?
    private var pendingPassphrase: String?

    init(
        service: any BackupServicing,
        metadataStore: any ManualBackupMetadataStoring = UserDefaultsManualBackupMetadataStore()
    ) {
        self.service = service
        self.metadataStore = metadataStore
        lastExportAt = metadataStore.lastExportAt
        lastRestoreAt = metadataStore.lastRestoreAt
    }

    func export(passphrase: String, confirmation: String) async -> URL? {
        guard passphrase.count >= ManualBackupPassphrasePolicy.minimumLength else {
            errorMessage = ManualBackupError.invalidPassphrase.localizedDescription
            return nil
        }
        guard passphrase == confirmation else {
            errorMessage = AppStrings.backupPassphraseMismatch
            return nil
        }
        isExporting = true
        defer { isExporting = false }
        do {
            let url = try await service.exportEncryptedBackup(passphrase: passphrase)
            lastExportAt = metadataStore.lastExportAt
            errorMessage = nil
            return url
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func inspect(url: URL, passphrase: String) async -> Bool {
        clearPending()
        guard passphrase.count >= ManualBackupPassphrasePolicy.minimumLength else {
            errorMessage = ManualBackupError.invalidPassphrase.localizedDescription
            return false
        }
        isInspecting = true
        defer { isInspecting = false }
        do {
            pendingPreview = try await service.inspectEncryptedBackup(
                at: url,
                passphrase: passphrase
            )
            pendingURL = url
            pendingPassphrase = passphrase
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restorePending() async -> ManualRestoreResult? {
        guard let pendingURL, let pendingPassphrase else {
            errorMessage = AppStrings.backupNotSelected
            return nil
        }
        isRestoring = true
        defer { isRestoring = false }
        do {
            let result = try await service.restoreEncryptedBackup(
                at: pendingURL,
                passphrase: pendingPassphrase
            )
            lastRestoreAt = metadataStore.lastRestoreAt
            errorMessage = nil
            clearPending()
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func clearPending() {
        pendingPreview = nil
        pendingURL = nil
        pendingPassphrase = nil
    }
}
