import SwiftUI

struct SourceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SourceDetailViewModel
    @ObservedObject private var momentStore: MomentStore
    @State private var isEditPresented = false
    @State private var isNewEpisodePresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isDeleting = false

    private let onUpdated: (SourceSummary) -> Void
    private let onDeleted: (String) -> Void
    private let onOpenEpisode: (String, String) -> Void
    private let onOpenMoment: (String) -> Void

    init(
        sourceID: String,
        repository: any SourceRepository,
        momentStore: MomentStore,
        onOpenEpisode: @escaping (String, String) -> Void = { _, _ in },
        onOpenMoment: @escaping (String) -> Void = { _ in },
        onUpdated: @escaping (SourceSummary) -> Void = { _ in },
        onDeleted: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: SourceDetailViewModel(
                sourceID: sourceID,
                repository: repository
            )
        )
        _momentStore = ObservedObject(wrappedValue: momentStore)
        self.onOpenEpisode = onOpenEpisode
        self.onOpenMoment = onOpenMoment
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home, motionEnabled: false)
                .ignoresSafeArea()
                .opacity(0.68)

            content
        }
        .navigationTitle(AppStrings.sourceDetailTitle)
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
                .accessibilityLabel(AppStrings.sourceDetailEdit)
                .accessibilityIdentifier("source_detail.edit")
                .disabled(viewModel.detail == nil)

                Menu {
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        DestructiveMenuLabel(title: AppStrings.sourceDetailDelete)
                    }
                    .tint(Color.red)
                    .accessibilityIdentifier("source_detail.delete")
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.white.opacity(0.72))
                .foregroundStyle(Color.appPrimary)
                .accessibilityLabel(AppStrings.sourceDetailMore)
                .accessibilityIdentifier("source_detail.more")
                .disabled(viewModel.detail == nil || isDeleting)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(isPresented: $isEditPresented) {
            if let source = viewModel.detail?.summary {
                NewSourceSheet(
                    source: source,
                    updateAction: { request in
                        try await viewModel.updateSource(request)
                    },
                    onUpdated: onUpdated
                )
            }
        }
        .sheet(isPresented: $isNewEpisodePresented) {
            if let source = viewModel.detail?.summary {
                let schema = SourceLocatorSchema.schema(for: source.mediaType)
                    ?? SourceLocatorSchema.fallback
                NewEpisodeSheet(
                    schema: schema,
                    saveAction: { request in
                        try await viewModel.createEpisode(request)
                    }
                )
            }
        }
        .confirmationDialog(
            AppStrings.sourceDetailDeleteConfirmationTitle,
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.sourceDetailDelete, role: .destructive) {
                Task { await deleteSource() }
            }
            Button(AppStrings.newMomentStep1NewSourceCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.sourceDetailDeleteConfirmationMessage)
        }
        .alert(
            AppStrings.sourceDetailMutationError,
            isPresented: Binding(
                get: { viewModel.mutationErrorMessage != nil },
                set: { if !$0 { viewModel.clearMutationError() } }
            )
        ) {
            Button(AppStrings.commonOK, role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("source_detail.loading")
        case .missing, .failed:
            SourceDetailFailureView {
                Task { await viewModel.retry() }
            }
        case .loaded:
            if let detail = viewModel.detail {
                detailContent(detail)
            }
        }
    }

    private func detailContent(_ detail: SourceDetail) -> some View {
        let schema = SourceLocatorSchema.schema(for: detail.summary.mediaType)
            ?? SourceLocatorSchema.fallback
        let directMoments = SourceMomentProjection.directMoments(
            sourceID: detail.id,
            supportsEpisodes: schema.supportsEpisodes,
            moments: momentStore.moments
        )
        return ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                SourceHeroSection(detail: detail)

                if schema.supportsEpisodes {
                    SourceEpisodeSection(
                        detail: detail,
                        dateText: { viewModel.relativeDateText(for: $0) },
                        onAddEpisode: { isNewEpisodePresented = true },
                        onOpenEpisode: { episodeID in
                            onOpenEpisode(detail.id, episodeID)
                        }
                    )
                    .padding(.top, 18)

                    if !directMoments.isEmpty {
                        SourceMomentSection(
                            title: AppStrings.sourceDetailOtherMoments,
                            moments: directMoments,
                            showsEmptyState: false,
                            momentStore: momentStore,
                            onOpenMoment: onOpenMoment
                        )
                        .padding(.top, 28)
                    }
                } else {
                    SourceMomentSection(
                        title: AppStrings.sourceDetailMoments,
                        moments: directMoments,
                        showsEmptyState: true,
                        momentStore: momentStore,
                        onOpenMoment: onOpenMoment
                    )
                    .padding(.top, 18)
                }
            }
            .padding(.bottom, AppTheme.Layout.bottomTabBarReservedHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteSource() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await viewModel.deleteSource()
            onDeleted(viewModel.sourceID)
            dismiss()
        } catch {}
    }
}

