import SwiftUI

enum PairListFilter: String, CaseIterable, Identifiable {
    case all
    case favorite

    var id: Self { self }
}

struct PairListCardModel: Identifiable {
    let id: String
    let displayName: String
    let nickname: String
    let momentCount: Int
    let leadingColor: Color
    let trailingColor: Color?
    var isFavorite: Bool
}

enum PairListPreviewData {
    static let pairs: [PairListCardModel] = [
        PairListCardModel(
            id: "kirito-asuna",
            displayName: "Kirito ・ Asuna",
            nickname: "きりあす",
            momentCount: 12,
            leadingColor: Color(hex: "#243979"),
            trailingColor: Color(hex: "#D3522E"),
            isFavorite: false
        ),
        PairListCardModel(
            id: "yuri-pik",
            displayName: "Yuri ・ Pik",
            nickname: "ゆりぴく",
            momentCount: 12,
            leadingColor: Color(hex: "#F375AA"),
            trailingColor: Color(hex: "#417CB3"),
            isFavorite: true
        ),
        PairListCardModel(
            id: "roi-yoru",
            displayName: "Roi ・ Yoru",
            nickname: "ロイヨル",
            momentCount: 12,
            leadingColor: Color(hex: "#C9A30F"),
            trailingColor: Color(hex: "#A8241E"),
            isFavorite: false
        ),
        PairListCardModel(
            id: "nakam-gio",
            displayName: "Nakam ・ Gio",
            nickname: "ナカギオ",
            momentCount: 12,
            leadingColor: Color(hex: "#2F9CCF"),
            trailingColor: Color(hex: "#6C3DB0"),
            isFavorite: false
        )
    ]
}
