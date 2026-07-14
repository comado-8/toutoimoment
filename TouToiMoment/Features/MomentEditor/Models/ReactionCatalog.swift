import Foundation

struct ReactionCatalog {
    struct Section: Hashable, Identifiable {
        let id: String
        let title: String
        let reactions: [NewMomentDraft.SelectedReaction]
    }

    static let sections: [Section] = [
        Section(
            id: "positive",
            title: "❤️ POSITIVE",
            reactions: [
                reaction("positive.toutoi", "positive", "❤️", "尊い"),
                reaction("positive.kyun", "positive", "🥰", "キュン"),
                reaction("positive.daisuki", "positive", "😊", "大好き"),
                reaction("positive.iyasareta", "positive", "😌", "癒された"),
                reaction("positive.shiawase", "positive", "✨", "幸せ"),
                reaction("positive.arigatou", "positive", "🙏", "ありがとう…"),
                reaction("positive.hohoemashii", "positive", "🌸", "微笑ましい"),
            ]
        ),
        Section(
            id: "emotional",
            title: "💜 EMOTIONAL",
            reactions: [
                reaction("emotional.naita", "emotional", "😭", "泣いた"),
                reaction("emotional.kandou", "emotional", "🥹", "感動"),
                reaction("emotional.setsunai", "emotional", "💔", "切ない"),
                reaction("emotional.shindoi", "emotional", "🫠", "しんどい"),
                reaction("emotional.munegakurushii", "emotional", "🥺", "胸が苦しい"),
                reaction("emotional.emoi", "emotional", "😮‍💨", "エモい"),
            ]
        ),
        Section(
            id: "excited",
            title: "🔥 EXCITED",
            reactions: [
                reaction("excited.shougeki", "excited", "🤯", "衝撃"),
                reaction("excited.kamikai", "excited", "🔥", "神回"),
                reaction("excited.kamiengi", "excited", "⭐", "神演技"),
                reaction("excited.torihada", "excited", "⚡", "鳥肌"),
                reaction("excited.saikou", "excited", "💥", "最高"),
                reaction("excited.hakushu", "excited", "👏", "拍手"),
            ]
        ),
        Section(
            id: "otaku",
            title: "🤣 OTAKU",
            reactions: [
                reaction("otaku.bakushou", "otaku", "😂", "爆笑"),
                reaction("otaku.kawaii", "otaku", "😳", "可愛い"),
                reaction("otaku.mimamoritai", "otaku", "🙈", "見守りたい"),
                reaction("otaku.niyaketa", "otaku", "😏", "ニヤけた"),
                reaction("otaku.muri", "otaku", "🫥", "無理…"),
                reaction("otaku.numa", "otaku", "💘", "沼"),
                reaction("otaku.yokoten", "otaku", "🤸", "横転"),
                reaction("otaku.daiyokoten", "otaku", "🤸‍♂️", "大横転"),
                reaction("otaku.kyuukyuusha", "otaku", "🚑", "救急車"),
                reaction("otaku.hakairi", "otaku", "⚰️", "墓入り"),
                reaction("otaku.hirefusu", "otaku", "🧎", "ひれ伏す"),
            ]
        ),
        Section(
            id: "analysis",
            title: "🧠 ANALYSIS",
            reactions: [
                reaction("analysis.fukusen", "analysis", "👀", "伏線"),
                reaction("analysis.kousatsu", "analysis", "💡", "考察"),
                reaction("analysis.kaishakuicchi", "analysis", "✅", "解釈一致"),
                reaction("analysis.kaishakuchigai", "analysis", "🤔", "解釈違い"),
                reaction("analysis.kizuita", "analysis", "😲", "気づいた"),
            ]
        ),
    ]

    static var allReactions: [NewMomentDraft.SelectedReaction] {
        sections.flatMap(\.reactions)
    }

    private static func reaction(
        _ id: String,
        _ section: String,
        _ emoji: String,
        _ label: String
    ) -> NewMomentDraft.SelectedReaction {
        NewMomentDraft.SelectedReaction(
            id: id,
            section: section,
            emoji: emoji,
            label: label
        )
    }
}
