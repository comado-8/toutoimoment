import Foundation
import SwiftData

@MainActor
final class PersistentProfileRepository: ProfileRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadProfile() throws -> UserProfile {
        let descriptor = FetchDescriptor<PersistedUserProfileState>()
        if let state = try context.fetch(descriptor).first {
            return UserProfile(
                id: state.id,
                nickname: state.nickname,
                avatarColor: AvatarColorSelection(rawValue: state.avatarColorID) ?? .purple,
                createdAt: state.createdAt,
                updatedAt: state.updatedAt
            )
        }

        let profile = UserProfile.initial()
        try saveProfile(profile)
        return profile
    }

    func saveProfile(_ profile: UserProfile) throws {
        let descriptor = FetchDescriptor<PersistedUserProfileState>()
        if let state = try context.fetch(descriptor).first {
            state.nickname = profile.nickname
            state.avatarColorID = profile.avatarColor.rawValue
            state.updatedAt = profile.updatedAt
        } else {
            context.insert(
                PersistedUserProfileState(
                    id: profile.id,
                    nickname: profile.nickname,
                    avatarColorID: profile.avatarColor.rawValue,
                    createdAt: profile.createdAt,
                    updatedAt: profile.updatedAt
                )
            )
        }
        try context.save()
    }
}

@MainActor
final class PersistentSettingsRepository: SettingsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<PersistedAppSettingsState>()
        if let state = try context.fetch(descriptor).first {
            if !state.showElapsedTime {
                state.showElapsedTime = true
                state.updatedAt = .now
                try context.save()
            }
            return AppSettings(
                backgroundTheme: ThemeSelection(rawValue: state.backgroundThemeID) ?? .defaultTheme,
                keepScreenAwake: state.keepScreenAwake,
                hapticFeedbackEnabled: state.hapticFeedbackEnabled,
                cloudSyncEnabled: state.cloudSyncEnabled,
                lastSyncedAt: state.lastSyncedAt,
                createdAt: state.createdAt,
                updatedAt: state.updatedAt
            )
        }

        let settings = AppSettings.initial()
        try saveSettings(settings)
        return settings
    }

    func saveSettings(_ settings: AppSettings) throws {
        let descriptor = FetchDescriptor<PersistedAppSettingsState>()
        if let state = try context.fetch(descriptor).first {
            state.backgroundThemeID = settings.backgroundTheme.rawValue
            state.keepScreenAwake = settings.keepScreenAwake
            state.showElapsedTime = true
            state.hapticFeedbackEnabled = settings.hapticFeedbackEnabled
            state.cloudSyncEnabled = settings.cloudSyncEnabled
            state.lastSyncedAt = settings.lastSyncedAt
            state.updatedAt = settings.updatedAt
        } else {
            context.insert(
                PersistedAppSettingsState(
                    backgroundThemeID: settings.backgroundTheme.rawValue,
                    keepScreenAwake: settings.keepScreenAwake,
                    showElapsedTime: true,
                    hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
                    cloudSyncEnabled: settings.cloudSyncEnabled,
                    lastSyncedAt: settings.lastSyncedAt,
                    createdAt: settings.createdAt,
                    updatedAt: settings.updatedAt
                )
            )
        }
        try context.save()
    }
}
