import Foundation
import SwiftData
import Combine

@MainActor
final class AppDataStore: ObservableObject {
    let modelContainer: ModelContainer
    let sourceRepository: any SourceRepository
    let pairRepository: any PairRepository
    let momentStore: MomentStore
    let profileStore: ProfileStore
    let settingsStore: SettingsStore
    let purchaseService: any PurchaseServicing
    let cloudSyncService: any CloudSyncServicing
    let backupService: any BackupServicing
    let supportLinks: SupportLinks
    private var cancellables: Set<AnyCancellable> = []

    init(
        isStoredInMemoryOnly: Bool = false,
        purchaseService: (any PurchaseServicing)? = nil,
        cloudSyncService: (any CloudSyncServicing)? = nil,
        backupService: (any BackupServicing)? = nil,
        supportLinks: SupportLinks? = nil,
        momentImageRepository: (any MomentImageRepository)? = nil
    ) {
        do {
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
            let container = try ModelContainer(
                for: PersistedSourceState.self,
                PersistedPairState.self,
                PersistedMomentState.self,
                PersistedUserProfileState.self,
                PersistedAppSettingsState.self,
                configurations: configuration
            )
            modelContainer = container
            let context = container.mainContext
            let resolvedImageRepository = momentImageRepository ?? LocalMomentImageRepository()
            sourceRepository = try PersistentSourceRepository(context: context)
            momentStore = MomentStore(
                imageRepository: resolvedImageRepository,
                persistence: SwiftDataMomentStorePersistence(context: context)
            )
            pairRepository = try PersistentPairRepository(
                context: context,
                moments: momentStore.moments
            )
            profileStore = ProfileStore(
                repository: PersistentProfileRepository(context: context)
            )
            let resolvedSettingsStore = SettingsStore(
                repository: PersistentSettingsRepository(context: context)
            )
            settingsStore = resolvedSettingsStore
            self.purchaseService = purchaseService ?? LocalPurchaseService()
            self.cloudSyncService = cloudSyncService ?? LocalCloudSyncService()
            self.backupService = backupService ?? EncryptedManualBackupService(
                modelContainer: container,
                imageRepository: resolvedImageRepository,
                imageRootURL: LocalMomentImageRepository.defaultRootURL(fileManager: .default),
                cloudSyncEnabled: { resolvedSettingsStore.settings.cloudSyncEnabled }
            )
            self.supportLinks = supportLinks ?? SupportLinks()
            momentStore.$moments
                .map(MomentReferenceCounts.make(from:))
                .removeDuplicates()
                .sink { [weak self] counts in
                    Task { @MainActor [weak self] in
                        try? await self?.sourceRepository.synchronizeMomentCounts(counts)
                    }
                }
                .store(in: &cancellables)
            momentStore.$moments
                .map { moments in
                    var counts: [String: Int] = [:]
                    for moment in moments {
                        if let pairID = moment.pairID { counts[pairID, default: 0] += 1 }
                    }
                    return counts
                }
                .removeDuplicates()
                .sink { [weak self] counts in
                    Task { @MainActor [weak self] in
                        try? await self?.pairRepository.synchronizeMomentCounts(counts)
                    }
                }
                .store(in: &cancellables)
            Task { @MainActor [weak self] in
                guard let self,
                      let pairs = try? await self.pairRepository.fetchPairs()
                else { return }
                for pair in pairs {
                    self.momentStore.updatePairReference(
                        id: pair.id,
                        displayName: pair.displayName,
                        member1Name: pair.member1Name,
                        member2Name: pair.member2Name,
                        leadingColorHex: pair.leadingColorHex,
                        trailingColorHex: pair.trailingColorHex
                    )
                }
            }
        } catch {
            fatalError("Unable to initialize app data: \(error)")
        }
    }

    func deleteAllContent() async throws {
        let sources = try await sourceRepository.fetchSources()
        for source in sources {
            try await sourceRepository.deleteSource(id: source.id)
        }
        try await pairRepository.deleteAllPairs()
        try await momentStore.deleteAll()
    }

    func reloadRestoredContent() async throws {
        try sourceRepository.reloadFromPersistence()
        try pairRepository.reloadFromPersistence()
        try profileStore.reloadFromPersistence()
        try settingsStore.reloadFromPersistence()
        try await momentStore.reloadFromPersistence()
        let pairs = try await pairRepository.fetchPairs()
        for pair in pairs {
            momentStore.updatePairReference(
                id: pair.id,
                displayName: pair.displayName,
                member1Name: pair.member1Name,
                member2Name: pair.member2Name,
                leadingColorHex: pair.leadingColorHex,
                trailingColorHex: pair.trailingColorHex
            )
        }
    }
}
