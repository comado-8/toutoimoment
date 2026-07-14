import Foundation

struct PairSummary: Identifiable, Hashable {
    let id: String
    let displayName: String
    let nickname: String
    let momentCount: Int
    let leadingColorHex: String
    let trailingColorHex: String?
    let isFavorite: Bool
}

protocol PairRepository {
    func fetchPairs() async throws -> [PairSummary]
}
