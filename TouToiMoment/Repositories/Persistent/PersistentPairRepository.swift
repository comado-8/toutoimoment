import Foundation
import SwiftData

@MainActor
final class PersistentPairRepository: PairRepository {
    private let context: ModelContext
    private var pairs: [PairSummary]

    init(context: ModelContext, moments: [MomentCardModel]) throws {
        self.context = context
        if let state = try context.fetch(FetchDescriptor<PersistedPairState>()).first {
            pairs = try JSONDecoder().decode([PairSummary].self, from: state.payload)
        } else {
            pairs = Self.initialPairs(from: moments)
            try persist()
        }
    }

    func fetchPairs() async throws -> [PairSummary] { pairs }

    func createPair(request: PairCreateRequest) async throws -> PairSummary {
        let values = try validatedValues(
            member1Name: request.member1Name,
            member2Name: request.member2Name,
            nickname: request.nickname,
            leadingColorHex: request.leadingColorHex,
            trailingColorHex: request.trailingColorHex
        )
        guard !containsPair(member1: values.member1Name, member2: values.member2Name) else {
            throw PairRepositoryError.duplicatePair
        }
        let pair = PairSummary(
            id: UUID().uuidString,
            member1Name: values.member1Name,
            member2Name: values.member2Name,
            nickname: values.nickname,
            momentCount: 0,
            leadingColorHex: values.leadingColorHex,
            trailingColorHex: values.trailingColorHex,
            isFavorite: false
        )
        pairs.insert(pair, at: 0)
        try persist()
        return pair
    }

    func updatePair(id: String, request: PairUpdateRequest) async throws -> PairSummary {
        guard let index = pairs.firstIndex(where: { $0.id == id }) else {
            throw PairRepositoryError.pairNotFound
        }
        let values = try validatedValues(
            member1Name: request.member1Name,
            member2Name: request.member2Name,
            nickname: request.nickname,
            leadingColorHex: request.leadingColorHex,
            trailingColorHex: request.trailingColorHex
        )
        guard !containsPair(
            member1: values.member1Name,
            member2: values.member2Name,
            excluding: id
        ) else {
            throw PairRepositoryError.duplicatePair
        }
        let existing = pairs[index]
        let updated = PairSummary(
            id: existing.id,
            member1Name: values.member1Name,
            member2Name: values.member2Name,
            nickname: values.nickname,
            momentCount: existing.momentCount,
            leadingColorHex: values.leadingColorHex,
            trailingColorHex: values.trailingColorHex,
            isFavorite: existing.isFavorite
        )
        pairs[index] = updated
        try persist()
        return updated
    }

    func deletePair(id: String) async throws {
        guard let index = pairs.firstIndex(where: { $0.id == id }) else {
            throw PairRepositoryError.pairNotFound
        }
        pairs.remove(at: index)
        try persist()
    }

    func toggleFavorite(id: String) async throws {
        guard let index = pairs.firstIndex(where: { $0.id == id }) else {
            throw PairRepositoryError.pairNotFound
        }
        let pair = pairs[index]
        pairs[index] = Self.copy(pair, isFavorite: !pair.isFavorite)
        try persist()
    }

    func synchronizeMomentCounts(_ counts: [String: Int]) async throws {
        let updated = pairs.map { Self.copy($0, momentCount: counts[$0.id, default: 0]) }
        guard updated != pairs else { return }
        pairs = updated
        try persist()
    }

    func deleteAllPairs() async throws {
        pairs.removeAll()
        try persist()
    }

    func reloadFromPersistence() throws {
        guard let state = try context.fetch(FetchDescriptor<PersistedPairState>()).first else {
            throw PairRepositoryError.invalidPair
        }
        pairs = try JSONDecoder().decode([PairSummary].self, from: state.payload)
    }

    private func persist() throws {
        let payload = try JSONEncoder().encode(pairs)
        if let state = try context.fetch(FetchDescriptor<PersistedPairState>()).first {
            state.schemaVersion = 1
            state.payload = payload
        } else {
            context.insert(PersistedPairState(payload: payload))
        }
        try context.save()
    }

    private func validatedValues(
        member1Name: String,
        member2Name: String?,
        nickname: String,
        leadingColorHex: String,
        trailingColorHex: String?
    ) throws -> (
        member1Name: String,
        member2Name: String?,
        nickname: String,
        leadingColorHex: String,
        trailingColorHex: String?
    ) {
        let normalizedMember1 = PairTextPolicy.limitedMember(member1Name)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMember2 = member2Name.map {
            PairTextPolicy.limitedMember($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }.flatMap { $0.isEmpty ? nil : $0 }
        let normalizedNickname = PairTextPolicy.limitedMember(nickname)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLeading = leadingColorHex.uppercased()
        let normalizedTrailing = trailingColorHex?.uppercased()
        guard !normalizedMember1.isEmpty,
              ManualBackupImportPolicy.isValidHexColor(normalizedLeading),
              normalizedTrailing.map(ManualBackupImportPolicy.isValidHexColor) ?? true
        else { throw PairRepositoryError.invalidPair }
        return (
            normalizedMember1,
            normalizedMember2,
            normalizedNickname,
            normalizedLeading,
            normalizedTrailing
        )
    }

    private func containsPair(
        member1: String,
        member2: String?,
        excluding id: String? = nil
    ) -> Bool {
        pairs.contains {
            $0.id != id
                && isSameName($0.member1Name, member1)
                && optionalNamesMatch($0.member2Name, member2)
        }
    }

    private func isSameName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(
            rhs,
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        ) == .orderedSame
    }

    private func optionalNamesMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): isSameName(lhs, rhs)
        default: false
        }
    }

    private static func initialPairs(from moments: [MomentCardModel]) -> [PairSummary] {
        var result = InMemoryPairRepository.fixturePairs
        let grouped = Dictionary(grouping: moments.compactMap { moment -> MomentCardModel? in
            moment.pairID == nil ? nil : moment
        }, by: { $0.pairID! })
        for (id, matching) in grouped {
            let first = matching[0]
            let memberNames = first.pairMemberNames
            let snapshot = PairSummary(
                id: id,
                member1Name: memberNames.first ?? first.pairName,
                member2Name: memberNames.dropFirst().first,
                nickname: memberNames.isEmpty ? "" : first.pairName,
                momentCount: matching.count,
                leadingColorHex: PersistedMomentSnapshot.hex(first.leadingDotColor),
                trailingColorHex: PersistedMomentSnapshot.hex(first.trailingDotColor),
                isFavorite: false
            )
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = copy(result[index], momentCount: matching.count)
            } else {
                result.append(snapshot)
            }
        }
        return result
    }

    private static func copy(
        _ pair: PairSummary,
        momentCount: Int? = nil,
        isFavorite: Bool? = nil
    ) -> PairSummary {
        PairSummary(
            id: pair.id,
            member1Name: pair.member1Name,
            member2Name: pair.member2Name,
            nickname: pair.nickname,
            momentCount: momentCount ?? pair.momentCount,
            leadingColorHex: pair.leadingColorHex,
            trailingColorHex: pair.trailingColorHex,
            isFavorite: isFavorite ?? pair.isFavorite
        )
    }
}
