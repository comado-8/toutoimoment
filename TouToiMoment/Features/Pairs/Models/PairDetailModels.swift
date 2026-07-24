import SwiftUI

private enum PairColorDefaults {
    static let leading = Color.appPrimary
    static let trailing = Color.appAccent
}

struct PairDetailModel: Identifiable {
    let id: String
    let displayName: String
    let titleLabel: String
    let momentCount: Int
    let lastLabel: String
    let sinceLabel: String
    let leadingColor: Color
    let trailingColor: Color
    var isFavorite: Bool
    var recentMoments: [PairDetailMomentModel]
}

struct PairDetailMomentModel: Identifiable {
    let id: String
    let sourceTitle: String
    let episodeLabel: String
    let timestampLabel: String
    let quote: String
    var isFavorite: Bool
}

enum PairDetailPreviewData {
    static func detail(for pairID: String) -> PairDetailModel {
        details[pairID] ?? defaultDetail
    }

    private static let details: [String: PairDetailModel] = [
        "kirito-asuna": makeDetail(
            pairID: "kirito-asuna",
            titleLabel: "Sword Art Online",
            momentCount: 14,
            lastLabel: "2d ago",
            sinceLabel: "Jan '24",
            isFavorite: false
        ),
        "yuri-pik": makeDetail(
            pairID: "yuri-pik",
            titleLabel: "Yuri on Ice",
            momentCount: 12,
            lastLabel: "4d ago",
            sinceLabel: "Mar '24",
            isFavorite: true
        ),
        "roi-yoru": makeDetail(
            pairID: "roi-yoru",
            titleLabel: "Spy x Family",
            momentCount: 12,
            lastLabel: "1w ago",
            sinceLabel: "Feb '24",
            isFavorite: false
        ),
        "nakam-gio": makeDetail(
            pairID: "nakam-gio",
            titleLabel: "Blue Lock",
            momentCount: 12,
            lastLabel: "3d ago",
            sinceLabel: "Apr '24",
            isFavorite: false
        )
    ]

    private static let recentMoments: [PairDetailMomentModel] = [
        PairDetailMomentModel(
            id: "moment-1",
            sourceTitle: "作品名",
            episodeLabel: "EP.03",
            timestampLabel: "18:42",
            quote: "目が合った瞬間。胸がぎゅってなった。",
            isFavorite: true
        ),
        PairDetailMomentModel(
            id: "moment-2",
            sourceTitle: "作品名",
            episodeLabel: "EP.03",
            timestampLabel: "18:42",
            quote: "目が合った瞬間。胸がぎゅってなった。",
            isFavorite: false
        ),
        PairDetailMomentModel(
            id: "moment-3",
            sourceTitle: "作品名",
            episodeLabel: "EP.03",
            timestampLabel: "18:42",
            quote: "目が合った瞬間。胸がぎゅってなった。",
            isFavorite: false
        ),
        PairDetailMomentModel(
            id: "moment-4",
            sourceTitle: "作品名",
            episodeLabel: "EP.03",
            timestampLabel: "18:42",
            quote: "目が合った瞬間。胸がぎゅってなった。",
            isFavorite: false
        ),
        PairDetailMomentModel(
            id: "moment-5",
            sourceTitle: "作品名",
            episodeLabel: "EP.03",
            timestampLabel: "18:42",
            quote: "目が合った瞬間。胸がぎゅってなった。",
            isFavorite: false
        )
    ]

    private static let defaultDetail = PairDetailModel(
        id: "kirito-asuna",
        displayName: "Kirito ・ Asuna",
        titleLabel: "Sword Art Online",
        momentCount: 14,
        lastLabel: "2d ago",
        sinceLabel: "Jan '24",
        leadingColor: PairColorDefaults.leading,
        trailingColor: PairColorDefaults.trailing,
        isFavorite: false,
        recentMoments: recentMoments
    )

    private static func makeDetail(
        pairID: String,
        titleLabel: String,
        momentCount: Int,
        lastLabel: String,
        sinceLabel: String,
        isFavorite: Bool
    ) -> PairDetailModel {
        let pairCard = PairListPreviewData.pairs.first(where: { $0.id == pairID })

        return PairDetailModel(
            id: pairID,
            displayName: pairCard?.displayName ?? "Pair",
            titleLabel: titleLabel,
            momentCount: momentCount,
            lastLabel: lastLabel,
            sinceLabel: sinceLabel,
            leadingColor: pairCard?.leadingColor ?? PairColorDefaults.leading,
            trailingColor: pairCard?.trailingColor ?? PairColorDefaults.trailing,
            isFavorite: isFavorite,
            recentMoments: recentMoments
        )
    }
}
