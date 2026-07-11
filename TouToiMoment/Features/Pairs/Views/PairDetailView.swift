import SwiftUI

struct PairDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pair: PairDetailModel

    init(pairID: String) {
        _pair = State(initialValue: PairDetailPreviewData.detail(for: pairID))
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, 8)

                PairHeroCard(
                    pair: pair,
                    onToggleFavorite: { pair.isFavorite.toggle() }
                )
                .padding(.top, 6)
                .padding(.bottom, 28)

                RecentMomentsSection(
                    moments: pair.recentMoments,
                    onToggleFavorite: toggleRecentMomentFavorite
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toggleRecentMomentFavorite(id: String) {
        guard let index = pair.recentMoments.firstIndex(where: { $0.id == id }) else {
            return
        }

        pair.recentMoments[index].isFavorite.toggle()
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: { dismiss() }) {
                    iconButtonBackground {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.pairDetailBackButton)

                Spacer()

                Button(action: {}) {
                    iconButtonBackground {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.pairDetailEditButton)
            }

            Text(AppStrings.pairDetailTitle)
                .font(AppTypography.titleMedium())
                .foregroundStyle(Color.textPrimary)
                .accessibilityIdentifier("pair_detail.title")
        }
        .frame(height: 60)
    }

    private func iconButtonBackground<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.28))

            content()
        }
        .frame(width: 44, height: 44)
    }
}

private struct PairHeroCard: View {
    let pair: PairDetailModel
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(pair.displayName)
                        .font(.custom("InstrumentSerif-Regular", size: 32))
                        .foregroundStyle(Color.textPrimary)
                        .accessibilityIdentifier("pair_detail.name")

                    Text(pair.titleLabel)
                        .font(.custom("Geist-Regular", size: 13))
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                }

                Spacer(minLength: 12)

                Button(action: onToggleFavorite) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.4))

                        Circle()
                            .stroke(Color.white, lineWidth: 1)

                        FavoriteHeartIcon(isFilled: pair.isFavorite, size: 24)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.pairsFavoriteToggleLabel(name: pair.displayName))
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [pair.leadingColor, pair.trailingColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

            HStack(spacing: 10) {
                PairStatCard(
                    value: "\(pair.momentCount)",
                    label: AppStrings.pairDetailStatMoments,
                    isFilled: true
                )

                PairStatCard(
                    value: pair.lastLabel,
                    label: AppStrings.pairDetailStatLast,
                    isFilled: false
                )

                PairStatCard(
                    value: pair.sinceLabel,
                    label: AppStrings.pairDetailStatSince,
                    isFilled: false
                )
            }
        }
        .padding(24)
        .glassCard(cornerRadius: 28, fillOpacity: 0.60)
        .padding(.horizontal, AppTheme.Spacing.screen)
    }
}

private struct PairStatCard: View {
    let value: String
    let label: String
    let isFilled: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Geist-Bold", size: 20))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.custom("Geist-SemiBold", size: 10))
                .tracking(0.8)
                .foregroundStyle(Color(hex: "#9B9EC4"))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isFilled ? Color.surfaceLight : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.appPrimaryTint, lineWidth: 1)
                }
        }
    }
}

private struct RecentMomentsSection: View {
    let moments: [PairDetailMomentModel]
    let onToggleFavorite: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(AppStrings.pairDetailRecentMomentsTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityIdentifier("pair_detail.recent_moments.title")

                Spacer(minLength: 12)

                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary)

                        MomentSparkleIcon(color: .white, width: 13, height: 21)
                    }
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.appPrimary.opacity(0.2), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.pairDetailNewMomentButton)
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 10) {
                    ForEach(moments) { moment in
                        PairRecentMomentRow(
                            moment: moment,
                            onToggleFavorite: { onToggleFavorite(moment.id) }
                        )
                    }
                }
                .padding(.bottom, AppTheme.Layout.bottomTabBarReservedHeight)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct PairRecentMomentRow: View {
    let moment: PairDetailMomentModel
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(moment.sourceTitle)
                    Text(moment.episodeLabel)
                    Text(moment.timestampLabel)
                }
                .font(.custom("Geist-Medium", size: 11))
                .foregroundStyle(Color(hex: "#8888AA"))

                Text(moment.quote)
                    .font(.custom("NotoSansJP-Thin_Medium", size: 14))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

            Button(action: onToggleFavorite) {
                FavoriteStarIcon(
                    variant: moment.isFavorite ? .on : .default,
                    width: 20,
                    height: 20
                )
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appPrimarySoft)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 63)
        .glassCard(cornerRadius: 16, fillOpacity: 0.60)
    }
}
