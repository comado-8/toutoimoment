import Foundation

enum ManualBackupPassphrasePolicy {
    static let minimumLength = 8
    static let recommendedLength = 12
}

enum ManualBackupImportPolicy {
    static let formatIdentifier = "com.comado-studio.toutoimoment.manual-backup"
    static let fileExtension = "ttmbackup"
    static let currentSchemaVersion = 1
    static let maximumArchiveBytes: Int64 = 1_073_741_824
    static let maximumContentBytes = 64 * 1_024 * 1_024
    static let maximumImageBytes = 25 * 1_024 * 1_024
    static let maximumEntryCount = 30_002
    static let maximumNodeCount = 200_000
    static let maximumIDLength = 128

    static func isValidID(_ value: String) -> Bool {
        !value.isEmpty
            && value.count <= maximumIDLength
            && value.utf8.count <= maximumIDLength * 4
            && !value.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    }

    static func isValidHexColor(_ value: String) -> Bool {
        guard value.count == 7, value.first == "#" else { return false }
        return value.dropFirst().allSatisfy { $0.isHexDigit }
    }
}

struct ManualBackupHeader: Codable, Equatable {
    let formatIdentifier: String
    let schemaVersion: Int
    let createdAt: Date
    let appVersion: String?
    let algorithm: String
    let keyDerivation: String
    let iterations: Int
    let salt: Data
}

struct ManualBackupProfileRecord: Codable, Equatable {
    let id: UUID
    let nickname: String
    let avatarColorID: String
    let createdAt: Date
    let updatedAt: Date
}

struct ManualBackupPayloadV1: Codable {
    var moments: [PersistedMomentSnapshot]
    let sources: [SourceDetail]
    let pairs: [PairSummary]
    let profile: ManualBackupProfileRecord

    init(
        moments: [PersistedMomentSnapshot],
        sources: [SourceDetail],
        pairs: [PairSummary],
        profile: ManualBackupProfileRecord
    ) {
        self.moments = moments
        self.sources = sources
        self.pairs = pairs
        self.profile = profile
    }

    private enum CodingKeys: String, CodingKey { case moments, sources, pairs, profile }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        moments = try container.decode([PersistedMomentSnapshot].self, forKey: .moments)
        sources = try container.decode([SourceDetail].self, forKey: .sources)
        profile = try container.decode(ManualBackupProfileRecord.self, forKey: .profile)
        pairs = try container.decodeIfPresent([PairSummary].self, forKey: .pairs)
            ?? Self.derivePairs(from: moments)
    }

    private static func derivePairs(from moments: [PersistedMomentSnapshot]) -> [PairSummary] {
        Dictionary(grouping: moments.filter { $0.pairID != nil }, by: { $0.pairID! })
            .map { id, matching in
                let first = matching[0]
                let members = first.pairMemberNames ?? []
                return PairSummary(
                    id: id,
                    member1Name: members.first ?? first.pairName,
                    member2Name: members.dropFirst().first,
                    nickname: members.isEmpty ? "" : first.pairName,
                    momentCount: matching.count,
                    leadingColorHex: first.leadingColorHex,
                    trailingColorHex: first.trailingColorHex,
                    isFavorite: false
                )
            }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }
}

struct ManualBackupPreview: Equatable {
    let header: ManualBackupHeader
    let momentCount: Int
    let sourceCount: Int
    let pairCount: Int
    let episodeCount: Int
    let watchingSessionCount: Int
    let imageCount: Int
}

struct ManualRestoreResult: Equatable {
    let restoredAt: Date
    let preview: ManualBackupPreview
}

enum ManualBackupError: LocalizedError, Equatable {
    case invalidPassphrase
    case invalidFormat
    case unsupportedVersion(Int)
    case wrongPassphrase
    case authenticationFailed
    case fileReadFailed
    case fileWriteFailed
    case archiveTooLarge
    case contentTooLarge
    case imageTooLarge
    case tooManyEntries
    case validationFailed(reason: String)
    case restoreFailed(reason: String)
    case restoreNotAllowedWhileCloudSyncEnabled

    var errorDescription: String? {
        switch self {
        case .invalidPassphrase:
            return "パスフレーズは\(ManualBackupPassphrasePolicy.minimumLength)文字以上で入力してください。"
        case .invalidFormat:
            return "バックアップファイルの形式が正しくありません。"
        case .unsupportedVersion(let version):
            return "未対応のバックアップ形式です（version: \(version)）。"
        case .wrongPassphrase:
            return "パスフレーズが正しくありません。"
        case .authenticationFailed:
            return "バックアップが破損しているか、改ざんされています。"
        case .fileReadFailed:
            return "バックアップファイルを読み込めませんでした。"
        case .fileWriteFailed:
            return "バックアップファイルを書き込めませんでした。"
        case .archiveTooLarge:
            return "バックアップファイルが大きすぎます。"
        case .contentTooLarge:
            return "バックアップ内のデータ量が上限を超えています。"
        case .imageTooLarge:
            return "バックアップ内に大きすぎる画像があります。"
        case .tooManyEntries:
            return "バックアップ内のファイル数が上限を超えています。"
        case .validationFailed:
            return "バックアップの内容を確認できませんでした。"
        case .restoreFailed:
            return "バックアップを復元できませんでした。"
        case .restoreNotAllowedWhileCloudSyncEnabled:
            return "クラウド同期をオフにしてから復元してください。"
        }
    }
}

nonisolated protocol ManualBackupMetadataStoring: AnyObject {
    var lastExportAt: Date? { get set }
    var lastRestoreAt: Date? { get set }
}

nonisolated final class UserDefaultsManualBackupMetadataStore: ManualBackupMetadataStoring {
    private enum Key {
        static let lastExportAt = "manualBackup.lastExportAt"
        static let lastRestoreAt = "manualBackup.lastRestoreAt"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastExportAt: Date? {
        get { defaults.object(forKey: Key.lastExportAt) as? Date }
        set { defaults.set(newValue, forKey: Key.lastExportAt) }
    }

    var lastRestoreAt: Date? {
        get { defaults.object(forKey: Key.lastRestoreAt) as? Date }
        set { defaults.set(newValue, forKey: Key.lastRestoreAt) }
    }
}
