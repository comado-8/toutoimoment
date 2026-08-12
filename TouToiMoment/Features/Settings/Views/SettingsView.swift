import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    let purchaseService: any PurchaseServicing
    let cloudSyncService: any CloudSyncServicing
    let backupService: any BackupServicing
    let supportLinks: SupportLinks
    let onBack: () -> Void
    let onOpenPremium: () -> Void
    let onOpenAbout: () -> Void
    let onDeleteAll: () async throws -> Void
    let onRestoreCompleted: () async throws -> Void

    @Environment(\.openURL) private var openURL
    @StateObject private var manualBackupViewModel: ManualBackupSettingsViewModel
    @State private var activeAlert: SettingsAlert?
    @State private var showsExportPassphrase = false
    @State private var showsImportPassphrase = false
    @State private var showsFileImporter = false
    @State private var showsRestoreConfirmation = false
    @State private var selectedImportURL: URL?
    @State private var shareItem: BackupShareItem?

    init(
        settingsStore: SettingsStore,
        purchaseService: any PurchaseServicing,
        cloudSyncService: any CloudSyncServicing,
        backupService: any BackupServicing,
        supportLinks: SupportLinks,
        onBack: @escaping () -> Void,
        onOpenPremium: @escaping () -> Void,
        onOpenAbout: @escaping () -> Void,
        onDeleteAll: @escaping () async throws -> Void,
        onRestoreCompleted: @escaping () async throws -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.purchaseService = purchaseService
        self.cloudSyncService = cloudSyncService
        self.backupService = backupService
        self.supportLinks = supportLinks
        self.onBack = onBack
        self.onOpenPremium = onOpenPremium
        self.onOpenAbout = onOpenAbout
        self.onDeleteAll = onDeleteAll
        self.onRestoreCompleted = onRestoreCompleted
        _manualBackupViewModel = StateObject(
            wrappedValue: ManualBackupSettingsViewModel(service: backupService)
        )
    }

    var body: some View {
        ZStack {
            ProfileScreenBackground()

            ScrollView {
                VStack(spacing: 0) {
                    settingsHeader

                    VStack(spacing: 20) {
                        appearanceSection
                        watchingSection
                        dataSection
                        aboutSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 132)
                }
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(item: $activeAlert) { alert in
            alertContent(alert)
        }
        .fullScreenCover(isPresented: $showsExportPassphrase) {
            ManualBackupPassphraseSheet(
                title: AppStrings.settingsExport,
                message: "記録とプロフィール、画像を暗号化して保存します。",
                submitTitle: "書き出す",
                requiresConfirmation: true,
                isProcessing: manualBackupViewModel.isExporting
            ) { passphrase, confirmation in
                Task {
                    guard let url = await manualBackupViewModel.export(
                        passphrase: passphrase,
                        confirmation: confirmation
                    ) else { return }
                    showsExportPassphrase = false
                    shareItem = BackupShareItem(url: url)
                }
            }
        }
        .fullScreenCover(isPresented: $showsImportPassphrase, onDismiss: {
            if !showsRestoreConfirmation {
                cleanupSelectedImportFile()
            }
        }) {
            ManualBackupPassphraseSheet(
                title: AppStrings.settingsImport,
                message: "バックアップ作成時のパスフレーズを入力してください。",
                submitTitle: "内容を確認",
                requiresConfirmation: false,
                isProcessing: manualBackupViewModel.isInspecting
            ) { passphrase, _ in
                guard let selectedImportURL else { return }
                Task {
                    let success = await manualBackupViewModel.inspect(
                        url: selectedImportURL,
                        passphrase: passphrase
                    )
                    showsImportPassphrase = false
                    if success {
                        showsRestoreConfirmation = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showsRestoreConfirmation, onDismiss: {
            manualBackupViewModel.clearPending()
            cleanupSelectedImportFile()
        }) {
            if let preview = manualBackupViewModel.pendingPreview {
                ManualRestoreConfirmationSheet(
                    preview: preview,
                    isRestoring: manualBackupViewModel.isRestoring
                ) {
                    Task {
                        guard await manualBackupViewModel.restorePending() != nil else {
                            showsRestoreConfirmation = false
                            return
                        }
                        do {
                            try await onRestoreCompleted()
                            showsRestoreConfirmation = false
                            activeAlert = .message("バックアップを復元しました")
                        } catch {
                            activeAlert = .message("復元後のデータを再読み込みできませんでした")
                        }
                    }
                }
            }
        }
        .sheet(item: $shareItem, onDismiss: cleanupSharedBackupFile) { item in
            SystemActivityView(activityItems: [item.url])
        }
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [Self.manualBackupContentType],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .accessibilityIdentifier("settings.screen")
    }

    private var settingsHeader: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text(AppStrings.profileSettings)
                .font(AppTypography.momentsTitle())
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: AppStrings.settingsAppearance)

            Button(action: openBackgroundSettings) {
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.appPrimary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(AppStrings.settingsBackground)
                                .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                                .foregroundStyle(Color.textPrimary)
                            if !purchaseService.isPremium {
                                SettingsPremiumBadge()
                            }
                            Spacer()
                            Text("\(settingsStore.settings.backgroundTheme.displayName) ›")
                                .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color(hex: "#9B9EC4"))
                        }

                        Text("Default / Premium backgrounds")
                            .font(.custom("Geist-Regular", size: 11, relativeTo: .caption2))
                            .foregroundStyle(Color(hex: "#9B9EC4"))
                    }
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassCard(cornerRadius: 20, fillOpacity: 0.4)
            .accessibilityIdentifier("settings.background")
        }
    }

    private var watchingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: AppStrings.settingsWatchingMode)

            SettingsGlassGroup {
                SettingsToggleRow(
                    title: AppStrings.settingsKeepAwake,
                    systemImage: "moon",
                    isOn: Binding(
                        get: { settingsStore.settings.keepScreenAwake },
                        set: settingsStore.setKeepScreenAwake
                    )
                )
                SettingsDivider()
                SettingsToggleRow(
                    title: AppStrings.settingsHaptics,
                    systemImage: "hand.tap",
                    isOn: Binding(
                        get: { settingsStore.settings.hapticFeedbackEnabled },
                        set: settingsStore.setHapticFeedbackEnabled
                    )
                )
            }
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: AppStrings.settingsData)

            SettingsGlassGroup {
                SettingsToggleRow(
                    title: AppStrings.settingsCloudSync,
                    systemImage: "cloud",
                    isOn: Binding(
                        get: { settingsStore.settings.cloudSyncEnabled },
                        set: handleCloudSyncToggle
                    ),
                    showsPremiumBadge: !purchaseService.isPremium
                )

                HStack {
                    Text(AppStrings.settingsLastSync)
                        .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                    Spacer()
                    Text(lastSyncText)
                        .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                }
                .padding(.leading, 52)
                .padding(.trailing, 16)
                .frame(minHeight: 34)

                Button(AppStrings.settingsSyncNow) {
                    Task { await syncNow() }
                }
                .font(.custom("Geist-SemiBold", size: 15, relativeTo: .body))
                .foregroundStyle(Color.appPrimary)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, minHeight: 39, alignment: .leading)
                .padding(.leading, 52)
                .overlay(alignment: .trailing) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.trailing, 16)
                }
                .disabled(!canSyncNow)

                SettingsDivider()
                SettingsActionRow(
                    title: AppStrings.settingsExport,
                    systemImage: "square.and.arrow.down",
                    action: exportData
                )
                SettingsDivider()
                SettingsActionRow(
                    title: AppStrings.settingsImport,
                    systemImage: "square.and.arrow.up",
                    action: importData
                )
                if let message = manualBackupViewModel.errorMessage {
                    Text(message)
                        .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                SettingsDivider()
                SettingsActionRow(
                    title: AppStrings.settingsDeleteAll,
                    systemImage: "trash",
                    tint: .red,
                    showsChevron: false
                ) {
                    activeAlert = .confirmDelete
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionLabel(title: AppStrings.settingsAbout)

            SettingsGlassGroup {
                SettingsActionRow(
                    title: AppStrings.settingsVersion,
                    trailingText: AppVersionInfo.versionAndBuild,
                    showsChevron: false,
                    action: onOpenAbout
                )
                SettingsDivider(leadingInset: 16)
                SettingsActionRow(title: AppStrings.settingsPrivacy, systemImage: "link") {
                    open(supportLinks.privacyPolicy)
                }
                SettingsDivider()
                SettingsActionRow(title: AppStrings.settingsTerms, systemImage: "link") {
                    open(supportLinks.termsOfService)
                }
                SettingsDivider()
                SettingsActionRow(title: AppStrings.settingsLicenses) {
                    activeAlert = .unavailable
                }
                SettingsDivider(leadingInset: 16)
                SettingsActionRow(title: AppStrings.settingsWebsite, systemImage: "link") {
                    open(supportLinks.officialWebsite)
                }
            }
        }
    }

    private var lastSyncText: String {
        guard let date = settingsStore.settings.lastSyncedAt else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private func handleCloudSyncToggle(_ value: Bool) {
        guard value else {
            settingsStore.setCloudSyncEnabled(false)
            return
        }
        guard PremiumAccessPolicy.canUsePremiumSettings(isPremium: purchaseService.isPremium) else {
            settingsStore.setCloudSyncEnabled(false)
            onOpenPremium()
            return
        }
        settingsStore.setCloudSyncEnabled(true)
    }

    private func openBackgroundSettings() {
        if PremiumAccessPolicy.canUsePremiumSettings(isPremium: purchaseService.isPremium) {
            activeAlert = .unavailable
        } else {
            onOpenPremium()
        }
    }

    private func syncNow() async {
        guard canSyncNow else { return }
        do {
            let date = try await cloudSyncService.syncNow()
            settingsStore.markSynced(at: date)
            activeAlert = .message("Sync Complete")
        } catch {
            activeAlert = .unavailable
        }
    }

    private var canSyncNow: Bool {
        settingsStore.settings.cloudSyncEnabled
            && PremiumAccessPolicy.canUsePremiumSettings(isPremium: purchaseService.isPremium)
    }

    private func exportData() {
        manualBackupViewModel.errorMessage = nil
        showsExportPassphrase = true
    }

    private func importData() {
        guard !settingsStore.settings.cloudSyncEnabled else {
            manualBackupViewModel.errorMessage = ManualBackupError
                .restoreNotAllowedWhileCloudSyncEnabled
                .localizedDescription
            return
        }
        manualBackupViewModel.errorMessage = nil
        cleanupSelectedImportFile()
        showsFileImporter = true
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first,
                  sourceURL.pathExtension.lowercased() == ManualBackupImportPolicy.fileExtension
            else {
                manualBackupViewModel.errorMessage = "`.ttmbackup`ファイルを選択してください。"
                return
            }
            do {
                let values = try sourceURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                guard values.isRegularFile == true,
                      let fileSize = values.fileSize,
                      Int64(fileSize) <= ManualBackupImportPolicy.maximumArchiveBytes
                else {
                    throw ManualBackupError.archiveTooLarge
                }
                let destination = FileManager.default.temporaryDirectory.appendingPathComponent(
                    "manual-backup-import-\(UUID().uuidString).ttmbackup"
                )
                let scoped = sourceURL.startAccessingSecurityScopedResource()
                defer { if scoped { sourceURL.stopAccessingSecurityScopedResource() } }
                try FileManager.default.copyItem(at: sourceURL, to: destination)
                selectedImportURL = destination
                showsImportPassphrase = true
            } catch {
                cleanupSelectedImportFile()
                manualBackupViewModel.errorMessage = "バックアップファイルを読み込めませんでした。"
            }
        case .failure:
            cleanupSelectedImportFile()
            manualBackupViewModel.errorMessage = "バックアップファイルを選択できませんでした。"
        }
    }

    private func cleanupSelectedImportFile() {
        if let selectedImportURL { try? FileManager.default.removeItem(at: selectedImportURL) }
        selectedImportURL = nil
    }

    private func cleanupSharedBackupFile() {
        if let shareItem { try? FileManager.default.removeItem(at: shareItem.url) }
        shareItem = nil
    }

    private static let manualBackupContentType = UTType(
        exportedAs: ManualBackupImportPolicy.formatIdentifier,
        conformingTo: .data
    )

    private func open(_ url: URL?) {
        guard let url else {
            activeAlert = .linkNotConfigured
            return
        }
        openURL(url)
    }

    private func alertContent(_ alert: SettingsAlert) -> Alert {
        switch alert {
        case .confirmDelete:
            Alert(
                title: Text("Delete All Data?"),
                message: Text("All Moments and Sources stored on this device will be removed."),
                primaryButton: .destructive(Text("Continue")) {
                    Task { @MainActor in
                        await Task.yield()
                        activeAlert = .finalDelete
                    }
                },
                secondaryButton: .cancel()
            )
        case .finalDelete:
            Alert(
                title: Text("This Cannot Be Undone"),
                message: Text("Your profile and settings will be kept."),
                primaryButton: .destructive(Text("Delete All Data")) {
                    Task {
                        do {
                            try await onDeleteAll()
                            activeAlert = .message("All Data Deleted")
                        } catch {
                            activeAlert = .message("Couldn’t Delete Data")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        case .unavailable:
            Alert(title: Text("Coming Soon"), message: Text("This feature is not available yet."), dismissButton: .default(Text("OK")))
        case .linkNotConfigured:
            Alert(title: Text("Link Not Configured"), message: Text("Add the destination URL to enable this action."), dismissButton: .default(Text("OK")))
        case .message(let message):
            Alert(title: Text(message), dismissButton: .default(Text("OK")))
        }
    }
}

private struct BackupShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private enum SettingsAlert: Identifiable {
    case confirmDelete
    case finalDelete
    case unavailable
    case linkNotConfigured
    case message(String)

    var id: String {
        switch self {
        case .confirmDelete: "confirm-delete"
        case .finalDelete: "final-delete"
        case .unavailable: "unavailable"
        case .linkNotConfigured: "link-not-configured"
        case .message(let text): "message-\(text)"
        }
    }
}
