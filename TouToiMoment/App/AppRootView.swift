import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            currentTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            BottomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .pairs, .moments, .sources:
            PlaceholderTabView(tab: selectedTab)
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
