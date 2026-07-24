import Foundation
import ImageIO
import UniformTypeIdentifiers

actor LocalMomentImageRepository: MomentImageRepository {
    nonisolated static let maximumImageCount = 3
    nonisolated static let maximumPixelDimension = 2_048

    private nonisolated struct Manifest: Codable {
        let images: [MomentImage]
    }

    private nonisolated struct PreparedImage {
        let data: Data
        let fileExtension: String
        let width: Int
        let height: Int
    }

    private let fileManager: FileManager
    private let rootURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        rootURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        self.rootURL = rootURL ?? Self.defaultRootURL(fileManager: fileManager)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func images(for momentID: String) async throws -> [MomentImage] {
        try loadManifest(for: momentID).images.sorted { $0.order < $1.order }
    }

    func imageData(for image: MomentImage, momentID: String) async throws -> Data {
        let url = directoryURL(for: momentID).appendingPathComponent(image.relativeFileName)
        guard fileManager.fileExists(atPath: url.path) else {
            throw MomentImageRepositoryError.imageNotFound
        }
        return try Data(contentsOf: url, options: [.mappedIfSafe])
    }

    func addImage(
        data: Data,
        id: String,
        createdAt: Date,
        to momentID: String
    ) async throws -> [MomentImage] {
        let current = try loadManifest(for: momentID).images.sorted { $0.order < $1.order }
        guard current.count < Self.maximumImageCount else {
            throw MomentImageRepositoryError.limitExceeded
        }
        return try rewriteDirectory(
            momentID: momentID,
            retainedImages: current,
            additions: [.init(id: id, data: data, createdAt: createdAt)]
        )
    }

    func removeImage(id: String, from momentID: String) async throws -> [MomentImage] {
        let current = try loadManifest(for: momentID).images.sorted { $0.order < $1.order }
        guard current.contains(where: { $0.id == id }) else {
            throw MomentImageRepositoryError.imageNotFound
        }
        return try rewriteDirectory(
            momentID: momentID,
            retainedImages: current.filter { $0.id != id },
            additions: []
        )
    }

    func commit(
        _ changes: MomentImageChangeSet,
        for momentID: String
    ) async throws -> [MomentImage] {
        let current = try loadManifest(for: momentID).images.sorted { $0.order < $1.order }
        let currentByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        let retained = changes.retainedImageIDs.compactMap { currentByID[$0] }
        guard retained.count + changes.additions.count <= Self.maximumImageCount else {
            throw MomentImageRepositoryError.limitExceeded
        }
        return try rewriteDirectory(
            momentID: momentID,
            retainedImages: retained,
            additions: changes.additions
        )
    }

    func deleteImages(for momentID: String) async throws {
        let directory = directoryURL(for: momentID)
        guard fileManager.fileExists(atPath: directory.path) else { return }
        try fileManager.removeItem(at: directory)
    }

    func removeOrphans(validMomentIDs: Set<String>) async throws {
        try createRootIfNeeded()
        let validDirectoryNames = Set(validMomentIDs.map(directoryName(for:)))
        let urls = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )
        for url in urls where !validDirectoryNames.contains(url.lastPathComponent) {
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
                continue
            }
            try fileManager.removeItem(at: url)
        }
    }

    private func rewriteDirectory(
        momentID: String,
        retainedImages: [MomentImage],
        additions: [MomentImageChangeSet.Addition]
    ) throws -> [MomentImage] {
        guard retainedImages.count + additions.count <= Self.maximumImageCount else {
            throw MomentImageRepositoryError.limitExceeded
        }

        try createRootIfNeeded()
        let target = directoryURL(for: momentID)
        let transaction = rootURL.appendingPathComponent(
            ".transaction-\(UUID().uuidString)",
            isDirectory: true
        )
        let backup = rootURL.appendingPathComponent(
            ".backup-\(UUID().uuidString)",
            isDirectory: true
        )
        try fileManager.createDirectory(at: transaction, withIntermediateDirectories: true)

        do {
            var result: [MomentImage] = []
            for (index, image) in retainedImages.enumerated() {
                let source = target.appendingPathComponent(image.relativeFileName)
                guard fileManager.fileExists(atPath: source.path) else {
                    throw MomentImageRepositoryError.imageNotFound
                }
                let destination = transaction.appendingPathComponent(image.relativeFileName)
                try fileManager.copyItem(at: source, to: destination)
                result.append(
                    MomentImage(
                        id: image.id,
                        relativeFileName: image.relativeFileName,
                        createdAt: image.createdAt,
                        order: index,
                        pixelWidth: image.pixelWidth,
                        pixelHeight: image.pixelHeight
                    )
                )
            }

            for addition in additions {
                let prepared = try Self.prepareImage(addition.data)
                let fileName = "\(addition.id).\(prepared.fileExtension)"
                try prepared.data.write(
                    to: transaction.appendingPathComponent(fileName),
                    options: [.atomic]
                )
                result.append(
                    MomentImage(
                        id: addition.id,
                        relativeFileName: fileName,
                        createdAt: addition.createdAt,
                        order: result.count,
                        pixelWidth: prepared.width,
                        pixelHeight: prepared.height
                    )
                )
            }

            let manifest = try encoder.encode(Manifest(images: result))
            try manifest.write(
                to: transaction.appendingPathComponent("manifest.json"),
                options: [.atomic]
            )
            try applyFileProtection(to: transaction)

            if fileManager.fileExists(atPath: target.path) {
                try fileManager.moveItem(at: target, to: backup)
            }
            do {
                try fileManager.moveItem(at: transaction, to: target)
            } catch {
                if !fileManager.fileExists(atPath: target.path),
                   fileManager.fileExists(atPath: backup.path) {
                    try? fileManager.moveItem(at: backup, to: target)
                }
                throw error
            }
            if fileManager.fileExists(atPath: backup.path) {
                try? fileManager.removeItem(at: backup)
            }
            return result
        } catch {
            try? fileManager.removeItem(at: transaction)
            try? fileManager.removeItem(at: backup)
            throw error
        }
    }

    private func loadManifest(for momentID: String) throws -> Manifest {
        let url = directoryURL(for: momentID).appendingPathComponent("manifest.json")
        guard fileManager.fileExists(atPath: url.path) else {
            return Manifest(images: [])
        }
        do {
            return try decoder.decode(Manifest.self, from: Data(contentsOf: url))
        } catch {
            throw MomentImageRepositoryError.storageUnavailable
        }
    }

    private func createRootIfNeeded() throws {
        do {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
            try applyFileProtection(to: rootURL)
        } catch {
            throw MomentImageRepositoryError.storageUnavailable
        }
    }

    private func applyFileProtection(to directory: URL) throws {
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directory.path
        )
        let contents = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        for url in contents {
            try? fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
        }
    }

    private func directoryURL(for momentID: String) -> URL {
        rootURL.appendingPathComponent(directoryName(for: momentID), isDirectory: true)
    }

    private func directoryName(for momentID: String) -> String {
        Data(momentID.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func defaultRootURL(fileManager: FileManager) -> URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
        return applicationSupport
            .appendingPathComponent("TouToiMoment", isDirectory: true)
            .appendingPathComponent("MomentImages", isDirectory: true)
    }

    private static func prepareImage(_ data: Data) throws -> PreparedImage {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension,
                    kCGImageSourceShouldCacheImmediately: true
                ] as CFDictionary
            )
        else {
            throw MomentImageRepositoryError.invalidImage
        }

        let destinationData = NSMutableData()
        let heicType = UTType.heic.identifier as CFString
        let jpegType = UTType.jpeg.identifier as CFString
        let supportedTypes = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        let outputType = supportedTypes.contains(UTType.heic.identifier) ? heicType : jpegType
        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            outputType,
            1,
            nil
        ) else {
            throw MomentImageRepositoryError.invalidImage
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            throw MomentImageRepositoryError.invalidImage
        }
        return PreparedImage(
            data: destinationData as Data,
            fileExtension: outputType == heicType ? "heic" : "jpg",
            width: image.width,
            height: image.height
        )
    }
}
