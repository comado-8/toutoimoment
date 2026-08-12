import CryptoKit
import Foundation
import ImageIO
import SwiftData
import ZIPFoundation

@MainActor
final class EncryptedManualBackupService: BackupServicing {
    private let modelContainer: ModelContainer
    private let imageRepository: any MomentImageRepository
    private let imageRootURL: URL
    private let cloudSyncEnabled: () -> Bool
    private let metadataStore: any ManualBackupMetadataStoring
    private let fileManager: FileManager
    private let backupDirectory: URL
    private let now: () -> Date
    private let appVersionProvider: () -> String?
    private let archiveCodec: ManualBackupArchiveCodec

    init(
        modelContainer: ModelContainer,
        imageRepository: any MomentImageRepository,
        imageRootURL: URL,
        cloudSyncEnabled: @escaping () -> Bool,
        metadataStore: any ManualBackupMetadataStoring = UserDefaultsManualBackupMetadataStore(),
        fileManager: FileManager = .default,
        backupDirectory: URL? = nil,
        now: @escaping () -> Date = Date.init,
        appVersionProvider: @escaping () -> String? = {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }
    ) {
        self.modelContainer = modelContainer
        self.imageRepository = imageRepository
        self.imageRootURL = imageRootURL
        self.cloudSyncEnabled = cloudSyncEnabled
        self.metadataStore = metadataStore
        self.fileManager = fileManager
        self.backupDirectory = backupDirectory
            ?? fileManager.temporaryDirectory.appendingPathComponent("manual-backups", isDirectory: true)
        self.now = now
        self.appVersionProvider = appVersionProvider
        self.archiveCodec = ManualBackupArchiveCodec(fileManager: fileManager)
    }

