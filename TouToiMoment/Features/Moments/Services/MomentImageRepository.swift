import Foundation

nonisolated protocol MomentImageRepository: Sendable {
    func images(for momentID: String) async throws -> [MomentImage]
    func imageData(for image: MomentImage, momentID: String) async throws -> Data
    func addImage(
        data: Data,
        id: String,
        createdAt: Date,
        to momentID: String
    ) async throws -> [MomentImage]
    func removeImage(id: String, from momentID: String) async throws -> [MomentImage]
    func commit(
        _ changes: MomentImageChangeSet,
        for momentID: String
    ) async throws -> [MomentImage]
    func deleteImages(for momentID: String) async throws
    func removeOrphans(validMomentIDs: Set<String>) async throws
}
