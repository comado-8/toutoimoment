import Foundation
import SwiftUI

enum AvatarColorSelection: String, Codable, CaseIterable, Identifiable {
    case purple
    case blue
    case pink
    case green
    case orange
    case gray

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .purple: Color(hex: "#7C6FCD")
        case .blue: Color(hex: "#4A7CF7")
        case .pink: Color(hex: "#F76FA0")
        case .green: Color(hex: "#4ACF8A")
        case .orange: Color(hex: "#F7904A")
        case .gray: Color(hex: "#9CA3AF")
        }
    }
}

struct UserProfile: Equatable {
    let id: UUID
    var nickname: String
    var avatarColor: AvatarColorSelection
    let createdAt: Date
    var updatedAt: Date

    static func initial(now: Date = .now, id: UUID = UUID()) -> UserProfile {
        UserProfile(
            id: id,
            nickname: "Comado",
            avatarColor: .purple,
            createdAt: now,
            updatedAt: now
        )
    }

    var localUserID: String {
        let compact = id.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return "ttoi_\(compact.prefix(8))"
    }
}
