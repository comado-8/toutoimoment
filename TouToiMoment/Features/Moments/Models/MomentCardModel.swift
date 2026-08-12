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
    let title: String?
    let sceneText: String
    let heartText: String
    let caption: String
    var pairID: String?
    var pairName: String
    var pairMemberNames: [String]
    var sourceID: String?
    var sourceName: String
    var mediaType: String?
    var episodeID: String? = nil
    var episodeLocatorValues: [LocatorValue] = []
    let contextValues: [ContextValue]
    let reactionIDs: [String]
    let reactionLabels: [String]
    var images: [MomentImage] = []
    var leadingDotColor: Color
    var trailingDotColor: Color
    var momentDate: MomentDate
    let createdAt: Date
    var isFavorite: Bool

    init(
        id: String,
        title: String? = nil,
        sceneText: String,
        heartText: String,
        caption: String,
        pairID: String?,
        pairName: String,
        pairMemberNames: [String] = [],
        sourceID: String?,
        sourceName: String,
        mediaType: String?,
        episodeID: String? = nil,
        episodeLocatorValues: [LocatorValue] = [],
        contextValues: [ContextValue],
        reactionIDs: [String],
        reactionLabels: [String],
        images: [MomentImage] = [],
        leadingDotColor: Color,
        trailingDotColor: Color,
        momentDate: MomentDate? = nil,
        createdAt: Date,
        isFavorite: Bool
    ) {
        self.id = id
        self.title = MomentTitlePolicy.normalized(title)
        self.sceneText = sceneText
        self.heartText = heartText
        self.caption = caption
        self.pairID = pairID
        self.pairName = pairName
        self.pairMemberNames = pairMemberNames
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.mediaType = mediaType
        self.episodeID = episodeID
        self.episodeLocatorValues = episodeLocatorValues
        self.contextValues = contextValues
        self.reactionIDs = reactionIDs
        self.reactionLabels = reactionLabels
        self.images = images
        self.leadingDotColor = leadingDotColor
        self.trailingDotColor = trailingDotColor
        self.momentDate = momentDate ?? MomentDate(date: createdAt)
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    var episodeDisplayLabel: String? {
        guard !episodeLocatorValues.isEmpty else { return nil }
        let schema = SourceLocatorSchema.schema(
            for: mediaType ?? SourceLocatorSchema.fallbackMediaType
        ) ?? .fallback
        return schema.episodeDisplayName(for: episodeLocatorValues).nilIfPlaceholder
    }

    var cardSourceLabel: String {
        sourceName.nilIfPlaceholder ?? "—"
    }

    var cardLocationLabel: String {
        episodeDisplayLabel
            ?? MomentContextDisplayFormatter.cardLabel(for: self)
            ?? "—"
    }

    /// Compatibility name for call sites that need the card's compact location.
    var episodeLabel: String {
        cardLocationLabel
    }

    var glowPaletteIndex: Int {
        MomentGlowPalette.index(for: id)
    }

    var sceneNote: String { sceneText }

    var displayHeading: String {
        if let title = MomentTitlePolicy.normalized(title) { return title }
        let note = sceneNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty { return note }
        let heart = heartText.trimmingCharacters(in: .whitespacesAndNewlines)
        return heart.isEmpty ? "—" : heart
    }

    var searchableText: String {
        ([
            title ?? "",
            sceneText,
            heartText,
            caption,
            episodeDisplayLabel ?? "",
            cardLocationLabel,
            pairName,
            sourceName,
            MomentContextDisplayFormatter.compactSummary(for: self)
        ] + pairMemberNames + reactionLabels)
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
            episodeLocatorValues: animeEpisode(3),
            contextValues: animeContext(timestamp: "00:18:42"),
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
            episodeLocatorValues: animeEpisode(3),
            contextValues: animeContext(timestamp: "00:21:05"),
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
            episodeLocatorValues: animeEpisode(6),
            contextValues: animeContext(timestamp: "00:14:22"),
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
            episodeLocatorValues: animeEpisode(6),
            contextValues: animeContext(timestamp: "00:32:18"),
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
            episodeLocatorValues: animeEpisode(8),
            contextValues: [.init(key: "timestamp", value: "00:26:40")],
            reactionIDs: ["excited.shougeki"],
            reactionLabels: ["🤯 衝撃"],
            leadingDotColor: Color(hex: "#8B91F4"),
            trailingDotColor: Color(hex: "#F18AB8"),
            createdAt: previewDate,
            isFavorite: true
        ),
        MomentCardModel(
            id: "moment-solo-leveling-unassigned",
            sceneText: "立ち上がった、その瞬間。",
            heartText: "ここから全部変わるんだ……！",
            caption: "Solo Leveling 第2期",
            pairID: "pair-kei-yu",
            pairName: "慧 ・ 悠",
            sourceID: "solo-leveling",
            sourceName: "Solo Leveling 第2期",
            mediaType: "anime",
            contextValues: animeContext(timestamp: "00:04:18"),
            reactionIDs: ["excited.shougeki"],
            reactionLabels: ["🤯 衝撃"],
            leadingDotColor: Color(hex: "#7467E8"),
            trailingDotColor: Color(hex: "#9B8CF2"),
            createdAt: previewDate,
            isFavorite: false
        ),
        MomentCardModel(
            id: "moment-solo-leveling-ep08-eye-contact",
            sceneText: "That eye contact—every rewatch hits different.",
            heartText: "That eye contact—every rewatch hits different.",
            caption: "The Monarch Awakens",
            pairID: nil,
            pairName: "Jinwoo ・ Cha Hae-In",
            sourceID: "solo-leveling",
            sourceName: "Solo Leveling 第2期",
            mediaType: "anime",
            episodeID: "solo-leveling-ep08",
            episodeLocatorValues: animeEpisode(8),
            contextValues: animeContext(timestamp: "00:18:42"),
            reactionIDs: ["positive.kyun"],
            reactionLabels: ["🥰 キュン"],
            leadingDotColor: Color(hex: "#7467E8"),
            trailingDotColor: Color(hex: "#F18AB8"),
            createdAt: previewDate,
            isFavorite: false
        ),
        MomentCardModel(
            id: "moment-solo-leveling-ep08-crying",
            sceneText: "Crying at the same moment again.",
            heartText: "Crying at the same moment again.",
            caption: "The Monarch Awakens",
            pairID: nil,
            pairName: "Jinwoo ・ Cha Hae-In",
            sourceID: "solo-leveling",
            sourceName: "Solo Leveling 第2期",
            mediaType: "anime",
            episodeID: "solo-leveling-ep08",
            episodeLocatorValues: animeEpisode(8),
            contextValues: animeContext(timestamp: "00:20:15"),
            reactionIDs: ["emotional.naita"],
            reactionLabels: ["😭 泣いた"],
            leadingDotColor: Color(hex: "#7467E8"),
            trailingDotColor: Color(hex: "#F18AB8"),
            createdAt: previewDate,
            isFavorite: true
        ),
        MomentCardModel(
            id: "moment-solo-leveling-ep08-final-look",
            sceneText: "That final look. Still devastates me.",
            heartText: "That final look. Still devastates me.",
            caption: "The Monarch Awakens",
            pairID: nil,
            pairName: "Jinwoo ・ Cha Hae-In",
            sourceID: "solo-leveling",
            sourceName: "Solo Leveling 第2期",
            mediaType: "anime",
            episodeID: "solo-leveling-ep08",
            episodeLocatorValues: animeEpisode(8),
            contextValues: animeContext(timestamp: "01:08:44"),
            reactionIDs: ["emotional.setsunai"],
            reactionLabels: ["🥺 切ない"],
            leadingDotColor: Color(hex: "#7467E8"),
            trailingDotColor: Color(hex: "#F18AB8"),
            createdAt: previewDate,
            isFavorite: false
        ),
        MomentCardModel(
            id: "moment-special-event",
            sceneText: "ステージに二人が揃った瞬間",
            heartText: "この景色をずっと覚えていたい",
            caption: "Special Event",
            pairID: "pair-sora-haru",
            pairName: "空 ・ 春",
            sourceID: "special-event-2026",
            sourceName: "Special Event",
            mediaType: "event_fanmeeting",
            contextValues: [],
            reactionIDs: ["emotional.naita"],
            reactionLabels: ["😭 泣いた"],
            leadingDotColor: Color(hex: "#7BC8C5"),
            trailingDotColor: Color(hex: "#F18484"),
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

    private static func animeContext(timestamp: String) -> [ContextValue] {
        [.init(key: "timestamp", value: timestamp)]
    }

    private static func animeEpisode(_ number: Int) -> [LocatorValue] {
        [
            .init(key: "episode_kind", value: "regular"),
            .init(key: "episode", value: String(number))
        ]
    }
}
