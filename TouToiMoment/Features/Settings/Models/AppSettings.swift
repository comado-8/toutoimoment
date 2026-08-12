import Foundation

enum ThemeSelection: String, Codable, CaseIterable, Identifiable {
    case defaultTheme = "default"

    var id: String { rawValue }
    var displayName: String { "Default" }
}

struct AppSettings: Equatable {
    var backgroundTheme: ThemeSelection
    var keepScreenAwake: Bool
    var hapticFeedbackEnabled: Bool
    var cloudSyncEnabled: Bool
    var lastSyncedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    static func initial(now: Date = .now) -> AppSettings {
        AppSettings(
            backgroundTheme: .defaultTheme,
            keepScreenAwake: true,
            hapticFeedbackEnabled: true,
            cloudSyncEnabled: false,
            lastSyncedAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}

enum PremiumAccessPolicy {
    static func canUsePremiumSettings(isPremium: Bool) -> Bool {
        isPremium
    }
}
