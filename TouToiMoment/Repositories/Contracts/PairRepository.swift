import Foundation

struct PairSummary: Identifiable, Hashable, Codable {
    let id: String
    let member1Name: String
    let member2Name: String?
    let nickname: String
    let momentCount: Int
    let leadingColorHex: String
    let trailingColorHex: String?
    let isFavorite: Bool

    var memberDisplayName: String {
        PairDisplayNameFormatter.displayName(
            member1: member1Name,
            member2: member2Name,
            nickname: ""
        )
    }

    var displayName: String {
        PairDisplayNameFormatter.displayName(
            member1: member1Name,
            member2: member2Name,
            nickname: nickname
        )
    }

    var subtitle: String { nickname.isEmpty ? "" : memberDisplayName }

    init(
        id: String,
        member1Name: String,
        member2Name: String?,
        nickname: String,
        momentCount: Int,
        leadingColorHex: String,
        trailingColorHex: String?,
        isFavorite: Bool
    ) {
        self.id = id
        self.member1Name = member1Name
        self.member2Name = member2Name
        self.nickname = nickname
        self.momentCount = momentCount
        self.leadingColorHex = leadingColorHex
        self.trailingColorHex = trailingColorHex
        self.isFavorite = isFavorite
    }

    private enum CodingKeys: String, CodingKey {
        case id, member1Name, member2Name, displayName, nickname, momentCount
        case leadingColorHex, trailingColorHex, isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        momentCount = try container.decode(Int.self, forKey: .momentCount)
        leadingColorHex = try container.decode(String.self, forKey: .leadingColorHex)
        trailingColorHex = try container.decodeIfPresent(String.self, forKey: .trailingColorHex)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)

        if let member1 = try container.decodeIfPresent(String.self, forKey: .member1Name) {
            member1Name = member1
            member2Name = try container.decodeIfPresent(String.self, forKey: .member2Name)
        } else {
            let legacyName = try container.decode(String.self, forKey: .displayName)
            (member1Name, member2Name) = PairDisplayNameFormatter.members(
                fromLegacyDisplayName: legacyName
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(member1Name, forKey: .member1Name)
        try container.encodeIfPresent(member2Name, forKey: .member2Name)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(momentCount, forKey: .momentCount)
        try container.encode(leadingColorHex, forKey: .leadingColorHex)
        try container.encodeIfPresent(trailingColorHex, forKey: .trailingColorHex)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
}

struct PairCreateRequest: Hashable {
    let member1Name: String
    let member2Name: String?
    let nickname: String
    let leadingColorHex: String
    let trailingColorHex: String?
}

struct PairUpdateRequest: Hashable {
    let member1Name: String
    let member2Name: String?
    let nickname: String
    let leadingColorHex: String
    let trailingColorHex: String?
}

protocol PairRepository {
    func fetchPairs() async throws -> [PairSummary]
    func createPair(request: PairCreateRequest) async throws -> PairSummary
    func updatePair(id: String, request: PairUpdateRequest) async throws -> PairSummary
    func deletePair(id: String) async throws
    func toggleFavorite(id: String) async throws
    func synchronizeMomentCounts(_ counts: [String: Int]) async throws
    func deleteAllPairs() async throws
    func reloadFromPersistence() throws
}

extension PairRepository {
    func createPair(request: PairCreateRequest) async throws -> PairSummary {
        throw PairRepositoryError.unsupported
    }
    func updatePair(id: String, request: PairUpdateRequest) async throws -> PairSummary {
        throw PairRepositoryError.unsupported
    }
    func deletePair(id: String) async throws { throw PairRepositoryError.unsupported }
    func toggleFavorite(id: String) async throws { throw PairRepositoryError.unsupported }
    func synchronizeMomentCounts(_ counts: [String: Int]) async throws {}
    func deleteAllPairs() async throws {}
    func reloadFromPersistence() throws {}
}

enum PairRepositoryError: Error, Equatable {
    case invalidPair
    case duplicatePair
    case pairNotFound
    case unsupported
}
