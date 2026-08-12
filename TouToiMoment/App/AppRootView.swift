import SwiftUI

struct AppRootView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var selectedTab: MainTab = .home
    @State private var navigationPath: [AppRoute] = []
    @State private var isDiscardConfirmationPresented = false
    @State private var isProfileDrawerPresented = false
    @State private var isKeyboardVisible = false
    @StateObject private var appDataStore = AppDataStore()
    private var momentStore: MomentStore { appDataStore.momentStore }
    private var sourceRepository: any SourceRepository { appDataStore.sourceRepository }
    private var pairRepository: any PairRepository { appDataStore.pairRepository }
    private var profileStore: ProfileStore { appDataStore.profileStore }
    private var settingsStore: SettingsStore { appDataStore.settingsStore }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AppBackgroundView(theme: .home)
                    .ignoresSafeArea()

                currentTabView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pairDetail(let pairID):
                    PairDetailView(
                        pairID: pairID,
                        repository: pairRepository,
                        momentStore: momentStore,
                        onCreateMoment: {
                            navigationPath.append(
                                .newMoment(pairID: pairID, sourceID: nil, episodeID: nil)
                            )
                        },
                        onUpdated: { pair in
                            momentStore.updatePairReference(
                                id: pair.id,
                                displayName: pair.displayName,
                                member1Name: pair.member1Name,
                                member2Name: pair.member2Name,
                                leadingColorHex: pair.leadingColorHex,
                                trailingColorHex: pair.trailingColorHex
                            )
                        },
                        onDeleted: { pairID in
                            momentStore.clearPairReferences(id: pairID)
                        },
                        onOpenMoment: { momentID in
                            navigationPath.append(.momentDetail(momentID))
                        }
                    )
                case .sourceDetail(let sourceID):
                    SourceDetailView(
                        sourceID: sourceID,
                        repository: sourceRepository,
                        momentStore: momentStore,
                        onOpenEpisode: { sourceID, episodeID in
                            navigationPath.append(
                                .episodeDetail(sourceID: sourceID, episodeID: episodeID)
                            )
                        },
                        onOpenMoment: { momentID in
                            navigationPath.append(.momentDetail(momentID))
                        },
                        onUpdated: { source in
                            momentStore.updateSourceReference(
                                id: source.id,
                                displayName: source.displayName,
                                mediaType: source.mediaType
                            )
                        },
                        onDeleted: { sourceID in
                            momentStore.clearSourceReferences(id: sourceID)
                        }
                    )
                case let .episodeDetail(sourceID, episodeID, initialSection):
                    EpisodeDetailView(
                        sourceID: sourceID,
                        episodeID: episodeID,
                        initialSection: initialSection,
                        repository: sourceRepository,
                        momentStore: momentStore,
                        onCreateMoment: {
                            navigationPath.append(
                                .newMoment(sourceID: sourceID, episodeID: episodeID)
                            )
                        },
                        onStartWatching: {
                            navigationPath.append(
                                .watchingSetup(sourceID: sourceID, episodeID: episodeID)
                            )
                        },
                        onOpenMoment: { momentID in
                            navigationPath.append(.momentDetail(momentID))
                        },
                        onOpenWatchHistory: { sessionID in
                            navigationPath.append(
                                .watchHistoryDetail(
                                    sourceID: sourceID,
                                    episodeID: episodeID,
                                    sessionID: sessionID,
                                    showsSavedConfirmation: false
                                )
                            )
                        }
                    )
                case let .watchingSetup(sourceID, episodeID):
                    WatchingModeSetupView(
                        sourceID: sourceID,
                        episodeID: episodeID,
                        sourceRepository: sourceRepository,
                        pairRepository: pairRepository,
                        onReady: { selection in
                            navigationPath.append(.watchingMode(selection))
                        },
                        onClose: closeWatchingMode
                    )
                case let .watchingMode(selection):
                    WatchingModeView(
                        selection: selection,
                        repository: sourceRepository,
                        pairRepository: pairRepository,
                        momentStore: momentStore,
                        settingsStore: settingsStore,
                        onFinished: { sourceID, episodeID, sessionID in
                            navigationPath = [
                                .sourceDetail(sourceID),
                                .episodeDetail(
                                    sourceID: sourceID,
                                    episodeID: episodeID,
                                    initialSection: .watchHistory
                                ),
                                .watchHistoryDetail(
                                    sourceID: sourceID,
                                    episodeID: episodeID,
                                    sessionID: sessionID,
                                    showsSavedConfirmation: true
                                ),
                            ]
                        },
                        onDiscard: closeWatchingMode
                    )
                case let .watchHistoryDetail(
                    sourceID,
                    episodeID,
                    sessionID,
                    showsSavedConfirmation
                ):
                    WatchHistoryDetailView(
                        sourceID: sourceID,
                        episodeID: episodeID,
                        sessionID: sessionID,
                        showsSavedConfirmation: showsSavedConfirmation,
                        repository: sourceRepository,
                        pairRepository: pairRepository,
                        momentStore: momentStore
                    )
                case .momentDetail(let momentID):
                    MomentDetailView(
                        store: momentStore,
                        momentID: momentID,
                        onEdit: { momentID in
                            navigationPath.append(.momentEdit(momentID))
                        },
                        onDelete: { momentID in
                            guard navigationPath.last == .momentDetail(momentID) else { return }
                            navigationPath.removeLast()
                        },
                        onOpenPair: { pairID in
                            navigationPath.append(.pairDetail(pairID))
                        },
                        onOpenMoment: { momentID in
                            navigationPath.append(.momentDetail(momentID))
                        }
                    )
                case .momentEdit(let momentID):
                    if let moment = momentStore.moment(id: momentID) {
                        MomentEditView(
                            viewModel: MomentEditViewModel(
                                moment: moment,
                                pairRepository: pairRepository,
                                sourceRepository: sourceRepository
                            ),
                            onSave: { draft, imageChanges in
                                do {
                                    return try await momentStore.update(
                                        id: momentID,
                                        draft: draft,
                                        imageChanges: imageChanges
                                    )
                                } catch {
                                    return false
                                }
                            },
                            onClose: popMomentEdit
                        )
                    } else {
                        ContentUnavailableView(
                            AppStrings.momentDetailMissingTitle,
                            systemImage: "sparkles"
                        )
                    }
                case let .newMoment(pairID, sourceID, episodeID):
                    NewMomentFlowView(
                        viewModel: NewMomentCreationViewModel(
                            pairRepository: pairRepository,
                            sourceRepository: sourceRepository,
                            initialPairID: pairID,
                            initialSourceID: sourceID,
                            initialEpisodeID: episodeID
                        ),
                        onSave: { draft in
                            momentStore.add(draft: draft)
                            closeNewMomentFlow()
                        },
                        onCancel: requestNewMomentCancellation
                    )
                case .editProfile:
                    EditProfileView(profileStore: profileStore, onBack: popProfileRoute)
                case .settings:
                    SettingsView(
                        settingsStore: settingsStore,
                        purchaseService: appDataStore.purchaseService,
                        cloudSyncService: appDataStore.cloudSyncService,
                        backupService: appDataStore.backupService,
                        supportLinks: appDataStore.supportLinks,
                        onBack: popProfileRoute,
                        onOpenPremium: { navigationPath.append(.premium) },
                        onOpenAbout: { navigationPath.append(.about) },
                        onDeleteAll: appDataStore.deleteAllContent,
                        onRestoreCompleted: {
                            try await appDataStore.reloadRestoredContent()
                            navigationPath.removeAll()
                            selectedTab = .home
                            isProfileDrawerPresented = false
                        }
                    )
                case .about:
                    AboutView(supportLinks: appDataStore.supportLinks, onBack: popProfileRoute)
                case .helpFeedback:
                    HelpFeedbackView(supportLinks: appDataStore.supportLinks, onBack: popProfileRoute)
                case .premium:
                    PremiumView(
                        purchaseService: appDataStore.purchaseService,
                        onBack: popProfileRoute
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .overlay {
            if isDiscardConfirmationPresented {
                NewMomentDiscardConfirmationOverlay(
                    onKeepEditing: {
                        isDiscardConfirmationPresented = false
                    },
                    onDiscard: {
                        isDiscardConfirmationPresented = false
                        closeNewMomentFlow()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: isDiscardConfirmationPresented)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if shouldShowBottomTabBar {
                BottomTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
        .overlay {
            if isProfileDrawerPresented {
                ProfileDrawerView(
                    profileStore: profileStore,
                    onDismiss: closeProfileDrawer,
                    onEditProfile: { openProfileRoute(.editProfile) },
                    onOpenPremium: { openProfileRoute(.premium) },
                    onOpenSettings: { openProfileRoute(.settings) },
                    onOpenHelp: { openProfileRoute(.helpFeedback) }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(
            accessibilityReduceMotion ? .none : .spring(duration: 0.34, bounce: 0.08),
            value: isProfileDrawerPresented
        )
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            setKeyboardVisible(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            setKeyboardVisible(false)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            guard oldTab != newTab else { return }
            resetNavigationForTabChange()
        }
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .home:
            HomeView(
                momentStore: momentStore,
                profileStore: profileStore,
                onOpenProfile: {
                    isProfileDrawerPresented = true
                },
                onCreateMoment: {
                    navigationPath.append(.newMoment(sourceID: nil, episodeID: nil))
                },
                onOpenMoment: { navigationPath.append(.momentDetail($0)) }
            )
        case .pairs:
            PairListView(repository: pairRepository) { pair in
                navigationPath.append(.pairDetail(pair.id))
            }
        case .moments:
            MomentListView(
                store: momentStore,
                onCreateMoment: {
                    navigationPath.append(.newMoment(sourceID: nil, episodeID: nil))
                },
                onOpenMoment: { navigationPath.append(.momentDetail($0)) }
            )
        case .sources:
            SourceListView(
                repository: sourceRepository,
                onOpenSource: { navigationPath.append(.sourceDetail($0)) }
            )
        }
    }

    private var shouldShowBottomTabBar: Bool {
        AppChromeVisibility.shouldShowBottomTabBar(
            navigationHidesBottomTabBar: navigationPath.last?.hidesBottomTabBar ?? false,
            isKeyboardVisible: isKeyboardVisible
        )
    }

    private func setKeyboardVisible(_ isVisible: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isKeyboardVisible = isVisible
        }
    }

    private func resetNavigationForTabChange() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            navigationPath.removeAll()
            isDiscardConfirmationPresented = false
            isProfileDrawerPresented = false
        }
    }

    private func requestNewMomentCancellation(hasInput: Bool) {
        if hasInput {
            isDiscardConfirmationPresented = true
        } else {
            closeNewMomentFlow()
        }
    }

    private func closeNewMomentFlow() {
        navigationPath.removeAll { route in
            switch route {
            case .newMoment:
                return true
            case .pairDetail,
                 .sourceDetail,
                 .episodeDetail,
                 .watchHistoryDetail,
                 .watchingSetup,
                 .watchingMode,
                 .momentDetail,
                 .momentEdit,
                 .editProfile,
                 .settings,
                 .about,
                 .helpFeedback,
                 .premium:
                return false
            }
        }
    }

    private func popMomentEdit() {
        guard case .momentEdit = navigationPath.last else { return }
        navigationPath.removeLast()
    }

    private func closeWatchingMode() {
        navigationPath.removeAll { route in
            switch route {
            case .watchingSetup, .watchingMode:
                true
            case .pairDetail,
                 .sourceDetail,
                 .episodeDetail,
                 .watchHistoryDetail,
                 .momentDetail,
                 .momentEdit,
                 .newMoment,
                 .editProfile,
                 .settings,
                 .about,
                 .helpFeedback,
                 .premium:
                false
            }
        }
    }

    private func closeProfileDrawer() {
        isProfileDrawerPresented = false
    }

    private func openProfileRoute(_ route: AppRoute) {
        isProfileDrawerPresented = false
        navigationPath.append(route)
    }

    private func popProfileRoute() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

}

private struct PlaceholderTabView: View {
    let tab: MainTab

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer(minLength: 0)

            if tab == .moments {
                MomentSparkleIcon(color: .appPrimary, width: 22, height: 34)
            } else {
                Image(systemName: tab.iconName)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.appPrimary)
            }

            Text(tab.title)
                .font(AppTypography.titleMedium())
                .foregroundStyle(Color.textPrimary)

            Text("Home 実装を先に固定しています。")
                .font(AppTypography.body())
                .foregroundStyle(Color.textSecondary)

            Spacer(minLength: 160)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AppRootView()
}
