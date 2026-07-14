import Foundation

struct SourceSummary: Identifiable, Hashable {
    let id: String
    let displayName: String
    let helperText: String
    let mediaType: String
    let totalCount: Int?
    let isFavorite: Bool
}

protocol SourceRepository {
    func fetchSources() async throws -> [SourceSummary]
    func createSource(
        displayName: String,
        helperText: String,
        mediaType: String,
        totalCount: Int?,
        isFavorite: Bool
    ) async throws -> SourceSummary
}