    func exportEncryptedBackup(passphrase: String) async throws -> URL {
        try validatePassphrase(passphrase)
        let payload = try makePayloadSnapshot()
        try Self.validate(payload: payload)

        let createdAt = now()
        let header = ManualBackupHeader(
            formatIdentifier: ManualBackupImportPolicy.formatIdentifier,
            schemaVersion: ManualBackupImportPolicy.currentSchemaVersion,
            createdAt: createdAt,
            appVersion: appVersionProvider(),
            algorithm: ManualBackupCrypto.algorithmIdentifier,
            keyDerivation: ManualBackupCrypto.keyDerivationIdentifier,
            iterations: ManualBackupCrypto.defaultPBKDF2Iterations,
            salt: try ManualBackupCrypto.makeSalt()
        )
        let key = try ManualBackupCrypto.deriveKey(
            passphrase: passphrase,
            salt: header.salt,
            iterations: header.iterations
        )

        let contentData = try Self.contentEncoder.encode(payload)
        guard contentData.count <= ManualBackupImportPolicy.maximumContentBytes else {
            throw ManualBackupError.contentTooLarge
        }
        let contentAAD = try ManualBackupCrypto.associatedData(
            header: header,
            entryIdentifier: ManualBackupArchiveCodec.contentPath
        )
        let encryptedContent = try ManualBackupCrypto.seal(
            contentData,
            key: key,
            associatedData: contentAAD
        )

        var encryptedAssets: [String: Data] = [:]
        for moment in payload.moments {
            for image in moment.images.sorted(by: { $0.order < $1.order }) {
                let data: Data
                do {
                    data = try await imageRepository.imageData(for: image, momentID: moment.id)
                } catch {
                    throw ManualBackupError.validationFailed(reason: "image-missing")
                }
                guard data.count <= ManualBackupImportPolicy.maximumImageBytes else {
                    throw ManualBackupError.imageTooLarge
                }
                try Self.validateImage(data)
                let path = ManualBackupArchiveCodec.assetPath(momentID: moment.id, imageID: image.id)
                guard encryptedAssets[path] == nil else {
                    throw ManualBackupError.validationFailed(reason: "asset-path-collision")
                }
                let aad = try ManualBackupCrypto.associatedData(
                    header: header,
                    entryIdentifier: Self.assetAADIdentifier(
                        path: path,
                        momentID: moment.id,
                        imageID: image.id
                    )
                )
                encryptedAssets[path] = try ManualBackupCrypto.seal(
                    data,
                    key: key,
                    associatedData: aad
                )
            }
        }

        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let outputURL = uniqueBackupURL(for: createdAt)
        let staging = backupDirectory.appendingPathComponent(
            ".export-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? fileManager.removeItem(at: staging) }
        try archiveCodec.createArchive(
            at: outputURL,
            header: header,
            encryptedContent: encryptedContent,
            encryptedAssets: encryptedAssets,
            stagingDirectory: staging
        )
        metadataStore.lastExportAt = createdAt
        return outputURL
    }

    func inspectEncryptedBackup(at url: URL, passphrase: String) async throws -> ManualBackupPreview {
        try validatePassphrase(passphrase)
        let decoded = try decodeBackup(at: url, passphrase: passphrase, validatesImages: true)
        return Self.makePreview(header: decoded.header, payload: decoded.payload)
    }

    func restoreEncryptedBackup(at url: URL, passphrase: String) async throws -> ManualRestoreResult {
        guard !cloudSyncEnabled() else {
            throw ManualBackupError.restoreNotAllowedWhileCloudSyncEnabled
        }
        try validatePassphrase(passphrase)

        let decoded = try decodeBackup(at: url, passphrase: passphrase, validatesImages: false)
        let workDirectory = fileManager.temporaryDirectory.appendingPathComponent(
            "manual-restore-\(UUID().uuidString)",
            isDirectory: true
        )
        let stagedImageRoot = workDirectory.appendingPathComponent("MomentImages", isDirectory: true)
        try fileManager.createDirectory(at: workDirectory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: workDirectory) }

        var restoredPayload = decoded.payload
        let stagingRepository = LocalMomentImageRepository(
            rootURL: stagedImageRoot,
            fileManager: fileManager
        )
        for momentIndex in restoredPayload.moments.indices {
            let momentID = restoredPayload.moments[momentIndex].id
            let originalImages = restoredPayload.moments[momentIndex].images.sorted { $0.order < $1.order }
            var stagedImages: [MomentImage] = []
            for image in originalImages {
                let data = try readAndDecryptAsset(
                    decoded: decoded,
                    momentID: momentID,
                    image: image
                )
                try Self.validateImage(data)
                do {
                    let images = try await stagingRepository.addImage(
                        data: data,
                        id: image.id,
                        createdAt: image.createdAt,
                        to: momentID
                    )
                    guard let restored = images.first(where: { $0.id == image.id }) else {
                        throw ManualBackupError.validationFailed(reason: "image-stage")
                    }
                    stagedImages.append(restored)
                } catch let error as ManualBackupError {
                    throw error
                } catch {
                    throw ManualBackupError.validationFailed(reason: "image-stage")
                }
            }
            restoredPayload.moments[momentIndex].images = stagedImages.sorted { $0.order < $1.order }
        }

        try replacePersistedContentAtomically(
            with: restoredPayload,
            stagedImageRoot: stagedImageRoot
        )
        let restoredAt = now()
        metadataStore.lastRestoreAt = restoredAt
        return ManualRestoreResult(
            restoredAt: restoredAt,
            preview: Self.makePreview(header: decoded.header, payload: restoredPayload)
        )
    }

    private func validatePassphrase(_ passphrase: String) throws {
        guard passphrase.count >= ManualBackupPassphrasePolicy.minimumLength else {
            throw ManualBackupError.invalidPassphrase
        }
    }