private struct SourceHeroSection: View {
    let detail: SourceDetail

    var body: some View {
        ZStack(alignment: .top) {
            SourceThumbnailView(sourceID: detail.id, cornerRadius: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(.rect(
                    bottomLeadingRadius: 28,
                    bottomTrailingRadius: 28
                ))

            VStack(alignment: .leading, spacing: 14) {
                Text(detail.summary.displayName)
                    .font(sourceTitleFont)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .accessibilityIdentifier("source_detail.name")

                Text(detail.summary.contextualHelperText)
                    .font(.custom("Geist-SemiBold", size: 11, relativeTo: .caption2))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.appAccentSoft, in: Capsule())
                    .overlay {
                        Capsule().stroke(Color.appAccent, lineWidth: 1)
                    }

                Link(destination: detail.summary.relatedURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text(AppStrings.sourceDetailRelatedURL)
                        Spacer()
                        Text(detail.summary.relatedURL.host ?? detail.summary.relatedURL.absoluteString)
                            .lineLimit(1)
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.custom("Geist-Medium", size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.appPrimary)
                }
                .accessibilityIdentifier("source_detail.related_url")
            }
            .padding(20)
            .glassCard(cornerRadius: 24, fillOpacity: 0.60)
            .padding(.horizontal, AppTheme.Spacing.screen)
            .offset(y: 160)
        }
        .frame(height: 348, alignment: .top)
    }

    private var sourceTitleFont: Font {
        MomentShareEpisodeTypography.usesJapaneseFont(for: detail.summary.displayName)
            ? .custom("ZenAntique-Regular", size: 28, relativeTo: .title)
            : .custom("InstrumentSerif-Regular", size: 28, relativeTo: .title)
    }
}

private struct SourceEpisodeSection: View {
    let detail: SourceDetail
    let dateText: (EpisodeSummary) -> String
    let onAddEpisode: () -> Void
    let onOpenEpisode: (String) -> Void

