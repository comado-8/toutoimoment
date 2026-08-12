import SwiftUI

struct WatchHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WatchHistoryDetailViewModel
    @State private var liveLogExportDocument: WatchHistoryLiveLogExportDocument?
    @State private var showsSavedToast: Bool
    @ObservedObject private var momentStore: MomentStore
    @State private var isDeleteConfirmationPresented = false

    private let historyFormatter = EpisodeWatchHistoryFormatter()
    private let eventFormatter = WatchingSessionEventFormatter()
    private let pairRepository: any PairRepository

    init(
        sourceID: String,
        episodeID: String,
        sessionID: String,
        showsSavedConfirmation: Bool = false,
        repository: any SourceRepository,
        pairRepository: any PairRepository,
        momentStore: MomentStore
    ) {
        _viewModel = StateObject(
            wrappedValue: WatchHistoryDetailViewModel(
                sourceID: sourceID,
                episodeID: episodeID,
                sessionID: sessionID,
                repository: repository
            )
        )
        _showsSavedToast = State(initialValue: showsSavedConfirmation)
        _momentStore = ObservedObject(wrappedValue: momentStore)
        self.pairRepository = pairRepository
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home, motionEnabled: false)
                .ignoresSafeArea()
                .opacity(0.68)

            content

            if showsSavedToast {
                savedToast
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .navigationTitle(AppStrings.watchHistoryDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            if viewModel.loadState == .loaded {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(
                            AppStrings.watchHistoryDetailSaveLiveLog,
                            systemImage: "square.and.arrow.down",
                            action: presentLiveLogExport
                        )
                        .tint(Color.appPrimary)
                        .disabled(viewModel.content?.session.events.isEmpty != false)
                        .accessibilityIdentifier("watch_history_detail.save_live_log")

                        Divider()

                        Button(role: .destructive) {
                            isDeleteConfirmationPresented = true
                        } label: {
                            DestructiveMenuLabel(
                                title: AppStrings.watchHistoryDetailDelete
                            )
                        }
                        .accessibilityIdentifier("watch_history_detail.delete")
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(Color.white.opacity(0.72))
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityLabel(AppStrings.watchHistoryDetailMore)
                    .accessibilityIdentifier("watch_history_detail.more")
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
            guard showsSavedToast else { return }
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeOut(duration: 0.2)) {
                showsSavedToast = false
            }
        }
        .sheet(item: $liveLogExportDocument) { document in
            WatchHistoryLiveLogExportView(document: document)
        }
        .alert(
            AppStrings.watchHistoryDetailSaveMomentError,
            isPresented: Binding(
                get: { viewModel.saveMomentErrorMessage != nil },
                set: { if !$0 { viewModel.clearSaveMomentError() } }
            )
        ) {
            Button(AppStrings.commonOK, role: .cancel) {
                viewModel.clearSaveMomentError()
            }
        }
        .confirmationDialog(
            AppStrings.watchHistoryDeleteConfirmationTitle,
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.watchHistoryDetailDelete, role: .destructive) {
                Task {
                    guard await viewModel.deleteSession() else { return }
                    dismiss()
                }
            }
            Button(AppStrings.watchingCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.watchHistoryDeleteConfirmationMessage)
        }
        .alert(
            AppStrings.watchHistoryDeleteErrorTitle,
            isPresented: Binding(
                get: { viewModel.deleteErrorMessage != nil },
                set: { if !$0 { viewModel.clearDeleteError() } }
            )
        ) {
            Button(AppStrings.sourcesRetry) {
                Task {
                    guard await viewModel.deleteSession() else { return }
                    dismiss()
                }
            }
            Button(AppStrings.watchingCancel, role: .cancel) {
                viewModel.clearDeleteError()
            }
        } message: {
            Text(viewModel.deleteErrorMessage ?? "")
        }
        .accessibilityIdentifier("watch_history_detail.view")
    }

    private var savedToast: some View {
        Label(AppStrings.watchHistorySaved, systemImage: "checkmark.circle.fill")
            .font(.custom("Geist-SemiBold", size: 13, relativeTo: .footnote))
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 14)
            .frame(minHeight: 40)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1))
            .shadow(color: Color.appPrimary.opacity(0.12), radius: 12, y: 5)
            .accessibilityIdentifier("watch_history_detail.saved")
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("watch_history_detail.loading")
        case .failed:
            ContentUnavailableView {
                Label(
                    AppStrings.watchHistoryDetailLoadErrorTitle,
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(AppStrings.watchHistoryDetailLoadErrorMessage)
            } actions: {
                Button(AppStrings.sourcesRetry) {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
            .accessibilityIdentifier("watch_history_detail.failed")
        case .missing:
            ContentUnavailableView(
                AppStrings.watchHistoryDetailMissingTitle,
                systemImage: "clock.badge.questionmark",
                description: Text(AppStrings.watchHistoryDetailMissingMessage)
            )
            .accessibilityIdentifier("watch_history_detail.missing")
        case .loaded:
            if let content = viewModel.content {
                loadedContent(content)
            }
        }
    }

    private func loadedContent(_ content: WatchHistoryDetailContent) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 24) {
                WatchHistorySessionSummaryCard(
                    session: content.session,
                    dateTimeText: historyFormatter.dateTimeText(
                        for: content.session.startedAt
                    )
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.watchHistoryDetailLiveLog)
                        .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
                        .foregroundStyle(Color.textPrimary)

                    Text(AppStrings.watchHistoryDetailLiveLogSubtitle)
                        .font(.custom("Geist-Medium", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.textSecondary)
                }

                if content.session.events.isEmpty {
                    ContentUnavailableView(
                        AppStrings.watchHistoryDetailEmptyLogTitle,
                        systemImage: "clock.arrow.circlepath"
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(content.session.events.enumerated()), id: \.element.id) {
                            index,
                            event in
                            WatchingSessionEventRow(
                                event: event,
                                timeText: eventFormatter.elapsedTimeText(
                                    seconds: event.elapsedSeconds
                                ),
                                showsLine: index < content.session.events.count - 1,
                                isSavingMoment: viewModel.savingEventID == event.id,
                                onSaveAsMoment: {
                                    Task {
                                        await viewModel.saveLiveHeartScreamAsMoment(
                                            eventID: event.id,
                                            pairRepository: pairRepository,
                                            momentStore: momentStore
                                        )
                                    }
                                }
                            )
                        }
                    }
                    .accessibilityIdentifier("watch_history_detail.live_log")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, AppTheme.Layout.bottomTabBarReservedHeight)
        }
    }

    @MainActor
    private func presentLiveLogExport() {
        guard let content = viewModel.content, !content.session.events.isEmpty else {
            return
        }
        liveLogExportDocument = WatchHistoryLiveLogExportDocument(content: content)
    }
}

