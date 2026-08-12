import Foundation

struct PairColorChoice: Identifiable, Hashable {
    let hex: String
    var id: String { hex }

    static let palette: [PairColorChoice] = [
        .init(hex: "#E5484D"),
        .init(hex: "#F97316"),
        .init(hex: "#F2C94C"),
        .init(hex: "#84CC16"),
        .init(hex: "#22C55E"),
        .init(hex: "#46C1B1"),
        .init(hex: "#38BDF8"),
        .init(hex: "#2F9CCF"),
        .init(hex: "#243979"),
        .init(hex: "#403CF8"),
        .init(hex: "#8B70F0"),
        .init(hex: "#D946EF"),
        .init(hex: "#FCA8D9"),
        .init(hex: "#F26767"),
        .init(hex: "#8B5E3C"),
        .init(hex: "#9CA3AF"),
        .init(hex: "#111827"),
        .init(hex: "#FFFFFF"),
    ]
}

struct PairEditorDraft: Equatable {
    var member1Name: String
    var member2Name: String
    var nickname: String
    var leadingColorHex: String
    var trailingColorHex: String
    var usesTrailingColor: Bool

    init(
        member1Name: String = "",
        member2Name: String = "",
        nickname: String = "",
        leadingColorHex: String = "#403CF8",
        trailingColorHex: String = "#FCA8D9",
        usesTrailingColor: Bool = true
    ) {
        self.member1Name = member1Name
        self.member2Name = member2Name
        self.nickname = nickname
        self.leadingColorHex = leadingColorHex
        self.trailingColorHex = trailingColorHex
        self.usesTrailingColor = usesTrailingColor
    }

    init(pair: PairSummary) {
        member1Name = pair.member1Name
        member2Name = pair.member2Name ?? ""
        nickname = pair.nickname
        leadingColorHex = pair.leadingColorHex
        trailingColorHex = pair.trailingColorHex ?? "#FCA8D9"
        usesTrailingColor = pair.trailingColorHex != nil
    }

    var normalizedMember1Name: String {
        PairTextPolicy.limitedMember(member1Name).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedMember2Name: String {
        PairTextPolicy.limitedMember(member2Name).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNickname: String {
        PairTextPolicy.limitedMember(nickname)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        PairDisplayNameFormatter.displayName(
            member1: normalizedMember1Name,
            member2: normalizedMember2Name.nilIfEmpty,
            nickname: normalizedNickname
        )
    }

    var memberDisplayName: String {
        PairDisplayNameFormatter.displayName(
            member1: normalizedMember1Name,
            member2: normalizedMember2Name.nilIfEmpty,
            nickname: ""
        )
    }

    var isValid: Bool { !normalizedMember1Name.isEmpty }

    func makeCreateRequest() -> PairCreateRequest? {
        guard isValid else { return nil }
        return PairCreateRequest(
            member1Name: normalizedMember1Name,
            member2Name: normalizedMember2Name.nilIfEmpty,
            nickname: normalizedNickname,
            leadingColorHex: leadingColorHex,
            trailingColorHex: usesTrailingColor ? trailingColorHex : nil
        )
    }

    func makeUpdateRequest() -> PairUpdateRequest? {
        guard isValid else { return nil }
        return PairUpdateRequest(
            member1Name: normalizedMember1Name,
            member2Name: normalizedMember2Name.nilIfEmpty,
            nickname: normalizedNickname,
            leadingColorHex: leadingColorHex,
            trailingColorHex: usesTrailingColor ? trailingColorHex : nil
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