    private func makePayloadSnapshot() throws -> ManualBackupPayloadV1 {
        let context = ModelContext(modelContainer)
        guard let momentState = try context.fetch(FetchDescriptor<PersistedMomentState>()).first,
              let sourceState = try context.fetch(FetchDescriptor<PersistedSourceState>()).first,
              let pairState = try context.fetch(FetchDescriptor<PersistedPairState>()).first,
              let profileState = try context.fetch(FetchDescriptor<PersistedUserProfileState>()).first
        else {
            throw ManualBackupError.validationFailed(reason: "missing-state")
        }

        var moments: [PersistedMomentSnapshot]
        let sources: [SourceDetail]
        let pairs: [PairSummary]
        do {
            moments = try JSONDecoder().decode([PersistedMomentSnapshot].self, from: momentState.payload)
            sources = try JSONDecoder().decode([SourceDetail].self, from: sourceState.payload)
            pairs = try JSONDecoder().decode([PairSummary].self, from: pairState.payload)
        } catch {
            throw ManualBackupError.validationFailed(reason: "stored-data")
        }
        for index in moments.indices where moments[index].momentDate == nil {
            moments[index].momentDate = MomentDate(date: moments[index].createdAt)
        }
        return ManualBackupPayloadV1(
            moments: moments,
            sources: sources,
            pairs: pairs,
            profile: ManualBackupProfileRecord(
                id: profileState.id,
                nickname: profileState.nickname,
                avatarColorID: profileState.avatarColorID,
                createdAt: profileState.createdAt,
                updatedAt: profileState.updatedAt
            )
        )
    }

    private struct DecodedBackup {
        let header: ManualBackupHeader
        var payload: ManualBackupPayloadV1
        let key: SymmetricKey
        let archive: Archive
        let entriesByPath: [String: Entry]
    }

    private func decodeBackup(
        at url: URL,
        passphrase: String,
        validatesImages: Bool
    ) throws -> DecodedBackup {
        let contents = try archiveCodec.openArchive(at: url)
        guard let contentEntry = contents.entriesByPath[ManualBackupArchiveCodec.contentPath] else {
            throw ManualBackupError.invalidFormat
        }
        let key = try ManualBackupCrypto.deriveKey(
            passphrase: passphrase,
            salt: contents.header.salt,
            iterations: contents.header.iterations
        )
        let encryptedContent = try archiveCodec.readEntry(
            contentEntry,
            from: contents.archive,
            maximumBytes: ManualBackupImportPolicy.maximumContentBytes + 64
        )
        let contentAAD = try ManualBackupCrypto.associatedData(
            header: contents.header,
            entryIdentifier: ManualBackupArchiveCodec.contentPath
        )
        let contentData = try ManualBackupCrypto.open(
            encryptedContent,
            key: key,
            associatedData: contentAAD,
            wrongPassphraseError: true
        )
        guard contentData.count <= ManualBackupImportPolicy.maximumContentBytes else {
            throw ManualBackupError.contentTooLarge
        }
        try Self.rejectPrivilegeInjectionKeys(in: contentData)
        var payload: ManualBackupPayloadV1
        do {
            payload = try Self.contentDecoder.decode(ManualBackupPayloadV1.self, from: contentData)
        } catch {
            throw ManualBackupError.invalidFormat
        }
        for index in payload.moments.indices where payload.moments[index].momentDate == nil {
            payload.moments[index].momentDate = MomentDate(date: payload.moments[index].createdAt)
        }
        try Self.validate(payload: payload)

        let expectedAssets = Set(payload.moments.flatMap { moment in
            moment.images.map {
                ManualBackupArchiveCodec.assetPath(momentID: moment.id, imageID: $0.id)
            }
        })
        let actualAssets = Set(contents.entriesByPath.keys.filter(ManualBackupArchiveCodec.isValidAssetPath))
        guard expectedAssets == actualAssets,
              contents.entriesByPath.count == expectedAssets.count + 2
        else {
            throw ManualBackupError.validationFailed(reason: "asset-set")
        }

        let decoded = DecodedBackup(
            header: contents.header,
            payload: payload,
            key: key,
            archive: contents.archive,
            entriesByPath: contents.entriesByPath
        )
        if validatesImages {
            for moment in payload.moments {
                for image in moment.images {
                    let data = try readAndDecryptAsset(
                        decoded: decoded,
                        momentID: moment.id,
                        image: image
                    )
                    try Self.validateImage(data)
                }
            }
        }
        return decoded
    }

