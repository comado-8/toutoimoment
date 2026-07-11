import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var selectionNamespace

    private let selectionAnimation = Animation.spring(duration: 0.46, bounce: 0.14)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    selectionNamespace: selectionNamespace
                ) {
                    withAnimation(selectionAnimation) {
                        selectedTab = tab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(4)
        .frame(width: 315, height: 60)
        .background {
            TabBarBackground()
        }
        .animation(selectionAnimation, value: selectedTab)
    }
}

private struct TabBarItem: View {
    let tab: MainTab
    let isSelected: Bool
    let selectionNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: -2) {
                tabIcon

                Text(tab.title)
                    .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))
                    .tracking(-0.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .allowsTightening(true)
            }
            .foregroundStyle(isSelected ? Color.appPrimary : Color.tabBarMuted)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 7)
            .background(alignment: .center) {
                if isSelected {
                    TabBarSelectionPill()
                        .matchedGeometryEffect(id: "tabSelectionPill", in: selectionNamespace)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tabIcon: some View {
        if tab == .moments {
            MomentSparkleIcon(
                color: isSelected ? .appPrimary : .tabBarMuted,
                width: 16,
                height: 23
            )
        } else {
            Image(systemName: isSelected ? tab.selectedIconName : tab.iconName)
                .font(.system(size: 19, weight: isSelected ? .medium : .regular))
        }
    }

    private var horizontalPadding: CGFloat {
        if isSelected && tab == .moments {
            return 14
        }

        return isSelected ? 16 : 9
    }
}

private struct TabBarBackground: View {
    private let overlayGradient = LinearGradient(
        stops: [
            .init(
                color: Color(red: 0.77, green: 0.71, blue: 0.94).opacity(0.19),
                location: 0
            ),
            .init(color: .white.opacity(0), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            backgroundLayer
                .blur(radius: 8)

            backgroundLayer
        }
        .shadow(
            color: Color(red: 0.31, green: 0.27, blue: 0.62).opacity(0.15),
            radius: 11,
            x: 0,
            y: 6
        )
        .shadow(color: .black.opacity(0.06), radius: 1.95, x: 0, y: 1)
        .overlay {
            Capsule(style: .continuous)
                .inset(by: 0.5)
                .stroke(
                    Color(red: 0.68, green: 0.65, blue: 0.92).opacity(0.45),
                    lineWidth: 1
                )
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.6))

            Capsule(style: .continuous)
                .fill(overlayGradient)
        }
    }
}

private struct TabBarSelectionPill: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(0.32))
            .shadow(
                color: Color(
                    red: 0.25,
                    green: 0.23,
                    blue: 0.97
                ).opacity(0.12),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        BottomTabBar(selectedTab: .constant(.home))
            .padding(.bottom, 18)
    }
}
