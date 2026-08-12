import CryptoKit
import Foundation
import SwiftData
import SwiftUI
import Testing
import UIKit
import ZIPFoundation
@testable import TouToiMoment

@MainActor
struct ManualBackupTests {
    private let passphrase = "correct horse battery staple"

    @Test func encryptedRoundTripRestoresOnlyContentAndProfile() async throws {
        let fixture = try await makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let settingsStore = SettingsStore(
            repository: PersistentSettingsRepository(context: fixture.container.mainContext)
        )
        let purchaseService = BackupTestPurchaseService()
        let originalSettingsStore = settingsStore
        let originalPurchaseService = purchaseService

        let exportedURL = try await fixture.service.exportEncryptedBackup(passphrase: passphrase)
        let preview = try await fixture.service.inspectEncryptedBackup(
            at: exportedURL,
            passphrase: passphrase
        )
        #expect(preview.momentCount == 1)
        #expect(preview.imageCount == 1)
        #expect(preview.sourceCount == 0)
        #expect(preview.pairCount == 1)

        let context = fixture.container.mainContext
        let momentState = try #require(context.fetch(FetchDescriptor<PersistedMomentState>()).first)
        momentState.payload = try JSONEncoder().encode([PersistedMomentSnapshot]())
        let profileState = try #require(context.fetch(FetchDescriptor<PersistedUserProfileState>()).first)
        profileState.nickname = "復元前に変更した名前"
        let pairState = try #require(context.fetch(FetchDescriptor<PersistedPairState>()).first)
        pairState.payload = try JSONEncoder().encode([PairSummary]())
        settingsStore.markSynced(at: Date(timeIntervalSince1970: 9_999))
        try context.save()

        _ = try await fixture.service.restoreEncryptedBackup(
            at: exportedURL,
            passphrase: passphrase
        )

        let restoredSnapshots = try JSONDecoder().decode(
            [PersistedMomentSnapshot].self,
            from: try #require(context.fetch(FetchDescriptor<PersistedMomentState>()).first).payload
        )
        let restoredProfile = try #require(
            context.fetch(FetchDescriptor<PersistedUserProfileState>()).first
        )
        let restoredSettings = try PersistentSettingsRepository(context: context).loadSettings()
        let restoredPairs = try JSONDecoder().decode(
            [PairSummary].self,
            from: try #require(context.fetch(FetchDescriptor<PersistedPairState>()).first).payload
        )
        let restoredImage = try await fixture.imageRepository.imageData(
            for: try #require(restoredSnapshots.first?.images.first),
            momentID: "moment-backup-test"
        )

