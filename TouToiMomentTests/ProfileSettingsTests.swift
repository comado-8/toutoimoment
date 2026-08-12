import Foundation
import SwiftData
import Testing
@testable import TouToiMoment

@MainActor
struct ProfileSettingsTests {
    @Test func profileIsCreatedOnceAndKeepsItsUserID() throws {
        let container = try makeContainer()
        let firstRepository = PersistentProfileRepository(context: container.mainContext)
        let original = try firstRepository.loadProfile()

        var edited = original
        edited.nickname = "Yumiko"
        edited.avatarColor = .pink
        edited.updatedAt = original.updatedAt.addingTimeInterval(1)
        try firstRepository.saveProfile(edited)

        let restored = try PersistentProfileRepository(context: container.mainContext).loadProfile()
        #expect(restored.nickname == "Yumiko")
        #expect(restored.avatarColor == .pink)
        #expect(restored.id == original.id)
        #expect(restored.localUserID == original.localUserID)
    }

    @Test func settingsDefaultsAndToggleValuesPersist() throws {
        let container = try makeContainer()
        let repository = PersistentSettingsRepository(context: container.mainContext)
        let initial = try repository.loadSettings()
        #expect(initial.keepScreenAwake)
        #expect(initial.hapticFeedbackEnabled)
        #expect(!initial.cloudSyncEnabled)

        var updated = initial
        updated.keepScreenAwake = false
        updated.hapticFeedbackEnabled = false
        updated.cloudSyncEnabled = true
        updated.lastSyncedAt = Date(timeIntervalSince1970: 123)
        try repository.saveSettings(updated)

        let restored = try PersistentSettingsRepository(context: container.mainContext).loadSettings()
        #expect(!restored.keepScreenAwake)
        #expect(!restored.hapticFeedbackEnabled)
        #expect(restored.cloudSyncEnabled)
        #expect(restored.lastSyncedAt == Date(timeIntervalSince1970: 123))
    }

    @Test func profileStoreSanitizesNicknameAndPublishesAvatarChanges() throws {
        let container = try makeContainer()
        let store = ProfileStore(
            repository: PersistentProfileRepository(context: container.mainContext)
        )

        #expect(store.update(nickname: "Yumiko_日本語!", avatarColor: .green))
        #expect(store.profile.nickname == "Yumiko_!")
        #expect(store.profile.avatarColor == .green)

        let restored = try PersistentProfileRepository(
            context: container.mainContext
        ).loadProfile()
        #expect(restored.nickname == "Yumiko_!")
        #expect(restored.avatarColor == .green)
    }

    @Test func settingsStorePersistsWatchingPreferences() throws {
        let container = try makeContainer()
        let repository = PersistentSettingsRepository(context: container.mainContext)
        let store = SettingsStore(repository: repository)
        store.setKeepScreenAwake(false)
        store.setHapticFeedbackEnabled(false)

        let restored = try repository.loadSettings()
        #expect(!restored.keepScreenAwake)
        #expect(!restored.hapticFeedbackEnabled)
    }

    @Test func restoredContentReloadsSettingsStore() async throws {
        let store = AppDataStore(
            isStoredInMemoryOnly: true,
            momentImageRepository: NoopMomentImageRepository()
        )
        let context = store.modelContainer.mainContext
        let state = try #require(
            context.fetch(FetchDescriptor<PersistedAppSettingsState>()).first
        )
        state.keepScreenAwake = false
        if try context.fetch(FetchDescriptor<PersistedMomentState>()).isEmpty {
            context.insert(
                PersistedMomentState(
                    fixtureVersion: 1,
                    payload: try JSONEncoder().encode([PersistedMomentSnapshot]())
                )
            )
        }
        try context.save()

        try await store.reloadRestoredContent()

        #expect(!store.settingsStore.settings.keepScreenAwake)
    }

    @Test func legacyElapsedTimePreferenceIsMigratedToAlwaysOn() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(
            PersistedAppSettingsState(
                backgroundThemeID: ThemeSelection.defaultTheme.rawValue,
                keepScreenAwake: true,
                showElapsedTime: false,
                hapticFeedbackEnabled: true,
                cloudSyncEnabled: false,
                lastSyncedAt: nil,
                createdAt: .now,
                updatedAt: .now
            )
        )
        try context.save()

        _ = try PersistentSettingsRepository(context: context).loadSettings()
        let persisted = try #require(context.fetch(FetchDescriptor<PersistedAppSettingsState>()).first)
        #expect(persisted.showElapsedTime)
    }

    @Test func profileRoutesApplyTheExpectedTabBarVisibility() {
        #expect(!AppRoute.settings.hidesBottomTabBar)
        #expect(AppRoute.editProfile.hidesBottomTabBar)
        #expect(AppRoute.about.hidesBottomTabBar)
        #expect(AppRoute.helpFeedback.hidesBottomTabBar)
        #expect(AppRoute.premium.hidesBottomTabBar)
    }

    @Test func premiumSettingsRequireAnUnlockedPurchase() {
        #expect(!PremiumAccessPolicy.canUsePremiumSettings(isPremium: false))
        #expect(PremiumAccessPolicy.canUsePremiumSettings(isPremium: true))
    }

    @Test func deletingContentKeepsProfileAndSettings() async throws {
        let store = AppDataStore(
            isStoredInMemoryOnly: true,
            momentImageRepository: NoopMomentImageRepository()
        )
        let profileID = store.profileStore.profile.id
        store.profileStore.update(nickname: "Keep Me", avatarColor: .green)

        try await store.deleteAllContent()
        let sources = try await store.sourceRepository.fetchSources()

        #expect(sources.isEmpty)
        #expect(store.momentStore.moments.isEmpty)
        #expect(store.profileStore.profile.id == profileID)
        #expect(store.profileStore.profile.nickname == "Keep Me")
    }

    @Test func localServicesReportUnavailableInsteadOfSilentlySucceeding() async {
        await #expect(throws: AppServiceError.self) {
            try await LocalPurchaseService().purchase()
        }
        await #expect(throws: AppServiceError.self) {
            _ = try await LocalCloudSyncService().syncNow()
        }
        await #expect(throws: AppServiceError.self) {
            _ = try await LocalBackupService().exportEncryptedBackup(passphrase: "test-passphrase")
        }
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PersistedUserProfileState.self,
            PersistedAppSettingsState.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

private actor NoopMomentImageRepository: MomentImageRepository {
    func images(for momentID: String) async throws -> [MomentImage] { [] }
    func imageData(for image: MomentImage, momentID: String) async throws -> Data { Data() }
    func addImage(data: Data, id: String, createdAt: Date, to momentID: String) async throws -> [MomentImage] { [] }
    func removeImage(id: String, from momentID: String) async throws -> [MomentImage] { [] }
    func commit(_ changes: MomentImageChangeSet, for momentID: String) async throws -> [MomentImage] { [] }
    func deleteImages(for momentID: String) async throws {}
    func removeOrphans(validMomentIDs: Set<String>) async throws {}
}
