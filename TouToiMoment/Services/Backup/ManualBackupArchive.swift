import Foundation
import ZIPFoundation

struct ManualBackupArchiveContents {
    let header: ManualBackupHeader
    let archive: Archive
    let entriesByPath: [String: Entry]
}

struct ManualBackupArchiveCodec {
    static let headerPath = "header.json"
    static let contentPath = "content.enc"
    private static let maximumHeaderBytes = 64 * 1_024

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func createArchive(
        at outputURL: URL,
        header: ManualBackupHeader,
        encryptedContent: Data,
        encryptedAssets: [String: Data],
        stagingDirectory: URL
    ) throws {
        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        let headerURL = stagingDirectory.appendingPathComponent(Self.headerPath)
        let contentURL = stagingDirectory.appendingPathComponent(Self.contentPath)

        do {
            try encoder.encode(header).write(to: headerURL, options: .atomic)
            try encryptedContent.write(to: contentURL, options: .atomic)
            if fileManager.fileExists(atPath: outputURL.path) {
                try fileManager.removeItem(at: outputURL)
            }
            let archive = try Archive(url: outputURL, accessMode: .create)
            try archive.addEntry(
                with: Self.headerPath,
                fileURL: headerURL,
                compressionMethod: .none
            )
            try archive.addEntry(
                with: Self.contentPath,
                fileURL: contentURL,
                compressionMethod: .none
            )

            for path in encryptedAssets.keys.sorted() {
                guard Self.isValidAssetPath(path), let data = encryptedAssets[path] else {
                    throw ManualBackupError.invalidFormat
                }
                let fileURL = stagingDirectory.appendingPathComponent(UUID().uuidString)
                try data.write(to: fileURL, options: .atomic)
                defer { try? fileManager.removeItem(at: fileURL) }
                try archive.addEntry(with: path, fileURL: fileURL, compressionMethod: .none)
            }
        } catch let error as ManualBackupError {
            try? fileManager.removeItem(at: outputURL)
            throw error
        } catch {
            try? fileManager.removeItem(at: outputURL)
            throw ManualBackupError.fileWriteFailed
        }
    }

    func openArchive(at url: URL) throws -> ManualBackupArchiveContents {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values?.isRegularFile == true, let byteCount = values?.fileSize else {
            throw ManualBackupError.fileReadFailed
        }
        guard Int64(byteCount) <= ManualBackupImportPolicy.maximumArchiveBytes else {
            throw ManualBackupError.archiveTooLarge
        }

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ManualBackupError.invalidFormat
        }

        var entriesByPath: [String: Entry] = [:]
        var totalUncompressedBytes: UInt64 = 0
        var count = 0
        for entry in archive {
            count += 1
            guard count <= ManualBackupImportPolicy.maximumEntryCount else {
                throw ManualBackupError.tooManyEntries
            }
            guard entry.type == .file,
                  Self.isAllowedPath(entry.path),
                  entriesByPath.updateValue(entry, forKey: entry.path) == nil
            else {
                throw ManualBackupError.invalidFormat
            }
            let (newTotal, overflowed) = totalUncompressedBytes.addingReportingOverflow(
                UInt64(entry.uncompressedSize)
            )
            guard !overflowed,
                  newTotal <= UInt64(ManualBackupImportPolicy.maximumArchiveBytes)
            else {
                throw ManualBackupError.archiveTooLarge
            }
            totalUncompressedBytes = newTotal
        }

        guard let headerEntry = entriesByPath[Self.headerPath],
              entriesByPath[Self.contentPath] != nil
        else {
            throw ManualBackupError.invalidFormat
        }
        let headerData = try readEntry(
            headerEntry,
            from: archive,
            maximumBytes: Self.maximumHeaderBytes
        )
        let header: ManualBackupHeader
        do {
            header = try decoder.decode(ManualBackupHeader.self, from: headerData)
        } catch {
            throw ManualBackupError.invalidFormat
        }
        try validate(header: header)
        return ManualBackupArchiveContents(
            header: header,
            archive: archive,
            entriesByPath: entriesByPath
        )
    }

    func readEntry(_ entry: Entry, from archive: Archive, maximumBytes: Int) throws -> Data {
        guard entry.type == .file,
              UInt64(entry.uncompressedSize) <= UInt64(maximumBytes)
        else {
            throw ManualBackupError.contentTooLarge
        }
        var result = Data()
        result.reserveCapacity(Int(entry.uncompressedSize))
        do {
            _ = try archive.extract(entry, bufferSize: 64 * 1_024, skipCRC32: false) { chunk in
                guard result.count <= maximumBytes - chunk.count else {
                    throw ManualBackupError.contentTooLarge
                }
                result.append(chunk)
            }
        } catch let error as ManualBackupError {
            throw error
        } catch {
            throw ManualBackupError.invalidFormat
        }
        return result
    }

    static func assetPath(momentID: String, imageID: String) -> String {
        "assets/\(ManualBackupCrypto.assetIdentifier(momentID: momentID, imageID: imageID)).enc"
    }

    static func isValidAssetPath(_ path: String) -> Bool {
        guard path.hasPrefix("assets/"), path.hasSuffix(".enc") else { return false }
        let name = path.dropFirst("assets/".count).dropLast(".enc".count)
        return name.count == 64 && name.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    private static func isAllowedPath(_ path: String) -> Bool {
        guard !path.isEmpty,
              !path.hasPrefix("/"),
              !path.contains("\\"),
              !path.contains("\0"),
              !path.split(separator: "/", omittingEmptySubsequences: false).contains("..")
        else {
            return false
        }
        return path == headerPath || path == contentPath || isValidAssetPath(path)
    }

    private func validate(header: ManualBackupHeader) throws {
        guard header.formatIdentifier == ManualBackupImportPolicy.formatIdentifier else {
            throw ManualBackupError.invalidFormat
        }
        guard header.schemaVersion == ManualBackupImportPolicy.currentSchemaVersion else {
            throw ManualBackupError.unsupportedVersion(header.schemaVersion)
        }
        guard header.algorithm == ManualBackupCrypto.algorithmIdentifier,
              header.keyDerivation == ManualBackupCrypto.keyDerivationIdentifier,
              header.iterations == ManualBackupCrypto.defaultPBKDF2Iterations,
              header.salt.count == ManualBackupCrypto.saltByteCount,
              header.appVersion?.utf8.count ?? 0 <= 128
        else {
            throw ManualBackupError.invalidFormat
        }
    }
}
