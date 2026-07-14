import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: MainTab = .home
    @State private var navigationPath: [AppRoute] = []
    @State private var isDiscardConfirmationPresented = false
    private let pairRepository: any PairRepository = InMemoryPairRepository()
    private let sourceRepository: any SourceRepository = InMemorySourceRepository()

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
                    PairDetailView(pairID: pairID)
                case .newMomentStep1:
                    NewMomentStep1View(
                        viewModel: NewMomentStep1ViewModel(
                            pairRepository: pairRepository,
                            sourceRepository: sourceRepository
                        ),
                        onContinue: { draft in
                            pushNewMomentRoute(.newMomentStep2(draft))
                        },
                        onCancel: requestNewMomentCancellation
                    )
                case .newMomentStep2(let draft):
                    NewMomentStep2View(
                        viewModel: NewMomentStep2ViewModel(draft: draft),
                        onContinue: { draft in
                            pushNewMomentRoute(.newMomentStep3(draft))
                        },
                        onCancel: requestNewMomentCancellation,
                        onBackToStep1: returnToNewMomentStep1
                    )
                case .newMomentStep3(let draft):
                    NewMomentStep3View(
                        viewModel: NewMomentStep3ViewModel(draft: draft),
                        onContinue: { draft in
                            pushNewMomentRoute(.newMomentStep4(draft))
                        },
                        onCancel: requestNewMomentCancellation,
                        onBackToStep1: returnToNewMomentStep1,
                        onBackToStep2: returnToNewMomentStep2
                    )
                case .newMomentStep4(let draft):
                    NewMomentStep4View(
                        viewModel: NewMomentStep4ViewModel(draft: draft),
                        onSave: { _ in
                            closeNewMomentFlow()
                        },
                        onCancel: requestNewMomentCancellation,
                        onBackToStep1: returnToNewMomentStep1,
                        onBackToStep2: returnToNewMomentStep2,
                        onBackToStep3: returnToNewMomentStep3
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
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .home:
            HomeView {
                navigationPath.append(.newMomentStep1)
            }
        case .pairs:
            PairListView { pair in
                navigationPath.append(.pairDetail(pair.id))
            }
        case .moments, .sources:
            PlaceholderTabView(tab: selectedTab)
        }
    }

    private var shouldShowBottomTabBar: Bool {
        !(navigationPath.last?.hidesBottomTabBar ?? false)
    }

    private func pushNewMomentRoute(_ route: AppRoute) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            navigationPath.append(route)
        }
    }

    private func requestNewMomentCancellation() {
        isDiscardConfirmationPresented = true
    }

    private func closeNewMomentFlow() {
        navigationPath.removeAll { route in
            switch route {
            case .newMomentStep1, .newMomentStep2, .newMomentStep3, .newMomentStep4:
                return true
            case .pairDetail:
                return false
            }
        }
    }

    private func returnToNewMomentStep1() {
        trimNewMomentPath { route in
            if case .newMomentStep1 = route {
                return .newMomentStep1
            }

            return nil
        }
    }

    private func returnToNewMomentStep2(draft: NewMomentDraft) {
        trimNewMomentPath { route in
            if case .newMomentStep2 = route {
                return .newMomentStep2(draft)
            }

            return nil
        }
    }

    private func returnToNewMomentStep3(draft: NewMomentDraft) {
        trimNewMomentPath { route in
            if case .newMomentStep3 = route {
                return .newMomentStep3(draft)
            }

            return nil
        }
    }

    private func trimNewMomentPath(replacementForTarget: (AppRoute) -> AppRoute?) {
        guard let targetIndex = navigationPath.indices.first(where: { index in
            replacementForTarget(navigationPath[index]) != nil
        }) else {
            return
        }

        guard let replacement = replacementForTarget(navigationPath[targetIndex]) else {
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            navigationPath[targetIndex] = replacement
            let nextIndex = navigationPath.index(after: targetIndex)
            if nextIndex < navigationPath.endIndex {
                navigationPath.removeSubrange(nextIndex..<navigationPath.endIndex)
            }
        }
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