        #expect(restoredSnapshots.map(\.id) == ["moment-backup-test"])
        #expect(restoredSnapshots.first?.momentDate != nil)
        #expect(restoredProfile.nickname == "バックアップ太郎")
        #expect(restoredPairs.map(\.id) == ["pair-backup-test"])
        #expect(restoredSettings.lastSyncedAt == Date(timeIntervalSince1970: 9_999))
        #expect(settingsStore === originalSettingsStore)
        #expect(purchaseService === originalPurchaseService)
        #expect(UIImage(data: restoredImage) != nil)
        #expect(fixture.metadata.lastExportAt != nil)
        #expect(fixture.metadata.lastRestoreAt != nil)
    }

    @Test func wrongPassphraseAndAuthenticatedTamperingAreRejected() async throws {
        let fixture = try await makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let exportedURL = try await fixture.service.exportEncryptedBackup(passphrase: passphrase)

        await #expect(throws: ManualBackupError.self) {
            _ = try await fixture.service.inspectEncryptedBackup(
                at: exportedURL,
                passphrase: "this is the wrong passphrase"
            )
        }

        let codec = ManualBackupArchiveCodec()
        let archive = try codec.openArchive(at: exportedURL)
        let contentEntry = try #require(
            archive.entriesByPath[ManualBackupArchiveCodec.contentPath]
        )
        var encryptedContent = try codec.readEntry(
            contentEntry,
            from: archive.archive,
            maximumBytes: ManualBackupImportPolicy.maximumContentBytes + 64
        )
        encryptedContent[encryptedContent.startIndex] ^= 0x01
        let tamperedURL = fixture.root.appendingPathComponent("tampered.ttmbackup")
        try codec.createArchive(
            at: tamperedURL,
            header: archive.header,
            encryptedContent: encryptedContent,
            encryptedAssets: try encryptedAssets(from: archive, codec: codec),
            stagingDirectory: fixture.root.appendingPathComponent("tamper-staging")
        )

        await #expect(throws: ManualBackupError.self) {
            _ = try await fixture.service.inspectEncryptedBackup(
                at: tamperedURL,
                passphrase: passphrase
            )
        }
    }

    @Test func eachAESGCMEntryUsesANewNonce() throws {
        let header = try makeHeader()
        let key = try ManualBackupCrypto.deriveKey(
            passphrase: passphrase,
            salt: header.salt,
            iterations: header.iterations
        )
        let aad = try ManualBackupCrypto.associatedData(
            header: header,
            entryIdentifier: "content.enc"
        )
        let first = try ManualBackupCrypto.seal(Data("same".utf8), key: key, associatedData: aad)
        let second = try ManualBackupCrypto.seal(Data("same".utf8), key: key, associatedData: aad)
        #expect(first != second)
    }

    @Test func encryptedPayloadCannotInjectPurchaseOrCloudState() async throws {
        let fixture = try await makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let exportedURL = try await fixture.service.exportEncryptedBackup(passphrase: passphrase)
        let codec = ManualBackupArchiveCodec()
        let contents = try codec.openArchive(at: exportedURL)
        let entry = try #require(contents.entriesByPath[ManualBackupArchiveCodec.contentPath])
        let key = try ManualBackupCrypto.deriveKey(
            passphrase: passphrase,
            salt: contents.header.salt,
            iterations: contents.header.iterations
        )
        let aad = try ManualBackupCrypto.associatedData(
            header: contents.header,
            entryIdentifier: ManualBackupArchiveCodec.contentPath
        )
        let encrypted = try codec.readEntry(
            entry,
            from: contents.archive,
            maximumBytes: ManualBackupImportPolicy.maximumContentBytes + 64
        )
        let plaintext = try ManualBackupCrypto.open(
            encrypted,
            key: key,
            associatedData: aad,
            wrongPassphraseError: false
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: plaintext) as? [String: Any]
        )
        object["purchaseState"] = ["isPremium": true]
        object["cloudSyncEnabled"] = true
        let injectedContent = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let injectedURL = fixture.root.appendingPathComponent("privilege-injection.ttmbackup")
        try codec.createArchive(
            at: injectedURL,
            header: contents.header,
            encryptedContent: try ManualBackupCrypto.seal(
                injectedContent,
                key: key,
                associatedData: aad
            ),
            encryptedAssets: try encryptedAssets(from: contents, codec: codec),
            stagingDirectory: fixture.root.appendingPathComponent("injection-staging")
        )

        await #expect(throws: ManualBackupError.self) {
            _ = try await fixture.service.inspectEncryptedBackup(
                at: injectedURL,
                passphrase: passphrase
            )
        }
    }

    @Test func cloudSyncPreventsRestoreWithoutChangingData() async throws {
        let fixture = try await makeFixture(cloudSyncEnabled: true)
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let exportedURL = try await fixture.service.exportEncryptedBackup(passphrase: passphrase)

        await #expect(throws: ManualBackupError.restoreNotAllowedWhileCloudSyncEnabled) {
            _ = try await fixture.service.restoreEncryptedBackup(
                at: exportedURL,
                passphrase: passphrase
            )
        }
        let state = try #require(
            fixture.container.mainContext.fetch(FetchDescriptor<PersistedMomentState>()).first
        )
        let snapshots = try JSONDecoder().decode([PersistedMomentSnapshot].self, from: state.payload)
        #expect(snapshots.map(\.id) == ["moment-backup-test"])
    }

    @Test func archiveReaderRejectsTraversalWithoutWritingOutsideStaging() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let sentinel = root.appendingPathComponent("sentinel")
        try Data("safe".utf8).write(to: sentinel)
        let source = root.appendingPathComponent("entry")
        try Data("bad".utf8).write(to: source)
        let archiveURL = root.appendingPathComponent("traversal.ttmbackup")
        let archive = try Archive(url: archiveURL, accessMode: .create)
        try archive.addEntry(with: "../sentinel", fileURL: source, compressionMethod: .none)

        #expect(throws: ManualBackupError.self) {
            _ = try ManualBackupArchiveCodec().openArchive(at: archiveURL)
        }
        #expect(try Data(contentsOf: sentinel) == Data("safe".utf8))
    }

    @Test func failedInspectionClearsPreviouslySuccessfulRestoreCandidate() async throws {
        let service = FlakyBackupInspectionService()
        let viewModel = ManualBackupSettingsViewModel(
            service: service,
            metadataStore: BackupTestMetadataStore()
        )
        let url = URL(fileURLWithPath: "/tmp/test.ttmbackup")

        #expect(await viewModel.inspect(url: url, passphrase: passphrase))
        #expect(viewModel.pendingPreview != nil)

        service.shouldFailInspection = true
        #expect(!(await viewModel.inspect(url: url, passphrase: passphrase)))
        #expect(viewModel.pendingPreview == nil)
        #expect(await viewModel.restorePending() == nil)
        #expect(service.restoreCount == 0)
    }

    private func makeFixture(cloudSyncEnabled: Bool = false) async throws -> BackupFixture {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "manual-backup-test-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let imageRoot = root.appendingPathComponent("MomentImages", isDirectory: true)
        let imageRepository = LocalMomentImageRepository(rootURL: imageRoot)
        let imageData = try #require(
            UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12))
                .image { context in
                    UIColor.systemPurple.setFill()
                    context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
                }
                .pngData()
        )
        let images = try await imageRepository.addImage(
            data: imageData,
            id: "image-backup-test",
            createdAt: Date(timeIntervalSince1970: 1_000),
            to: "moment-backup-test"
        )
        let moment = MomentCardModel(
            id: "moment-backup-test",
            title: "Unicode 🌸",
            sceneText: "あの瞬間",
            heartText: "尊い！",
            caption: "",
            pairID: "pair-backup-test",
            pairName: "葵 ・ 凛",
            sourceID: nil,
            sourceName: "—",
            mediaType: nil,
            contextValues: [.init(key: "memo", value: "改行\nも保持")],
            reactionIDs: ["positive.kyun"],
            reactionLabels: ["🥰 キュン"],
            images: images,
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            createdAt: Date(timeIntervalSince1970: 2_000),
            isFavorite: true
        )
        let container = try ModelContainer(
            for: PersistedSourceState.self,
            PersistedPairState.self,
            PersistedMomentState.self,
            PersistedUserProfileState.self,
            PersistedAppSettingsState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(
            PersistedMomentState(
                fixtureVersion: 1,
                payload: try JSONEncoder().encode([PersistedMomentSnapshot(moment: moment)])
            )
        )
        context.insert(
            PersistedSourceState(fixtureVersion: 1, payload: try JSONEncoder().encode([SourceDetail]()))
        )
        context.insert(
            PersistedPairState(
                payload: try JSONEncoder().encode([
                    PairSummary(
                        id: "pair-backup-test",
                        member1Name: "葵",
                        member2Name: "凛",
                        nickname: "",
                        momentCount: 1,
                        leadingColorHex: "#46C1B1",
                        trailingColorHex: "#F26767",
                        isFavorite: true
                    )
                ])
            )
        )
        context.insert(
            PersistedUserProfileState(
                id: UUID(),
                nickname: "バックアップ太郎",
                avatarColorID: AvatarColorSelection.purple.rawValue,
                createdAt: Date(timeIntervalSince1970: 100),
                updatedAt: Date(timeIntervalSince1970: 200)
            )
        )
        context.insert(
            PersistedAppSettingsState(
                backgroundThemeID: ThemeSelection.defaultTheme.rawValue,
                keepScreenAwake: true,
                showElapsedTime: true,
                hapticFeedbackEnabled: true,
                cloudSyncEnabled: false,
                lastSyncedAt: nil,
                createdAt: Date(timeIntervalSince1970: 100),
                updatedAt: Date(timeIntervalSince1970: 200)
            )
        )
        try context.save()
        let metadata = BackupTestMetadataStore()
        let service = EncryptedManualBackupService(
            modelContainer: container,
            imageRepository: imageRepository,
            imageRootURL: imageRoot,
            cloudSyncEnabled: { cloudSyncEnabled },
            metadataStore: metadata,
            backupDirectory: root.appendingPathComponent("Backups", isDirectory: true),
            now: { Date(timeIntervalSince1970: 3_000) },
            appVersionProvider: { "1.0-test" }
        )
        return BackupFixture(
            root: root,
            container: container,
            imageRepository: imageRepository,
            metadata: metadata,
            service: service
        )
    }

    private func encryptedAssets(
        from contents: ManualBackupArchiveContents,
        codec: ManualBackupArchiveCodec
    ) throws -> [String: Data] {
        var result: [String: Data] = [:]
        for (path, entry) in contents.entriesByPath where ManualBackupArchiveCodec.isValidAssetPath(path) {
            result[path] = try codec.readEntry(
                entry,
                from: contents.archive,
                maximumBytes: ManualBackupImportPolicy.maximumImageBytes + 64
            )
        }
        return result
    }

    private func makeHeader() throws -> ManualBackupHeader {
        ManualBackupHeader(
            formatIdentifier: ManualBackupImportPolicy.formatIdentifier,
            schemaVersion: ManualBackupImportPolicy.currentSchemaVersion,
            createdAt: Date(timeIntervalSince1970: 1),
            appVersion: "test",
            algorithm: ManualBackupCrypto.algorithmIdentifier,
            keyDerivation: ManualBackupCrypto.keyDerivationIdentifier,
            iterations: ManualBackupCrypto.defaultPBKDF2Iterations,
            salt: try ManualBackupCrypto.makeSalt()
        )
    }
}

