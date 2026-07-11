import SwiftUI

struct MomentCardModel: Identifiable {
    let id = UUID()
    let sceneText: String
    let caption: String
    let episodeLabel: String
    let leadingDotColor: Color
    let trailingDotColor: Color
    let isFavorite: Bool
    let glowColors: [Color]
}

enum HomePreviewData {
    static let greetingName = "Comado"
    static let registeredMomentCount = 14
    static let moments = MomentCardModel.preview
}

extension MomentCardModel {
    static let preview: [MomentCardModel] = [
        MomentCardModel(
            sceneText: "待ってるよ。\nあの場所で。",
            caption: "修学旅行で仲良くないグループに...",
            episodeLabel: "EP3",
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            isFavorite: true,
            glowColors: [Color.appAccentSoft.opacity(0.65), Color.appPrimaryTint.opacity(0.65)]
        ),
        MomentCardModel(
            sceneText: "待ってるよ。\nあの場所で。",
            caption: "修学旅行で仲良くないグループに...",
            episodeLabel: "EP3",
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            isFavorite: true,
            glowColors: [Color.surfaceWhite.opacity(0.72), Color.appPrimaryTint.opacity(0.58)]
        ),
        MomentCardModel(
            sceneText: "待ってるよ。\nあの場所で。",
            caption: "修学旅行で仲良くないグループに...",
            episodeLabel: "EP3",
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            isFavorite: true,
            glowColors: [Color.appAccentSoft.opacity(0.52), Color.appPrimaryTint.opacity(0.60)]
        )
    ]
}
