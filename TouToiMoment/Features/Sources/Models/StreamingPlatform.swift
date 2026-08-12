import Foundation

enum StreamingPlatformID: String, CaseIterable, Identifiable, Hashable, Codable {
    case youtube
    case instagram
    case twitch
    case tiktok
    case twitcasting
    case niconico
    case showroom
    case other

    var id: Self { self }

    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .instagram: return "Instagram"
        case .twitch: return "Twitch"
        case .tiktok: return "TikTok"
        case .twitcasting: return "ツイキャス"
        case .niconico: return "ニコニコ"
        case .showroom: return "SHOWROOM"
        case .other: return "その他"
        }
    }
}

struct StreamingPlatform: Hashable, Codable {
    let id: StreamingPlatformID
    let customName: String?

    init(id: StreamingPlatformID, customName: String? = nil) {
        self.id = id
        let trimmed = customName.map(StreamingPlatformNamePolicy.limited)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        self.customName = id == .other && trimmed?.isEmpty == false ? trimmed : nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case customName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(StreamingPlatformID.self, forKey: .id),
            customName: try container.decodeIfPresent(String.self, forKey: .customName)
        )
    }

    var isValid: Bool {
        id != .other || customName != nil
    }

    var displayName: String {
        customName ?? id.displayName
    }
}