@MainActor
private struct BackupFixture {
    let root: URL
    let container: ModelContainer
    let imageRepository: LocalMomentImageRepository
    let metadata: BackupTestMetadataStore
    let service: EncryptedManualBackupService
}

nonisolated private final class BackupTestMetadataStore: ManualBackupMetadataStoring {
    var lastExportAt: Date?
    var lastRestoreAt: Date?
}

private final class BackupTestPurchaseService: PurchaseServicing {
    let isPremium = true
    let localizedOneTimePrice: String? = "¥100"
    func purchase() async throws {}
    func restore() async throws {}
}

@MainActor
private final class FlakyBackupInspectionService: BackupServicing {
    var shouldFailInspection = false
    private(set) var restoreCount = 0

    func exportEncryptedBackup(passphrase: String) async throws -> URL {
        throw MVPBackupTestError.expected
    }

    func inspectEncryptedBackup(
        at url: URL,
        passphrase: String
    ) async throws -> ManualBackupPreview {
        if shouldFailInspection { throw MVPBackupTestError.expected }
        return ManualBackupPreview(
            header: ManualBackupHeader(
                formatIdentifier: ManualBackupImportPolicy.formatIdentifier,
                schemaVersion: 1,
                createdAt: .now,
                appVersion: "test",
                algorithm: "test",
                keyDerivation: "test",
                iterations: 1,
                salt: Data()
            ),
            momentCount: 0,
            sourceCount: 0,
            pairCount: 0,
            episodeCount: 0,
            watchingSessionCount: 0,
            imageCount: 0
        )
    }

    func restoreEncryptedBackup(
        at url: URL,
        passphrase: String
    ) async throws -> ManualRestoreResult {
        restoreCount += 1
        throw MVPBackupTestError.expected
    }
}

private enum MVPBackupTestError: Error {
    case expected
}
