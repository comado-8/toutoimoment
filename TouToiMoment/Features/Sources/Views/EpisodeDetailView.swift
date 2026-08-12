import SwiftUI

struct EpisodeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EpisodeDetailViewModel
    @ObservedObject private var momentStore: MomentStore
    @State private var selectedTab: EpisodeDetailTab = .moments
    @State private var timelineExportDocument: EpisodeTimelineExportDocument?
    @State private var isEditPresented = false
    @State private var isDeleteConfirmationPresented = false

    private let onCreateMoment: () -> Void
    private let onStartWatching: () -> Void
    private let onOpenMoment: (String) -> Void
    private let onOpenWatchHistory: (String) -> Void
    private let historyFormatter = EpisodeWatchHistoryFormatter()

    init(
        sourceID: String,
        episodeID: String,
        initialSection: EpisodeDetailSection = .moments,
        repository: any SourceRepository,
        momentStore: MomentStore,
        onCreateMoment: @escaping () -> Void = {},
        onStartWatching: @escaping () -> Void = {},
        onOpenMoment: @escaping (String) -> Void = { _ in },
        onOpenWatchHistory: @escaping (String) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: EpisodeDetailViewModel(
                sourceID: sourceID,
                episodeID: episodeID,
                repository: repository
            )
        )
        _selectedTab = State(
            initialValue: initialSection == .watchHistory ? .watchHistory : .moments
        )
        _momentStore = ObservedObject(wrappedValue: momentStore)
        self.onCreateMoment = onCreateMoment
        self.onStartWatching = onStartWatching
        self.onOpenMoment = onOpenMoment
        self.onOpenWatchHistory = onOpenWatchHistory
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home, motionEnabled: false)
                .ignoresSafeArea()
                .opacity(0.68)

            content

            if selectedTab == .moments, viewModel.loadState == .loaded {
                addMomentButton
            }
        }
        .navigationTitle(AppStrings.episodeDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if viewModel.loadState == .loaded {
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
                    .accessibilityLabel(AppStrings.episodeDetailEdit)
                    .accessibilityIdentifier("episode_detail.edit")

                    Menu {
                        if selectedTab == .moments {
                            Button(action: presentTimelineExport) {
                                Label(
                                    AppStrings.episodeDetailSaveTimeline,
                                    systemImage: "square.and.arrow.down"
                                )
                            }
                            .tint(Color.appPrimary)
                            .disabled(episodeMoments.isEmpty)
                            .accessibilityIdentifier("episode_detail.save_timeline")

                            Divider()
                        }

                        Button(role: .destructive) {
                            isDeleteConfirmationPresented = true
                        } label: {
                            DestructiveMenuLabel(title: AppStrings.episodeDetailDelete)
                        }
                        .tint(Color.red)
                        .accessibilityIdentifier("episode_detail.delete")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(Color.white.opacity(0.72))
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityLabel(AppStrings.episodeDetailMore)
                    .accessibilityIdentifier("episode_detail.more")
                }
            }
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
        .alert(
            AppStrings.episodeDetailRefreshErrorTitle,
            isPresented: Binding(
                get: { viewModel.refreshErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearRefreshError()
                    }
                }
            )
        ) {
            Button(AppStrings.sourcesRetry) {
                Task { await viewModel.retryRefresh() }
            }
            Button(AppStrings.watchingCancel, role: .cancel) {
                viewModel.clearRefreshError()
            }
        } message: {
            if let message = viewModel.refreshErrorMessage {
                Text(message)
            }
        }
        .sheet(item: $timelineExportDocument) { document in
            EpisodeTimelineExportView(document: document)
        }
        .sheet(isPresented: $isEditPresented) {
            if let content = viewModel.content {
                let schema = SourceLocatorSchema.schema(for: content.source.mediaType)
                    ?? SourceLocatorSchema.fallback
                NewEpisodeSheet(
                    schema: schema,
                    episode: content.episode,
                    saveAction: { request in
                        try await viewModel.updateEpisode(request)
                    }
                )
            }
        }
        .confirmationDialog(
            AppStrings.episodeDeleteConfirmationTitle,
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.episodeDetailDelete, role: .destructive) {
                Task {
                    guard await viewModel.deleteEpisode() else { return }
                    momentStore.detachEpisodeReferences(
                        sourceID: viewModel.sourceID,
                        episodeID: viewModel.episodeID
                    )
                    dismiss()
                }
            }
            Button(AppStrings.watchingCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.episodeDeleteConfirmationMessage)
        }
        .alert(
            AppStrings.episodeDeleteErrorTitle,
            isPresented: Binding(
                get: { viewModel.deleteErrorMessage != nil },
                set: { if !$0 { viewModel.clearDeleteError() } }
            )
        ) {
            Button(AppStrings.sourcesRetry) {
                Task {
                    guard await viewModel.deleteEpisode() else { return }
                    momentStore.detachEpisodeReferences(
                        sourceID: viewModel.sourceID,
                        episodeID: viewModel.episodeID
                    )
                    dismiss()
                }
            }
            Button(AppStrings.watchingCancel, role: .cancel) {
                viewModel.clearDeleteError()
            }
        } message: {
            Text(viewModel.deleteErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("episode_detail.loading")
        case .failed:
            ContentUnavailableView {
                Label(
                    AppStrings.episodeDetailLoadErrorTitle,
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(AppStrings.episodeDetailLoadErrorMessage)
            } actions: {
                Button(AppStrings.sourcesRetry) {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
            .accessibilityIdentifier("episode_detail.failed")
        case .missing:
            ContentUnavailableView(
                AppStrings.episodeDetailMissingTitle,
                systemImage: "rectangle.stack.badge.questionmark",
                description: Text(AppStrings.episodeDetailMissingMessage)
            )
            .accessibilityIdentifier("episode_detail.missing")
        case .loaded:
            if let content = viewModel.content {
                loadedContent(content)
            }
        }
    }

    private func loadedContent(_ content: EpisodeDetailContent) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 20) {
                EpisodeDetailHeroCard(
                    content: content,
                    onStartWatching: onStartWatching
                )

                EpisodeDetailTabSwitcher(selection: $selectedTab)

                switch selectedTab {
                case .moments:
                    momentsContent(episodeMoments)
                case .watchHistory:
                    watchHistoryContent(content.episode.watchingSessions)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, AppTheme.Layout.bottomTabBarReservedHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func momentsContent(_ moments: [MomentCardModel]) -> some View {
        if moments.isEmpty {
            ContentUnavailableView(
                AppStrings.episodeDetailEmptyMomentsTitle,
                systemImage: "sparkles",
                description: Text(AppStrings.episodeDetailEmptyMomentsMessage)
            )
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("episode_detail.moments.empty")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppStrings.episodeDetailTimeline)
                    .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityIdentifier("episode_detail.timeline.title")

                LazyVStack(spacing: 0) {
                    ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                        EpisodeMomentTimelineRow(
                            moment: moment,
                            showsLine: index < moments.count - 1,
                            onOpen: { onOpenMoment(moment.id) }
                        )
                    }
                }
                .accessibilityIdentifier("episode_detail.moments")
            }
        }
    }

    @ViewBuilder
    private func watchHistoryContent(_ sessions: [WatchingSessionSummary]) -> some View {
        if sessions.isEmpty {
            ContentUnavailableView(
                AppStrings.episodeDetailEmptyHistoryTitle,
                systemImage: "clock.arrow.circlepath",
                description: Text(AppStrings.episodeDetailEmptyHistoryMessage)
            )
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("episode_detail.history.empty")
        } else {
            LazyVStack(spacing: 12) {
                ForEach(sessions) { session in
                    EpisodeWatchHistoryCard(
                        session: session,
                        dateTimeText: historyFormatter.dateTimeText(for: session.startedAt),
                        durationText: historyFormatter.durationText(
                            seconds: session.durationSeconds
                        ),
                        onOpen: { onOpenWatchHistory(session.id) }
                    )
                }
            }
            .accessibilityIdentifier("episode_detail.history")
        }
    }

    private var addMomentButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: onCreateMoment) {
                    MomentSparkleIcon(color: .white, width: 18, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.extraLarge)
                .tint(Color.appPrimary)
                .accessibilityLabel(AppStrings.episodeDetailAddMoment)
                .accessibilityIdentifier("episode_detail.add_moment")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 96)
        }
    }

    private var episodeMoments: [MomentCardModel] {
        guard let content = viewModel.content else { return [] }
        return SourceMomentProjection.episodeMoments(
            sourceID: content.source.id,
            episodeID: content.episode.id,
            moments: momentStore.moments
        )
    }

    @MainActor
    private func presentTimelineExport() {
        guard let content = viewModel.content, !episodeMoments.isEmpty else { return }
        timelineExportDocument = EpisodeTimelineExportDocument(
            content: content,
            moments: episodeMoments
        )
    }
}

