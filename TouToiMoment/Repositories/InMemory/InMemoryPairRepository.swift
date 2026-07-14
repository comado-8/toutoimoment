import Foundation

struct InMemoryPairRepository: PairRepository {
    func fetchPairs() async throws -> [PairSummary] {
        [
            PairSummary(
                id: "kirito-asuna",
                displayName: "Kirito ･ Asuna",
                nickname: "きりあす",
                momentCount: 12,
                leadingColorHex: "#243979",
                trailingColorHex: "#D3522E",
                isFavorite: false
            ),
            PairSummary(
                id: "yuri-pik",
                displayName: "Yuri ･ Pik",
                nickname: "ゆりぴく",
                momentCount: 12,
                leadingColorHex: "#F375AA",
                trailingColorHex: "#417CB3",
                isFavorite: true
            ),
            PairSummary(
                id: "roi-yoru",
                displayName: "Roi ･ Yoru",
                nickname: "ロイヨル",
                momentCount: 9,
                leadingColorHex: "#C9A30F",
                trailingColorHex: "#A8241E",
                isFavorite: false
            ),
            PairSummary(
                id: "nakam-gio",
                displayName: "Nakam ･ Gio",
                nickname: "ナカギオ",
                momentCount: 7,
                leadingColorHex: "#2F9CCF",
                trailingColorHex: "#6C3DB0",
                isFavorite: false
            ),
            PairSummary(
                id: "gojo-geto",
                displayName: "Gojo ･ Geto",
                nickname: "五夏",
                momentCount: 19,
                leadingColorHex: "#6E5AE6",
                trailingColorHex: "#93D7FF",
                isFavorite: true
            ),
            PairSummary(
                id: "rin-haru",
                displayName: "Rin ･ Haru",
                nickname: "りんはる",
                momentCount: 6,
                leadingColorHex: "#48C2B0",
                trailingColorHex: "#F46B80",
                isFavorite: false
            ),
        ]
    }
}
