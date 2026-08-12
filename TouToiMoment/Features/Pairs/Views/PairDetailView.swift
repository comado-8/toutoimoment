import SwiftUI

struct PairDetailView: View {
    @Environment(\.dismiss) private var dismiss
    private let pairID: String
    private let repository: any PairRepository
    @ObservedObject private var momentStore: MomentStore
    private let onCreateMoment: () -> Void
    private let onUpdated: (PairSummary) -> Void
    private let onDeleted: (String) -> Void
    private let onOpenMoment: (String) -> Void
    @State private var pair: PairDetailModel
    @State private var pairSummary: PairSummary?
    @State private var isEditPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var mutationErrorMessage: String?
    @State private var isDeleting = false

    init(
        pairID: String,
        repository: any PairRepository = InMemoryPairRepository(),
        momentStore: MomentStore,
        onCreateMoment: @escaping () -> Void = {},
        onUpdated: @escaping (PairSummary) -> Void = { _ in },
        onDeleted: @escaping (String) -> Void = { _ in },
        onOpenMoment: @escaping (String) -> Void = { _ in }
    ) {
        self.pairID = pairID
        self.repository = repository
        self.momentStore = momentStore
        self.onCreateMoment = onCreateMoment
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        self.onOpenMoment = onOpenMoment
        _pair = State(initialValue: PairDetailPreviewData.detail(for: pairID))
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PairHeroCard(
                    pair: pair,
                    onToggleFavorite: togglePairFavorite
                )
                .padding(.top, 14)
                .padding(.bottom, 28)

                RecentMomentsSection(
                    moments: pairMoments,
                    onCreateMoment: onCreateMoment,
                    onOpenMoment: onOpenMoment,
                    onToggleFavorite: momentStore.toggleFavorite
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(AppStrings.pairDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isEditPresented = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.appPrimary.opacity(0.14))
                .accessibilityLabel(AppStrings.pairDetailEditButton)
                .accessibilityIdentifier("pair_detail.edit")
                .disabled(pairSummary == nil)

                Menu {
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        DestructiveMenuLabel(title: AppStrings.pairDetailDelete)
                    }
                    .tint(Color.red)
                    .accessibilityIdentifier("pair_detail.delete")
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.white.opacity(0.72))
                .foregroundStyle(Color.appPrimary)
                .accessibilityLabel(AppStrings.pairDetailMore)
                .accessibilityIdentifier("pair_detail.more")
                .disabled(pairSummary == nil || isDeleting)
            }
        }
        .sheet(isPresented: $isEditPresented) {
            if let pairSummary {
                PairEditorSheet(
                    pair: pairSummary,
                    updateAction: { request in
                        try await repository.updatePair(id: pairID, request: request)
                    },
                    onUpdated: { updated in
                        apply(updated)
                        onUpdated(updated)
                    }
                )
            }
        }
        .confirmationDialog(
            AppStrings.pairDetailDeleteConfirmationTitle,
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.pairDetailDelete, role: .destructive) {
                Task { await deletePair() }
            }
            Button(AppStrings.newMomentStep1NewPairCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.pairDetailDeleteConfirmationMessage)
        }
        .alert(
            AppStrings.pairDetailMutationError,
            isPresented: Binding(
                get: { mutationErrorMessage != nil },
                set: { if !$0 { mutationErrorMessage = nil } }
            )
        ) {
            Button(AppStrings.commonOK, role: .cancel) {}
        }
        .task {
            do {
                try await reloadPair()
            } catch {
                mutationErrorMessage = AppStrings.pairDetailMutationError
            }
        }
    }

    private var pairMoments: [MomentCardModel] {
        momentStore.moments
            .filter { $0.pairID == pairID }
            .sorted { lhs, rhs in
                if lhs.momentDate != rhs.momentDate {
                    return lhs.momentDate > rhs.momentDate
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    private func togglePairFavorite() {
        Task {
            do {
                try await repository.toggleFavorite(id: pairID)
                try await reloadPair()
            } catch {
                mutationErrorMessage = AppStrings.pairDetailMutationError
            }
        }
    }

    private func reloadPair() async throws {
        guard let summary = try await repository.fetchPairs().first(where: { $0.id == pairID }) else {
            throw PairRepositoryError.pairNotFound
        }
        apply(summary)
    }

    private func apply(_ summary: PairSummary) {
        pairSummary = summary
        pair = PairDetailModel(
            id: summary.id,
            displayName: summary.displayName,
            titleLabel: summary.subtitle,
            momentCount: summary.momentCount,
            lastLabel: pair.lastLabel,
            sinceLabel: pair.sinceLabel,
            leadingColor: Color(hex: summary.leadingColorHex),
            trailingColor: Color(hex: summary.trailingColorHex ?? summary.leadingColorHex),
            isFavorite: summary.isFavorite,
            recentMoments: pair.recentMoments
        )
    }

    private func deletePair() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await repository.deletePair(id: pairID)
            onDeleted(pairID)
            dismiss()
        } catch {
            mutationErrorMessage = AppStrings.pairDetailMutationError
        }
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

                    if !pair.titleLabel.isEmpty {
                        Text(pair.titleLabel)
                            .font(.custom("Geist-Regular", size: 13))
                            .foregroundStyle(Color(hex: "#9B9EC4"))
                    }
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

        }
        .padding(24)
        .glassCard(cornerRadius: 28, fillOpacity: 0.60)
        .padding(.horizontal, AppTheme.Spacing.screen)
    }
}

private struct RecentMomentsSection: View {
    let moments: [MomentCardModel]
    let onCreateMoment: () -> Void
    let onOpenMoment: (String) -> Void
    let onToggleFavorite: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(AppStrings.pairDetailRecentMomentsTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityIdentifier("pair_detail.recent_moments.title")

                Spacer(minLength: 10)

                Text("\(moments.count)")
                    .font(.custom("Geist-Bold", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 24)
                    .background(Color.appPrimary, in: Capsule())
                    .accessibilityLabel(AppStrings.newMomentStep1MomentCount(count: moments.count))
                    .accessibilityIdentifier("pair_detail.moments.count")

                Button(action: onCreateMoment) {
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
                .accessibilityIdentifier("pair_detail.new_moment")
            }

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 10) {
                    ForEach(moments) { moment in
                        PairRecentMomentRow(
                            moment: moment,
                            onOpen: { onOpenMoment(moment.id) },
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
    let moment: MomentCardModel
    let onOpen: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    Text(moment.momentDate.cardText())
                        .font(.custom("Geist-Bold", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.appPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(width: 54, alignment: .leading)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(moment.cardSourceLabel)
                            if let episode = moment.episodeDisplayLabel {
                                Text(episode)
                            }
                            if let context = MomentContextDisplayFormatter
                                .compactSummary(for: moment)
                                .trimmedOrNil {
                                Text(context)
                            }
                        }
                        .font(.custom("Geist-Medium", size: 11))
                        .foregroundStyle(Color(hex: "#8888AA"))
                        .lineLimit(1)

                        Text(moment.displayHeading)
                            .font(.custom("NotoSansJP-Thin_Medium", size: 14))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onToggleFavorite) {
                FavoriteStarIcon(
                    variant: moment.isFavorite ? .on : .default,
                    width: 20,
                    height: 20
                )
            }
            .buttonStyle(.plain)

            Button(action: onOpen) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appPrimarySoft)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.momentDetailTitle)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 63)
        .glassCard(cornerRadius: 16, fillOpacity: 0.60)
        .accessibilityIdentifier("pair_detail.moment.\(moment.id)")
    }
}