private enum EpisodeDetailTab: String, CaseIterable, Identifiable {
    case moments
    case watchHistory

    var id: Self { self }

    var title: String {
        switch self {
        case .moments: AppStrings.episodeDetailMomentsTab
        case .watchHistory: AppStrings.episodeDetailWatchHistoryTab
        }
    }
}

enum EpisodeDetailPalette {
    static let actionGradient = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: Color.appPrimary, location: 0),
            .init(
                color: Color(red: 0.55, green: 0.44, blue: 0.94),
                location: 0.50
            ),
            .init(color: Color.appAccent, location: 1),
        ]),
        startPoint: UnitPoint(x: 0.53, y: -0.98),
        endPoint: UnitPoint(x: 0.58, y: 1.78)
    )

    static let historyCardGradient = LinearGradient(
        colors: [
            Color(hex: "#C4B5F0").opacity(0.19),
            Color.white.opacity(0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

private struct EpisodeDetailTabSwitcher: View {
    @Binding var selection: EpisodeDetailTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EpisodeDetailTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(4)
        .frame(height: 48)
        .background(Color.white, in: Capsule())
        .shadow(color: Color(hex: "#7C6FCD").opacity(0.08), radius: 5, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppStrings.episodeDetailTabPickerLabel)
        .accessibilityIdentifier("episode_detail.tabs")
        .animation(.easeInOut(duration: 0.18), value: selection)
    }

    private func tabButton(_ tab: EpisodeDetailTab) -> some View {
        let isSelected = selection == tab

        return Button {
            selection = tab
        } label: {
            Text(tab.title)
                .font(.custom("Geist-Medium", size: 14, relativeTo: .subheadline))
                .foregroundStyle(isSelected ? Color.white : Color.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Capsule())
                .background {
                    if isSelected {
                        switch tab {
                        case .moments:
                            Capsule().fill(Color.appPrimary)
                        case .watchHistory:
                            Capsule().fill(EpisodeDetailPalette.actionGradient)
                        }
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("episode_detail.tab.\(tab.rawValue)")
    }
}

private struct EpisodeDetailHeroCard: View {
    let content: EpisodeDetailContent
    let onStartWatching: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.locatorDisplayName.uppercased())
                    .font(.custom("Geist-Bold", size: 14, relativeTo: .caption))
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityIdentifier("episode_detail.locator")

                if let displayTitle = content.episode.displayTitle?.trimmedOrNil {
                    Text(displayTitle)
                        .font(.custom("Geist-Bold", size: 22, relativeTo: .title2))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("episode_detail.display_title")
                }

                Text(content.source.displayName)
                    .font(.custom("Geist-Medium", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("episode_detail.source")
            }

            HStack(spacing: 12) {
                Label {
                    Text(AppStrings.episodeDetailViewedCount(content.episode.viewedCount))
                } icon: {
                    Image(systemName: "eye")
                }
                .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.textSecondary)

                Spacer(minLength: 4)

                Button(action: onStartWatching) {
                    Label(AppStrings.episodeDetailStartWatching, systemImage: "play.fill")
                        .font(.custom("Geist-SemiBold", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 32)
                        .background(
                            EpisodeDetailPalette.actionGradient,
                            in: Capsule()
                        )
                        .shadow(color: Color.appPrimary.opacity(0.25), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("episode_detail.start_watching")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 24, fillOpacity: 0.60)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("episode_detail.hero")
    }
}

private struct EpisodeWatchHistoryCard: View {
    let session: WatchingSessionSummary
    let dateTimeText: String
    let durationText: String
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateTimeText)
                        .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
                        .foregroundStyle(Color.textPrimary)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            statChips
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            statChips
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.40))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(EpisodeDetailPalette.historyCardGradient)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appPrimary, lineWidth: 1)
            }
            .shadow(color: Color(hex: "#7C6FCD").opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("episode_detail.history.\(session.id)")
    }

    @ViewBuilder
    private var statChips: some View {
        EpisodeMetadataChip(
            text: durationText,
            foregroundColor: Color.appPrimarySoft
        )
        EpisodeMetadataChip(
            text: AppStrings.sourcesMomentCount(session.momentCount),
            foregroundColor: Color.appPrimarySoft
        )
        EpisodeMetadataChip(
            text: AppStrings.episodeDetailReactionCount(session.reactionCount),
            foregroundColor: Color.appPrimarySoft
        )
    }
}
