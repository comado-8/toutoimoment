import SwiftUI

struct PairListView: View {
    var onSelectPair: (PairListCardModel) -> Void = { _ in }

    @State private var selectedFilter: PairListFilter = .all
    @State private var pairs = PairListPreviewData.pairs

    var body: some View {
        GeometryReader { geometry in
            let profile = PairListLayoutProfile(size: geometry.size)

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, profile.headerTop)

                filterRow
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, profile.filterTop)

                ScrollView(.vertical, showsIndicators: true) {
                    pairList
                        .padding(.top, profile.listTop)
                        .padding(.bottom, profile.scrollBottomPadding)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .animation(.spring(duration: 0.34, bounce: 0.15), value: selectedFilter)
            .animation(
                .spring(duration: 0.34, bounce: 0.15),
                value: pairs.map(\.isFavorite)
            )
        }
    }

    private var header: some View {
        Text(AppStrings.tabPairs)
            .font(AppTypography.heroTitle())
            .foregroundStyle(Color.textPrimary)
            .accessibilityIdentifier("pairs.title")
    }

    private var filterRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            FilterChip(
                title: AppStrings.pairsFilterAll,
                isSelected: selectedFilter == .all,
                showsHeart: false
            ) {
                selectedFilter = .all
            }
            .accessibilityIdentifier("pairs.filter.all")

            FilterChip(
                title: AppStrings.pairsFilterFavorite,
                isSelected: selectedFilter == .favorite,
                showsHeart: true
            ) {
                selectedFilter = .favorite
            }
            .accessibilityIdentifier("pairs.filter.favorite")
        }
    }

    private var pairList: some View {
        VStack(spacing: 10) {
            NewPairCard()
                .accessibilityIdentifier("pairs.new_pair")

            ForEach(displayedPairs) { pair in
                PairListCard(
                    pair: pair,
                    onTap: { onSelectPair(pair) },
                    onToggleFavorite: { toggleFavorite(id: pair.id) }
                )
                .accessibilityIdentifier("pairs.card.\(pair.id)")
            }
        }
        .padding(.horizontal, 16)
    }

    private var displayedPairs: [PairListCardModel] {
        switch selectedFilter {
        case .all:
            return pairs
        case .favorite:
            return pairs.filter(\.isFavorite)
        }
    }

    private func toggleFavorite(id: String) {
        guard let index = pairs.firstIndex(where: { $0.id == id }) else {
            return
        }

        pairs[index].isFavorite.toggle()
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let showsHeart: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if showsHeart {
                    FavoriteHeartIcon(
                        isFilled: isSelected,
                        size: 16
                    )
                }

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.white : Color.appPrimarySoft)
            .padding(.horizontal, 16)
            .frame(height: 33)
            .background(background)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Capsule(style: .continuous)
                .fill(Color.appPrimary)
        } else {
            Capsule(style: .continuous)
                .fill(Color.surfaceLight.opacity(0.92))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.appPrimaryTint, lineWidth: 1)
                }
        }
    }
}

private struct NewPairCard: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))

                Text(AppStrings.pairsNewPair)
                    .font(.system(size: 17, weight: .bold))

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .glassCard(cornerRadius: 20, fillOpacity: 0.60)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppStrings.pairsNewPair)
    }
}

private struct PairListLayoutProfile {
    let headerTop: CGFloat
    let filterTop: CGFloat
    let listTop: CGFloat
    let scrollBottomPadding: CGFloat

    init(size: CGSize) {
        if size.height < 760 {
            headerTop = 20
            filterTop = 14
            listTop = 20
            scrollBottomPadding = AppTheme.Layout.bottomTabBarReservedHeight
        } else {
            headerTop = 28
            filterTop = 16
            listTop = 20
            scrollBottomPadding = AppTheme.Layout.bottomTabBarReservedHeight
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        PairListView()

        BottomTabBar(selectedTab: .constant(.pairs))
            .padding(.bottom, 8)
    }
}