struct WatchHistorySessionSummaryCard: View {
    let session: WatchingSessionSummary
    let dateTimeText: String

    private let historyFormatter = EpisodeWatchHistoryFormatter()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateTimeText)
                .font(.custom("Geist-Medium", size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 6) {
                WatchHistoryStatChip(
                    text: historyFormatter.durationText(seconds: session.durationSeconds),
                    icon: .system("clock.fill")
                )
                WatchHistoryStatChip(
                    text: AppStrings.sourcesMomentCount(session.momentCount),
                    icon: .moment
                )
                WatchHistoryStatChip(
                    text: AppStrings.episodeDetailReactionCount(session.reactionCount),
                    icon: .system("heart.fill")
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.60))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(EpisodeDetailPalette.historyCardGradient)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.appPrimary, lineWidth: 1)
        }
        .shadow(color: Color(hex: "#7C6FCD").opacity(0.08), radius: 10, y: 4)
        .accessibilityIdentifier("watch_history_detail.summary")
    }
}

struct WatchHistoryStatChip: View {
    enum Icon {
        case system(String)
        case moment
    }

    let text: String
    let icon: Icon

    var body: some View {
        HStack(spacing: 4) {
            switch icon {
            case let .system(systemImage):
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            case .moment:
                MomentSparkleIcon(color: .appPrimary, width: 8, height: 12)
            }

            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
            .font(.custom("Geist-SemiBold", size: 10.5, relativeTo: .caption2))
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color(hex: "#F0EFFF"), in: Capsule())
            .frame(maxWidth: .infinity)
    }
}

struct WatchingSessionEventRow: View {
    let event: WatchingSessionEvent
    let timeText: String
    let showsLine: Bool
    var isSavingMoment = false
    var onSaveAsMoment: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.white)
                    .overlay {
                        Circle()
                            .stroke(Color.appPrimary, lineWidth: 2)
                    }
                    .frame(width: 8, height: 8)

                if showsLine {
                    Rectangle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 16)

            HStack(alignment: .top, spacing: 12) {
                Text(timeText)
                    .font(.custom("Geist-Bold", size: 10, relativeTo: .caption2))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#F0EFFF"), in: RoundedRectangle(
                        cornerRadius: 4,
                        style: .continuous
                    ))

                eventContent
            }
            .padding(.top, -4)
            .padding(.bottom, showsLine ? 16 : 0)
            .frame(maxWidth: .infinity, minHeight: showsLine ? 80 : 28, alignment: .topLeading)
        }
        .accessibilityIdentifier("watch_history_detail.event.\(event.id)")
    }

    @ViewBuilder
    private var eventContent: some View {
        switch event.kind {
        case let .reaction(reaction):
            Text(reaction.count > 1
                ? "\(reaction.displayText) ×\(reaction.count)"
                : reaction.displayText)
                .font(.custom("Geist-Medium", size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        case let .voiceNote(text):
            Label {
                Text("“\(text)”")
                    .italic()
            } icon: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.textSecondary)
            }
            .font(.custom("Geist-Medium", size: 14, relativeTo: .subheadline))
            .foregroundStyle(Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
        case let .liveHeartScream(momentID, comment, _):
            VStack(alignment: .leading, spacing: 8) {
                if momentID != nil {
                    MomentSparkleIcon(color: .white, width: 9, height: 13)
                        .frame(width: 30, height: 24)
                        .background(Color.appPrimary, in: Capsule())
                        .accessibilityLabel(AppStrings.watchHistoryDetailMomentSaved)
                } else {
                    Button {
                        onSaveAsMoment?()
                    } label: {
                        HStack(spacing: 6) {
                            if isSavingMoment {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color.appPrimary)
                            } else {
                                MomentSparkleIcon(color: .appPrimary, width: 9, height: 13)
                            }
                            Text(AppStrings.watchHistoryDetailSaveAsMoment)
                        }
                        .font(.custom("Geist-Bold", size: 11, relativeTo: .caption2))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.72), in: Capsule())
                        .overlay(Capsule().stroke(Color.appPrimary, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingMoment || onSaveAsMoment == nil)
                    .accessibilityIdentifier("watch_history_detail.save_moment.\(event.id)")
                }

                Text(comment)
                    .font(.custom(
                        "ZenKakuGothicNew-Medium",
                        size: 13,
                        relativeTo: .subheadline
                    ))
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
