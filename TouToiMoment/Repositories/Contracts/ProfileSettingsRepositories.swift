import Foundation

@MainActor
protocol ProfileRepository {
    func loadProfile() throws -> UserProfile
    func saveProfile(_ profile: UserProfile) throws
}

@MainActor
protocol SettingsRepository {
    func loadSettings() throws -> AppSettings
    func saveSettings(_ settings: AppSettings) throws
}
