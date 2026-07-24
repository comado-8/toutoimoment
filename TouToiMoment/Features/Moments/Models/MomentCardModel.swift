import SwiftUI

enum MomentFace: String, CaseIterable, Hashable {
    case scene
    case heart

    mutating func toggle() {
        self = self == .scene ? .heart : .scene
    }
}

struct MomentCardModel: Identifiable {
    struct ContextValue: Hashable, Identifiable {
        let key: String
        let value: String

        var id: String { key }
    }

    let id: String
    let sceneText: String
    let heartText: String
    let caption: String
    let pairID: String?
    let pairName: String
    let sourceID: String?
    let sourceName: String
    let mediaType: String?
    let contextValues: [ContextValue]
    let reactionIDs: [String]
    let reactionLabels: [String]
    var images: [MomentImage] = []
    let leadingDotColor: Color
    let trailingDotColor: Color
    let createdAt: Date
    var isFavorite: Bool

    var episodeLabel: String {
        MomentContextDisplayFormatter.cardLabel(for: self) ?? "—"
    }

    var glowPaletteIndex: Int {
        MomentGlowPalette.index(for: id)
    }

    var searchableText: String {
        ([
            sceneText,
            heartText,
            caption,
            episodeLabel,
            pairName,
            sourceName,
            MomentContextDisplayFormatter.compactSummary(for: self)
        ] + reactionLabels)
            .joined(separator: " ")
    }
}

enum MomentGlowPalette {
    static let count = 6

    static func index(for stableID: String) -> Int {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in stableID.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return Int(hash % UInt64(count))
    }
}

extension MomentCardModel {
    static let preview: [MomentCardModel] = [
        MomentCardModel(
            id: "moment-school-trip-ep3-scene-1",
            sceneText: "待ってるよ。\nあの場所で。",
            heartText: "目から汗止まらん",
            caption: "修学旅行で仲良くないグループに...",
            pairID: "pair-aoi-rin",
            pairName: "葵 ・ 凛",
            sourceID: "source-school-trip",
            sourceName: "修学旅行で仲良くないグループに...",
            mediaType: "anime",
            contextValues: animeContext(episode: "3", timestamp: "00:18:42"),
            reactionIDs: ["emotional.naita"],
            reactionLabels: ["😭 泣いた"],
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            createdAt: previewDate,
            isFavorite: true
        ),
        MomentCardModel(
            id: "moment-school-trip-ep3-scene-2",
            sceneText: "君、昨日の子だよね？",
            heartText: "目が合った瞬間、胸が\nぎゅってなった。",
            caption: "修学旅行で仲良くないグループに...",
            pairID: "pair-aoi-rin",
            pairName: "葵 ・ 凛",
            sourceID: "source-school-trip",
            sourceName: "修学旅行で仲良くないグループに...",
            mediaType: "anime",
            contextValues: animeContext(episode: "3", timestamp: "00:21:05"),
            reactionIDs: ["positive.kyun"],
            reactionLabels: ["🥰 キュン"],
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            createdAt: previewDate,
            isFavorite: true
        ),
        MomentCardModel(
            id: "moment-school-trip-ep6-scene-1",
            sceneText: "I'll be waiting.\nAt that place.",
            heartText: "I felt my heart\npounding when our\neyes met.",
            caption: "修学旅行で仲良くないグループに...",
            pairID: "pair-aoi-rin",
            pairName: "葵 ・ 凛",
            sourceID: "source-school-trip",
            sourceName: "修学旅行で仲良くないグループに...",
            mediaType: "anime",
            contextValues: animeContext(episode: "6", timestamp: "00:14:22"),
            reactionIDs: ["positive.kyun"],
            reactionLabels: ["🥰 キュン"],
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            createdAt: previewDate,
            isFavorite: true
        ),
        MomentCardModel(
            id: "moment-school-trip-ep6-scene-2",
            sceneText: "You're the one from\nyesterday, right?",
            heartText: "I can't stop the\nsweat pouring from\nmy eyes.",
            caption: "修学旅行で仲良くないグループに...",
            pairID: "pair-kei-yu",
            pairName: "慧 ・ 悠",
            sourceID: "source-school-trip",
            sourceName: "修学旅行で仲良くないグループに...",
            mediaType: "anime",
            contextValues: animeContext(episode: "6", timestamp: "00:32:18"),
            reactionIDs: ["emotional.naita"],
            reactionLabels: ["😭 泣いた"],
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            createdAt: previewDate,
            isFavorite: false
        ),
        MomentCardModel(
            id: "moment-drama-ep8",
            sceneText: "アイツ、めっちゃ見て\nくる…なに……？",
            heartText: "待って、突然の射撃は\n心臓に悪い",
            caption: "視線の先にいたのは...",
            pairID: "pair-kei-yu",
            pairName: "慧 ・ 悠",
            sourceID: "source-summer-drama",
            sourceName: "真夏のドラマ",
            mediaType: "tv_drama",
            contextValues: [
                .init(key: "episode", value: "第8話"),
                .init(key: "timestamp", value: "00:26:40")
            ],
            reactionIDs: ["excited.shougeki"],
            reactionLabels: ["🤯 衝撃"],
            leadingDotColor: Color(hex: "#8B91F4"),
            trailingDotColor: Color(hex: "#F18AB8"),
            createdAt: previewDate,
            isFavorite: true
        ),
        MomentCardModel(
            id: "moment-live-ep10",
            sceneText: "Toutoi瞬間を記録しよう\n＋ Add your Moment",
            heartText: "Toutoi瞬間の気持ちを残そう\n＋ Add your feelings",
            caption: "ステージの最後に...",
            pairID: "pair-sora-haru",
            pairName: "空 ・ 春",
            sourceID: "source-live",
            sourceName: "Anniversary Live",
            mediaType: "live_concert",
            contextValues: [.init(key: "position", value: "ステージの最後")],
            reactionIDs: ["excited.saikou"],
            reactionLabels: ["💥 最高"],
            leadingDotColor: Color(hex: "#7BC8C5"),
            trailingDotColor: Color(hex: "#F18484"),
            createdAt: previewDate,
            isFavorite: false
        )
    ]

    private static let previewDate = Date(timeIntervalSince1970: 1_769_040_000)

    private static func animeContext(episode: String, timestamp: String) -> [ContextValue] {
        [
            .init(key: "episode", value: episode),
            .init(key: "timestamp", value: timestamp)
        ]
    }
}
