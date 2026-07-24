import Foundation

nonisolated struct MomentImage: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let relativeFileName: String
    let createdAt: Date
    let order: Int
    let pixelWidth: Int
    let pixelHeight: Int
}

nonisolated struct MomentImageChangeSet: Sendable {
    nonisolated struct Addition: Sendable {
        let id: String
        let data: Data
        let createdAt: Date
    }

    let retainedImageIDs: [String]
    let additions: [Addition]

}

nonisolated enum MomentImageRepositoryError: Error, Equatable {
    case invalidImage
    case limitExceeded
    case imageNotFound
    case storageUnavailable
}
