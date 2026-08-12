import Foundation

enum AppServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        AppStrings.serviceUnavailable
    }
}

@MainActor
protocol PurchaseServicing {
    var isPremium: Bool { get }
    var localizedOneTimePrice: String? { get }
    func purchase() async throws
    func restore() async throws
}

@MainActor
protocol CloudSyncServicing {
    func syncNow() async throws -> Date
}

@MainActor
protocol BackupServicing {
    func exportEncryptedBackup(passphrase: String) async throws -> URL
    func inspectEncryptedBackup(at url: URL, passphrase: String) async throws -> ManualBackupPreview
    func restoreEncryptedBackup(at url: URL, passphrase: String) async throws -> ManualRestoreResult
}

struct SupportLinks {
    var privacyPolicy: URL? = nil
    var termsOfService: URL? = nil
    var officialWebsite: URL? = nil
    var faq: URL? = nil
    var contact: URL? = nil
    var featureRequest: URL? = nil
    var reportBug: URL? = nil

    static let unconfigured = SupportLinks()
}
