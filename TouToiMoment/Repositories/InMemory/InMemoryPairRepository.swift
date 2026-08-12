import Foundation

struct InMemoryPairRepository: PairRepository {
    func fetchPairs() async throws -> [PairSummary] {
        Self.fixturePairs
    }

    static let fixturePairs: [PairSummary] = [
            PairSummary(
                id: "kirito-asuna",
                member1Name: "Kirito",
                member2Name: "Asuna",
                nickname: "きりあす",
                momentCount: 12,
                leadingColorHex: "#243979",
                trailingColorHex: "#D3522E",
                isFavorite: false
            ),
            PairSummary(
                id: "yuri-pik",
                member1Name: "Yuri",
                member2Name: "Pik",
                nickname: "ゆりぴく",
                momentCount: 12,
                leadingColorHex: "#F375AA",
                trailingColorHex: "#417CB3",
                isFavorite: true
            ),
            PairSummary(
                id: "roi-yoru",
                member1Name: "Roi",
                member2Name: "Yoru",
                nickname: "ロイヨル",
                momentCount: 9,
                leadingColorHex: "#C9A30F",
                trailingColorHex: "#A8241E",
                isFavorite: false
            ),
            PairSummary(
                id: "nakam-gio",
                member1Name: "Nakam",
                member2Name: "Gio",
                nickname: "ナカギオ",
                momentCount: 7,
                leadingColorHex: "#2F9CCF",
                trailingColorHex: "#6C3DB0",
                isFavorite: false
            ),
            PairSummary(
                id: "gojo-geto",
                member1Name: "Gojo",
                member2Name: "Geto",
                nickname: "五夏",
                momentCount: 19,
                leadingColorHex: "#6E5AE6",
                trailingColorHex: "#93D7FF",
                isFavorite: true
            ),
            PairSummary(
                id: "rin-haru",
                member1Name: "Rin",
                member2Name: "Haru",
                nickname: "りんはる",
                momentCount: 6,
                leadingColorHex: "#48C2B0",
                trailingColorHex: "#F46B80",
                isFavorite: false
            ),
    ]
}