    private func readAndDecryptAsset(
        decoded: DecodedBackup,
        momentID: String,
        image: MomentImage
    ) throws -> Data {
        let path = ManualBackupArchiveCodec.assetPath(momentID: momentID, imageID: image.id)
        guard let entry = decoded.entriesByPath[path] else {
            throw ManualBackupError.validationFailed(reason: "asset-missing")
        }
        let encrypted = try archiveCodec.readEntry(
            entry,
            from: decoded.archive,
            maximumBytes: ManualBackupImportPolicy.maximumImageBytes + 64
        )
        let aad = try ManualBackupCrypto.associatedData(
            header: decoded.header,
            entryIdentifier: Self.assetAADIdentifier(
                path: path,
                momentID: momentID,
                imageID: image.id
            )
        )
        let data = try ManualBackupCrypto.open(
            encrypted,
            key: decoded.key,
            associatedData: aad,
            wrongPassphraseError: false
        )
        guard data.count <= ManualBackupImportPolicy.maximumImageBytes else {
            throw ManualBackupError.imageTooLarge
        }
        return data
    }

    private func replacePersistedContentAtomically(
        with payload: ManualBackupPayloadV1,
        stagedImageRoot: URL
    ) throws {
        let parent = imageRootURL.deletingLastPathComponent()
        let rollbackRoot = parent.appendingPathComponent(
            ".manual-restore-rollback-\(UUID().uuidString)",
            isDirectory: true
        )
        var movedExistingImages = false
        var installedStagedImages = false
        let context = modelContainer.mainContext

        do {
            try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: imageRootURL.path) {
                try fileManager.moveItem(at: imageRootURL, to: rollbackRoot)
                movedExistingImages = true
            }
            if fileManager.fileExists(atPath: stagedImageRoot.path) {
                try fileManager.moveItem(at: stagedImageRoot, to: imageRootURL)
                installedStagedImages = true
            } else {
                try fileManager.createDirectory(at: imageRootURL, withIntermediateDirectories: true)
                installedStagedImages = true
            }

            let momentPayload = try JSONEncoder().encode(payload.moments)
            let sourcePayload = try JSONEncoder().encode(payload.sources)
            let pairPayload = try JSONEncoder().encode(payload.pairs)
            try Self.replaceState(
                PersistedMomentState.self,
                in: context,
                make: { PersistedMomentState(fixtureVersion: 1, payload: momentPayload) },
                update: {
                    $0.fixtureVersion = 1
                    $0.payload = momentPayload
                }
            )
            try Self.replaceState(
                PersistedSourceState.self,
                in: context,
                make: { PersistedSourceState(fixtureVersion: 1, payload: sourcePayload) },
                update: {
                    $0.fixtureVersion = 1
                    $0.payload = sourcePayload
                }
            )
            try Self.replaceState(
                PersistedPairState.self,
                in: context,
                make: { PersistedPairState(payload: pairPayload) },
                update: {
                    $0.schemaVersion = 1
                    $0.payload = pairPayload
                }
            )
            let profiles = try context.fetch(FetchDescriptor<PersistedUserProfileState>())
            if let existing = profiles.first {
                existing.id = payload.profile.id
                existing.nickname = payload.profile.nickname
                existing.avatarColorID = payload.profile.avatarColorID
                existing.createdAt = payload.profile.createdAt
                existing.updatedAt = payload.profile.updatedAt
                for extra in profiles.dropFirst() { context.delete(extra) }
            } else {
                context.insert(
                    PersistedUserProfileState(
                        id: payload.profile.id,
                        nickname: payload.profile.nickname,
                        avatarColorID: payload.profile.avatarColorID,
                        createdAt: payload.profile.createdAt,
                        updatedAt: payload.profile.updatedAt
                    )
                )
            }
            try context.save()
            if movedExistingImages { try? fileManager.removeItem(at: rollbackRoot) }
        } catch {
            context.rollback()
            if installedStagedImages { try? fileManager.removeItem(at: imageRootURL) }
            if movedExistingImages { try? fileManager.moveItem(at: rollbackRoot, to: imageRootURL) }
            if let backupError = error as? ManualBackupError { throw backupError }
            throw ManualBackupError.restoreFailed(reason: "atomic-replace")
        }
    }

    private static func replaceState<Model: PersistentModel>(
        _ type: Model.Type,
        in context: ModelContext,
        make: () -> Model,
        update: (Model) -> Void
    ) throws {
        let states = try context.fetch(FetchDescriptor<Model>())
        if let existing = states.first {
            update(existing)
            for extra in states.dropFirst() { context.delete(extra) }
        } else {
            context.insert(make())
        }
    }

    private static func validate(payload: ManualBackupPayloadV1) throws {
        var nodeCount = payload.moments.count + payload.sources.count + payload.pairs.count
        guard nodeCount <= ManualBackupImportPolicy.maximumNodeCount else {
            throw ManualBackupError.validationFailed(reason: "node-count")
        }

        try validateUniqueIDs(payload.moments.map(\.id), label: "moment")
        try validateUniqueIDs(payload.sources.map(\.id), label: "source")
        try validateUniqueIDs(payload.pairs.map(\.id), label: "pair")
        for pair in payload.pairs {
            guard ManualBackupImportPolicy.isValidID(pair.id),
                  !pair.member1Name.isEmpty,
                  PairTextPolicy.limitedMember(pair.member1Name) == pair.member1Name,
                  (pair.member2Name.map {
                      !$0.isEmpty && PairTextPolicy.limitedMember($0) == $0
                  } ?? true),
                  pair.nickname.utf8.count <= 1_024,
                  pair.momentCount >= 0,
                  ManualBackupImportPolicy.isValidHexColor(pair.leadingColorHex),
                  pair.trailingColorHex.map(ManualBackupImportPolicy.isValidHexColor) ?? true
            else { throw ManualBackupError.validationFailed(reason: "pair") }
        }
        var episodeIDs = Set<String>()
        var sessionIDs = Set<String>()
        var eventIDs = Set<String>()
        var imageIDs = Set<String>()
        var episodeSourceByID: [String: String] = [:]
        var eventKinds: [WatchingSessionEvent.Kind] = []

        for source in payload.sources {
            guard ManualBackupImportPolicy.isValidID(source.id),
                  SourceNamePolicy.normalized(source.summary.displayName) == source.summary.displayName,
                  source.summary.helperText.utf8.count <= 4 * 1_024,
                  source.summary.mediaType.utf8.count <= 128,
                  (source.summary.mediaType == "streaming"
                      ? source.summary.streamingPlatform?.isValid == true
                      : source.summary.streamingPlatform == nil),
                  SourceRelatedURLPolicy.isValid(source.summary.relatedURL),
                  source.summary.momentCount >= 0
            else {
                throw ManualBackupError.validationFailed(reason: "source")
            }
            nodeCount += source.episodes.count
            for episode in source.episodes {
                guard ManualBackupImportPolicy.isValidID(episode.id),
                      episodeIDs.insert(episode.id).inserted,
                      episode.relatedURL.map(SourceRelatedURLPolicy.isValid) ?? true,
                      EpisodeDisplayTitlePolicy.normalized(episode.displayTitle) == episode.displayTitle,
                      episode.momentCount >= 0,
                      episode.viewedCount >= 0,
                      episode.durationAndProgressAreValid
                else {
                    throw ManualBackupError.validationFailed(reason: "episode")
                }
                episodeSourceByID[episode.id] = source.id
                nodeCount += episode.locatorValues.count + episode.watchingSessions.count
                try validateLocatorValues(episode.locatorValues)
                for session in episode.watchingSessions {
                    guard ManualBackupImportPolicy.isValidID(session.id),
                          sessionIDs.insert(session.id).inserted,
                          session.durationSeconds >= 0,
                          session.momentCount >= 0,
                          session.reactionCount >= 0
                    else {
                        throw ManualBackupError.validationFailed(reason: "session")
                    }
                    nodeCount += session.events.count
                    for event in session.events {
                        guard ManualBackupImportPolicy.isValidID(event.id),
                              eventIDs.insert(event.id).inserted,
                              event.elapsedSeconds >= 0
                        else {
                            throw ManualBackupError.validationFailed(reason: "event")
                        }
                        eventKinds.append(event.kind)
                    }
                }
            }
        }

        let sourceIDs = Set(payload.sources.map(\.id))
        for moment in payload.moments {
            guard ManualBackupImportPolicy.isValidID(moment.id),
                  moment.title.map(MomentTitlePolicy.isValid) ?? true,
                  MomentSceneTextPolicy.isValid(moment.sceneNote),
                  HeartScreamTextPolicy.isValid(moment.heartText),
                  moment.caption.utf8.count <= 16 * 1_024,
                  moment.pairName.utf8.count <= 1_024,
                  (moment.pairMemberNames?.count ?? 0) <= 2,
                  (moment.pairMemberNames?.allSatisfy {
                      !$0.isEmpty && PairTextPolicy.limitedMember($0) == $0
                  } ?? true),
                  moment.sourceName.utf8.count <= 1_024,
                  moment.mediaType?.utf8.count ?? 0 <= 128,
                  moment.pairID.map(ManualBackupImportPolicy.isValidID) ?? true,
                  ManualBackupImportPolicy.isValidHexColor(moment.leadingColorHex),
                  ManualBackupImportPolicy.isValidHexColor(moment.trailingColorHex),
                  moment.reactionIDs.count == moment.reactionLabels.count,
                  moment.reactionIDs.count <= 100,
                  moment.contextValues.count <= 100,
                  moment.images.count <= LocalMomentImageRepository.maximumImageCount
            else {
                throw ManualBackupError.validationFailed(reason: "moment")
            }
            guard moment.momentDate?.isValid == true else {
                throw ManualBackupError.validationFailed(reason: "moment-date")
            }
            if let pairID = moment.pairID,
               let pair = payload.pairs.first(where: { $0.id == pairID }) {
                if let memberNames = moment.pairMemberNames, !memberNames.isEmpty,
                   (moment.pairName != pair.displayName
                    || memberNames != [pair.member1Name, pair.member2Name].compactMap({ $0 })) {
                    throw ManualBackupError.validationFailed(reason: "moment-pair-snapshot")
                }
            } else if moment.pairID != nil {
                throw ManualBackupError.validationFailed(reason: "moment-pair")
            }
            try validateUniqueIDs(moment.reactionIDs, label: "moment-reaction")
            if let sourceID = moment.sourceID {
                guard sourceIDs.contains(sourceID) else {
                    throw ManualBackupError.validationFailed(reason: "moment-source")
                }
            }
            if let episodeID = moment.episodeID {
                guard let sourceID = moment.sourceID,
                      episodeSourceByID[episodeID] == sourceID
                else {
                    throw ManualBackupError.validationFailed(reason: "moment-episode")
                }
            }
            try validateLocatorValues(moment.episodeLocatorValues)
            var orders = Set<Int>()
            for image in moment.images {
                guard ManualBackupImportPolicy.isValidID(image.id),
                      imageIDs.insert(image.id).inserted,
                      orders.insert(image.order).inserted,
                      image.order >= 0,
                      image.order < LocalMomentImageRepository.maximumImageCount,
                      image.pixelWidth > 0,
                      image.pixelHeight > 0,
                      image.pixelWidth <= LocalMomentImageRepository.maximumPixelDimension,
                      image.pixelHeight <= LocalMomentImageRepository.maximumPixelDimension,
                      image.pixelWidth * image.pixelHeight <= 4_194_304
                else {
                    throw ManualBackupError.validationFailed(reason: "image-metadata")
                }
            }
            nodeCount += moment.images.count + moment.contextValues.count + moment.reactionIDs.count
        }

        let momentIDs = Set(payload.moments.map(\.id))
        for kind in eventKinds {
            switch kind {
            case .reaction(let reaction):
                guard ManualBackupImportPolicy.isValidID(reaction.reactionID),
                      reaction.displayText.utf8.count <= 4 * 1_024,
                      reaction.count > 0,
                      reaction.count <= 1_000_000
                else {
                    throw ManualBackupError.validationFailed(reason: "event-reaction")
                }
            case .voiceNote(let text):
                guard text.utf8.count <= 16 * 1_024 else {
                    throw ManualBackupError.validationFailed(reason: "event-voice")
                }
            case .liveHeartScream(let momentID, let comment, let pairID):
                guard momentID.map(momentIDs.contains) ?? true,
                      pairID.map(ManualBackupImportPolicy.isValidID) ?? true,
                      comment.utf8.count <= 16 * 1_024
                else {
                    throw ManualBackupError.validationFailed(reason: "event-moment-reference")
                }
            }
        }

        guard AvatarColorSelection(rawValue: payload.profile.avatarColorID) != nil,
              !payload.profile.nickname.isEmpty,
              payload.profile.nickname.count <= 100,
              payload.profile.nickname.utf8.count <= 1_024,
              nodeCount <= ManualBackupImportPolicy.maximumNodeCount
        else {
            throw ManualBackupError.validationFailed(reason: "profile-or-count")
        }
    }

    private static func rejectPrivilegeInjectionKeys(in data: Data) throws {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw ManualBackupError.invalidFormat
        }
        let forbiddenFragments = [
            "purchase", "premium", "entitlement", "subscription",
            "cloud", "setting", "lastsynced"
        ]
        func inspect(_ value: Any) throws {
            if let dictionary = value as? [String: Any] {
                for (key, child) in dictionary {
                    let normalized = key.lowercased().filter(\.isLetter)
                    guard !forbiddenFragments.contains(where: normalized.contains) else {
                        throw ManualBackupError.validationFailed(reason: "privilege-field")
                    }
                    try inspect(child)
                }
            } else if let array = value as? [Any] {
                for child in array { try inspect(child) }
            }
        }
        try inspect(object)
    }

    private static func validateUniqueIDs(_ ids: [String], label: String) throws {
        var seen = Set<String>()
        for id in ids {
            guard ManualBackupImportPolicy.isValidID(id), seen.insert(id).inserted else {
                throw ManualBackupError.validationFailed(reason: "duplicate-\(label)")
            }
        }
    }

    private static func validateLocatorValues(_ values: [LocatorValue]) throws {
        guard values.count <= 100 else {
            throw ManualBackupError.validationFailed(reason: "locator-count")
        }
        var keys = Set<String>()
        for value in values {
            guard ManualBackupImportPolicy.isValidID(value.key),
                  keys.insert(value.key).inserted,
                  value.value.utf8.count <= 8 * 1_024
            else {
                throw ManualBackupError.validationFailed(reason: "locator")
            }
        }
    }

    private static func validateImage(_ data: Data) throws {
        guard data.count <= ManualBackupImportPolicy.maximumImageBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) == 1,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0,
              height > 0,
              width <= LocalMomentImageRepository.maximumPixelDimension,
              height <= LocalMomentImageRepository.maximumPixelDimension,
              width * height <= 4_194_304,
              CGImageSourceCreateThumbnailAtIndex(
                  source,
                  0,
                  [
                      kCGImageSourceCreateThumbnailFromImageAlways: true,
                      kCGImageSourceCreateThumbnailWithTransform: true,
                      kCGImageSourceThumbnailMaxPixelSize:
                          LocalMomentImageRepository.maximumPixelDimension,
                      kCGImageSourceShouldCacheImmediately: true,
                  ] as CFDictionary
              ) != nil
        else {
            throw ManualBackupError.validationFailed(reason: "image-data")
        }
    }

    private static func makePreview(
        header: ManualBackupHeader,
        payload: ManualBackupPayloadV1
    ) -> ManualBackupPreview {
        let episodes = payload.sources.flatMap(\.episodes)
        return ManualBackupPreview(
            header: header,
            momentCount: payload.moments.count,
            sourceCount: payload.sources.count,
            pairCount: payload.pairs.count,
            episodeCount: episodes.count,
            watchingSessionCount: episodes.reduce(0) { $0 + $1.watchingSessions.count },
            imageCount: payload.moments.reduce(0) { $0 + $1.images.count }
        )
    }

    private static func assetAADIdentifier(path: String, momentID: String, imageID: String) -> String {
        "\(path)\u{0}\(momentID)\u{0}\(imageID)"
    }

    private func uniqueBackupURL(for date: Date) -> URL {
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let name = "TouToiMomentBackup_\(Self.filenameFormatter.string(from: date))_\(suffix).ttmbackup"
        return backupDirectory.appendingPathComponent(name)
    }

    private static let contentEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let contentDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}

private extension EpisodeSummary {
    var durationAndProgressAreValid: Bool {
        guard let progress else { return true }
        return progress.isFinite && progress >= 0 && progress <= 1
    }
}
