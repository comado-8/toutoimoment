import Foundation
import SwiftData

@Model
final class PersistedSourceState {
    @Attribute(.unique) var key: String
    var fixtureVersion: Int
    var payload: Data

    init(key: String = "sources", fixtureVersion: Int, payload: Data) {
        self.key = key
        self.fixtureVersion = fixtureVersion
        self.payload = payload
    }
}

@Model
final class PersistedPairState {
    @Attribute(.unique) var key: String
    var schemaVersion: Int
    var payload: Data

    init(key: String = "pairs", schemaVersion: Int = 1, payload: Data) {
        self.key = key
        self.schemaVersion = schemaVersion
        self.payload = payload
    }
}

@Model
final class PersistedMomentState {
    @Attribute(.unique) var key: String
    var fixtureVersion: Int
    var payload: Data

    init(key: String = "moments", fixtureVersion: Int, payload: Data) {
        self.key = key
        self.fixtureVersion = fixtureVersion
        self.payload = payload
    }
}

@Model
final class PersistedUserProfileState {
    @Attribute(.unique) var key: String
    var id: UUID
    var nickname: String
    var avatarColorID: String
    var createdAt: Date
    var updatedAt: Date

    init(
        key: String = "user-profile",
        id: UUID,
        nickname: String,
        avatarColorID: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.key = key
        self.id = id
        self.nickname = nickname
        self.avatarColorID = avatarColorID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class PersistedAppSettingsState {
    @Attribute(.unique) var key: String
    var backgroundThemeID: String
    var keepScreenAwake: Bool
    var showElapsedTime: Bool
    var hapticFeedbackEnabled: Bool
    var cloudSyncEnabled: Bool
    var lastSyncedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        key: String = "app-settings",
        backgroundThemeID: String,
        keepScreenAwake: Bool,
        showElapsedTime: Bool,
        hapticFeedbackEnabled: Bool,
        cloudSyncEnabled: Bool,
        lastSyncedAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.key = key
        self.backgroundThemeID = backgroundThemeID
        self.keepScreenAwake = keepScreenAwake
        self.showElapsedTime = showElapsedTime
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.cloudSyncEnabled = cloudSyncEnabled
        self.lastSyncedAt = lastSyncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