    private var schema: SourceLocatorSchema {
        SourceLocatorSchema.schema(for: detail.summary.mediaType)
            ?? SourceLocatorSchema.fallback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(AppStrings.sourceDetailEpisodes)
                    .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                    .foregroundStyle(Color.textPrimary)

                Text("\(detail.episodes.count)")
                    .font(.custom("Geist-Bold", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.surfaceLight, in: Capsule())

                Spacer()

                Button(action: onAddEpisode) {
                    Image(systemName: "plus")
                        .font(.system(size: 25, weight: .regular))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.appPrimary)
                .accessibilityLabel(AppStrings.sourceDetailAddEpisode)
                .accessibilityIdentifier("source_detail.add_episode")
            }

            if detail.episodes.isEmpty {
                ContentUnavailableView(
                    AppStrings.sourceDetailEmptyEpisodesTitle,
                    systemImage: "rectangle.stack",
                    description: Text(AppStrings.sourceDetailEmptyEpisodesMessage)
                )
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("source_detail.episodes.empty")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(detail.episodes) { episode in
                        SourceEpisodeRow(
                            episode: episode,
                            displayName: schema.episodeDisplayName(for: episode.locatorValues),
                            updatedText: dateText(episode),
                            action: { onOpenEpisode(episode.id) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
    }
}

private struct SourceMomentSection: View {
    let title: String
    let moments: [MomentCardModel]
    let showsEmptyState: Bool
    @ObservedObject var momentStore: MomentStore
    let onOpenMoment: (String) -> Void

    @State private var facesByMomentID: [String: MomentFace] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                    .foregroundStyle(Color.textPrimary)

                Text("\(moments.count)")
                    .font(.custom("Geist-Bold", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.surfaceLight, in: Capsule())

                Spacer()
            }

            if moments.isEmpty, showsEmptyState {
                ContentUnavailableView(
                    AppStrings.sourceDetailEmptyMomentsTitle,
                    systemImage: "sparkles",
                    description: Text(AppStrings.sourceDetailEmptyMomentsMessage)
                )
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("source_detail.moments.empty")
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                    ],
                    spacing: 8
                ) {
                    ForEach(moments) { moment in
                        MomentCard(
                            model: moment,
                            layout: .momentGrid,
                            face: faceBinding(for: moment.id),
                            onToggleFavorite: {
                                momentStore.toggleFavorite(id: moment.id)
                            },
                            onOpen: {
                                onOpenMoment(moment.id)
                            }
                        )
                        .accessibilityIdentifier("source_detail.moment.\(moment.id)")
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .accessibilityIdentifier("source_detail.moments")
    }

    private func faceBinding(for momentID: String) -> Binding<MomentFace> {
        Binding(
            get: { facesByMomentID[momentID] ?? .scene },
            set: { facesByMomentID[momentID] = $0 }
        )
    }
}

private struct SourceEpisodeRow: View {
    let episode: EpisodeSummary
    let displayName: String
    let updatedText: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text(displayName)
                            .font(.custom("Geist-Bold", size: 15, relativeTo: .subheadline))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "#C7B7FF"))
                    }

                    HStack(spacing: 6) {
                        MomentCountPill(count: episode.momentCount)
                        Text(AppStrings.sourceDetailViewedCount(episode.viewedCount))
                        Text("·")
                        Text(updatedText)

                        Spacer()
                    }
                    .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color(hex: "#8888AA"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("source_detail.episode.\(episode.id)")
            .accessibilityHint(AppStrings.sourceDetailOpenEpisodeHint)

            if let url = episode.relatedURL {
                Divider()
                    .overlay(Color.white.opacity(0.45))

                Link(destination: url) {
                    HStack(spacing: 7) {
                        Image(systemName: "link")
                        Text(AppStrings.sourceDetailRelatedURL)
                        Spacer()
                        Text(url.host ?? url.absoluteString)
                            .lineLimit(1)
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.custom("Geist-Medium", size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 12)
                    .background(
                        Color.appPrimary.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.appPrimary.opacity(0.09), lineWidth: 0.5)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("source_detail.episode_url.\(episode.id)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 16, fillOpacity: 0.40)
        .accessibilityElement(children: .contain)
    }
}

private struct SourceDetailFailureView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(AppStrings.sourceDetailLoadErrorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(AppStrings.sourceDetailLoadErrorMessage)
        } actions: {
            Button(AppStrings.sourcesRetry, action: retry)
                .buttonStyle(.borderedProminent)
                .tint(Color.appPrimary)
        }
        .accessibilityIdentifier("source_detail.load_error")
    }
}

#Preview {
    NavigationStack {
        SourceDetailView(
            sourceID: "solo-leveling",
            repository: InMemorySourceRepository(),
            momentStore: MomentStore()
        )
    }
}
