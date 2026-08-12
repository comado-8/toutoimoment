import Foundation

@MainActor
struct LocalPurchaseService: PurchaseServicing {
    let isPremium = false
    let localizedOneTimePrice: String? = nil
    func purchase() async throws { throw AppServiceError.unavailable }
    func restore() async throws { throw AppServiceError.unavailable }
}

@MainActor
struct LocalCloudSyncService: CloudSyncServicing {
    func syncNow() async throws -> Date { throw AppServiceError.unavailable }
}

@MainActor
struct LocalBackupService: BackupServicing {
    func exportEncryptedBackup(passphrase: String) async throws -> URL {
        throw AppServiceError.unavailable
    }

    func inspectEncryptedBackup(at url: URL, passphrase: String) async throws -> ManualBackupPreview {
        throw AppServiceError.unavailable
    }

    func restoreEncryptedBackup(at url: URL, passphrase: String) async throws -> ManualRestoreResult {
        throw AppServiceError.unavailable
    }
}
