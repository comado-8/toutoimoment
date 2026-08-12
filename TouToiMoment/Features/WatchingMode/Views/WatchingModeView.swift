import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WatchingModeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: WatchingModeViewModel
    @ObservedObject private var momentStore: MomentStore
    @ObservedObject private var settingsStore: SettingsStore
    @State private var pairs: [PairSummary] = []
    @State private var isMomentSheetPresented = false
    @State private var isMomentReviewPresented = false
    @State private var selectedMomentCandidateIDs: Set<String> = []
    @State private var momentTimestamp = 0
    @State private var isFinishConfirmationPresented = false
    @State private var isExitConfirmationPresented = false
    @State private var isSettingsPresented = false
    @State private var showsMomentToast = false
    @State private var reactionFlightQueue = ReactionFlightQueue()
    @State private var xShareDraft: XShareDraft?
    @State private var isXLengthAlertPresented = false

    private let sourceRepository: any SourceRepository
    private let pairRepository: any PairRepository
    private let onFinished: (String, String, String) -> Void
    private let onDiscard: () -> Void

    init(
        selection: WatchingModeSelection,
        repository: any SourceRepository,
        pairRepository: any PairRepository,
        momentStore: MomentStore,
        settingsStore: SettingsStore,
        onFinished: @escaping (String, String, String) -> Void,
        onDiscard: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: WatchingModeViewModel(
                selection: selection,
                repository: repository
            )
        )
        _momentStore = ObservedObject(wrappedValue: momentStore)
        _settingsStore = ObservedObject(wrappedValue: settingsStore)
        self.sourceRepository = repository
        self.pairRepository = pairRepository
        self.onFinished = onFinished
        self.onDiscard = onDiscard
    }

    var body: some View {
        ZStack {
            if isSettingsPresented {
                sessionSettingsScreen
            } else {
                AppBackgroundView(theme: .home)
                    .ignoresSafeArea()
                    .opacity(0.72)

                ReactionFlightOverlay(events: reactionFlightQueue.events)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 0) {
                    header
                    sessionContent
                }
                .allowsHitTesting(!isConfirmationPresented)

                WatchingReactionDock(
                    isEnabled: viewModel.allowsLogging,
                    hapticFeedbackEnabled: settingsStore.settings.hapticFeedbackEnabled,
                    onReaction: recordReaction
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(!isConfirmationPresented)
                .zIndex(2)

                if showsMomentToast {
                    momentSavedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(3)
                }

                if isConfirmationPresented {
                    finishConfirmationOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .zIndex(4)
                }
            }
        }
        .coordinateSpace(name: WatchingMotionCoordinateSpace.name)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            pairs = (try? await pairRepository.fetchPairs()) ?? []
        }
        .onAppear(perform: updateIdleTimer)
        .onChange(of: settingsStore.settings.keepScreenAwake) { _, _ in
            updateIdleTimer()
        }
        .onDisappear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .sheet(isPresented: $isMomentSheetPresented) {
            WatchingMomentSheet(
                timestampSeconds: momentTimestamp,
                pairs: pairs,
                selectedPairID: viewModel.selection.pair?.id,
                onSave: saveMoment
            )
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isMomentReviewPresented) {
            WatchingMomentReviewView(
                candidates: viewModel.momentCandidates,
                selectedIDs: $selectedMomentCandidateIDs,
                onCancel: cancelMomentReview,
                onFinish: finishFromMomentReview
            )
            .interactiveDismissDisabled()
        }
        .sheet(item: $xShareDraft) { draft in
            SystemActivityView(activityItems: draft.activityItems)
        }
        .alert(
            AppStrings.watchingSaveFailed,
            isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearSaveError()
                    }
                }
            )
        ) {
            Button(AppStrings.sourcesRetry) {
                Task { await finishAndSave() }
            }
            Button(AppStrings.watchingKeepWatching, role: .cancel) {
                viewModel.clearSaveError()
            }
        }
        .alert(
            AppStrings.xShareTooLongTitle,
            isPresented: $isXLengthAlertPresented
        ) {
            Button(AppStrings.commonOK, role: .cancel) {}
        } message: {
            Text(AppStrings.xShareTooLongMessage)
        }
        .accessibilityIdentifier("watching_mode.view")
    }

    private var isConfirmationPresented: Bool {
        isFinishConfirmationPresented || isExitConfirmationPresented
    }

    private var header: some View {
        HStack {
            Button {
                if viewModel.hasStarted {
                    requestFinish(fromExit: true)
                } else {
                    onDiscard()
                }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(Color.white.opacity(0.72))
            .foregroundStyle(Color.appPrimary)
            .disabled(viewModel.phase == .saving)
            .accessibilityIdentifier("watching_mode.close")

            Spacer()

            Button {
                if viewModel.phase == .running {
                    viewModel.pause()
                }
                isSettingsPresented = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(Color.white.opacity(0.72))
            .foregroundStyle(Color.appPrimary)
            .disabled(viewModel.phase == .saving)
            .accessibilityLabel(AppStrings.watchingSettings)
            .accessibilityIdentifier("watching_mode.settings")
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var sessionContent: some View {
        GeometryReader { proxy in
            let usesCompactSpacing = proxy.size.height < 700

            VStack(spacing: usesCompactSpacing ? 28 : 56) {
                VStack(spacing: 8) {
                    Text(viewModel.selection.source.displayName)
                        .font(.custom("ZenKakuGothicNew-Regular", size: 14, relativeTo: .subheadline))
                    Text(viewModel.selection.episodeDisplayName)
                        .font(episodeTitleFont)
                        .fontWeight(usesJapaneseEpisodeFont ? .light : .regular)
                        .foregroundStyle(episodeTitleColor)
                    Capsule()
                        .fill(Color.appPrimary.opacity(0.2))
                        .frame(width: 184, height: 2)
                }
                .foregroundStyle(Color.appPrimary)
                .padding(.top, 16)

                elapsedTimeView

                HStack(spacing: 26) {
                    playbackButton(
                        assetName: viewModel.phase == .idle ? "WatchingStart" : "WatchingFinish",
                        title: viewModel.phase == .idle
                            ? AppStrings.watchingStart
                            : AppStrings.watchingFinish,
                        identifier: "watching_mode.primary"
                    ) {
                        if viewModel.phase == .idle {
                            viewModel.start()
                        } else {
                            requestFinish(fromExit: false)
                        }
                    }

                    playbackButton(
                        assetName: viewModel.phase == .paused ? "WatchingStart" : "WatchingPause",
                        title: viewModel.phase == .paused
                            ? AppStrings.watchingResume
                            : AppStrings.watchingPause,
                        identifier: "watching_mode.pause_resume",
                        isEnabled: viewModel.phase == .running || viewModel.phase == .paused,
                        isEmphasized: viewModel.phase == .paused
                    ) {
                        if viewModel.phase == .running {
                            viewModel.pause()
                        } else if viewModel.phase == .paused {
                            viewModel.resume()
                        }
                    }
                }

                PlaybackMotionBar(
                    phase: viewModel.phase,
                    elapsedTime: viewModel.elapsedTimeInterval
                )

                Button {
                    momentTimestamp = viewModel.elapsedSeconds()
                    isMomentSheetPresented = true
                } label: {
                    VStack(spacing: 8) {
                        LiveHeartScreamButtonIcon()
                            .frame(width: 92, height: 92)

                        Text(AppStrings.watchingNewMoment)
                            .font(.custom("Geist-Medium", size: 11, relativeTo: .caption))
                    }
                    .foregroundStyle(Color.appPrimarySoft)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.allowsLogging)
                .opacity(viewModel.allowsLogging ? 1 : 0.42)
                .accessibilityIdentifier("watching_mode.new_moment")
            }
            .padding(.top, usesCompactSpacing ? 12 : 24)
            .padding(.bottom, usesCompactSpacing ? 64 : 85)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func playbackButton(
        assetName: String,
        title: String,
        identifier: String,
        isEnabled: Bool = true,
        isEmphasized: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isEmphasized
                                ? AnyShapeStyle(EpisodeDetailPalette.actionGradient)
                                : AnyShapeStyle(Color.white.opacity(0.44))
                        )
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                        .shadow(color: Color.appPrimary.opacity(0.1), radius: 10, y: 4)
                    Image(assetName)
                        .renderingMode(isEmphasized ? .template : .original)
                        .resizable()
                        .foregroundStyle(isEmphasized ? Color.white : Color.primary)
                        .frame(
                            width: playbackIconSize(
                                assetName: assetName,
                                isEmphasized: isEmphasized
                            ),
                            height: playbackIconSize(
                                assetName: assetName,
                                isEmphasized: isEmphasized
                            )
                        )
                }
                .frame(width: 64, height: 64)

                Text(title)
                    .font(.custom("Geist-Medium", size: 10, relativeTo: .caption2))
                    .frame(width: 96)
            }
            .foregroundStyle(Color.appPrimarySoft)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || viewModel.phase == .saving)
        .opacity(isEnabled ? 1 : 0.35)
        .accessibilityIdentifier(identifier)
    }

    private func recordReaction(
        _ reaction: NewMomentDraft.SelectedReaction,
        from origin: CGPoint
    ) {
        viewModel.recordReaction(reaction)
        let event = reactionFlightQueue.enqueue(
            emoji: reaction.emoji,
            origin: origin,
            reducesMotion: reduceMotion
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(event.duration + 0.08))
            reactionFlightQueue.remove(id: event.id)
        }
    }

    private func playbackIconSize(
        assetName: String,
        isEmphasized: Bool
    ) -> CGFloat {
        if isEmphasized {
            // The white template reads heavier than the original gradient SVG.
            return 36
        }
        return assetName == "WatchingStart" ? 40 : 47
    }

    private var episodeTitleFont: Font {
        usesJapaneseEpisodeFont
            ? .custom("ZenAntique-Regular", size: 30, relativeTo: .largeTitle)
            : .custom("InstrumentSerif-Regular", size: 32, relativeTo: .largeTitle)
    }

    private var usesJapaneseEpisodeFont: Bool {
        MomentShareEpisodeTypography.usesJapaneseFont(
            for: viewModel.selection.episodeDisplayName
        )
    }

    private var episodeTitleColor: Color {
        usesJapaneseEpisodeFont ? Color.appPrimary.opacity(0.84) : Color.appPrimary
    }

    @ViewBuilder
    private var elapsedTimeView: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(WatchingModeViewModel.timestampText(
                viewModel.elapsedSeconds(at: context.date)
            ))
            .font(.custom("EBGaramond-Regular", size: 60, relativeTo: .largeTitle))
            .monospacedDigit()
            .foregroundStyle(Color.appPrimary)
            .contentTransition(.numericText())
            .accessibilityIdentifier("watching_mode.timer")
        }
    }

    private func updateIdleTimer() {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = settingsStore.settings.keepScreenAwake
        #endif
    }

    private var sessionSettingsScreen: some View {
        WatchingModeSetupView(
            sourceID: viewModel.selection.source.id,
            episodeID: viewModel.selection.episode.id,
            pairID: viewModel.selection.pair?.id,
            autoHashtags: viewModel.selection.autoHashtags,
            locksSourceAndEpisode: viewModel.hasStarted,
            sourceRepository: sourceRepository,
            pairRepository: pairRepository,
            onReady: { selection in
                if viewModel.hasStarted {
                    viewModel.selection.pair = selection.pair
                    viewModel.selection.autoHashtags = selection.autoHashtags
                } else {
                    viewModel.selection = selection
                }
                isSettingsPresented = false
            },
            onClose: {
                isSettingsPresented = false
            }
        )
    }

    private var finishConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: cancelConfirmation)

            VStack(alignment: .leading, spacing: 18) {
                Text(AppStrings.watchingFinishConfirmationTitle)
                    .font(.custom("Geist-SemiBold", size: 20, relativeTo: .title3))
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !viewModel.shouldSaveHistory {
                    Text(AppStrings.watchingHistoryNotSaved)
                        .font(.custom("Geist-Regular", size: 14, relativeTo: .body))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    isFinishConfirmationPresented = false
                    isExitConfirmationPresented = false
                    if viewModel.shouldSaveHistory {
                        if viewModel.momentCandidates.isEmpty {
                            Task { await finishAndSave() }
                        } else {
                            presentMomentReview()
                        }
                    } else {
                        onDiscard()
                    }
                } label: {
                    Text(
                        viewModel.shouldSaveHistory
                            ? AppStrings.watchingFinishAndSave
                            : AppStrings.watchingFinishWithoutSaving
                    )
                        .font(.custom("Geist-SemiBold", size: 16, relativeTo: .headline))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.appPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("watching_mode.finish_confirm")

                if isExitConfirmationPresented, viewModel.shouldSaveHistory {
                    Button(AppStrings.watchingDiscardSession) {
                        isExitConfirmationPresented = false
                        onDiscard()
                    }
                    .font(.custom("Geist-Medium", size: 15, relativeTo: .body))
                    .foregroundStyle(Color.red)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("watching_mode.discard")
                }

                Button(AppStrings.watchingCancel, action: cancelConfirmation)
                    .font(.custom("Geist-Medium", size: 15, relativeTo: .body))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("watching_mode.finish_cancel")
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.95), lineWidth: 1)
            )
            .shadow(color: Color.appPrimary.opacity(0.16), radius: 24, y: 10)
            .padding(.horizontal, 28)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .accessibilityIdentifier("watching_mode.finish_dialog")
        }
    }

    private func cancelConfirmation() {
        isFinishConfirmationPresented = false
        isExitConfirmationPresented = false
        viewModel.cancelFinish()
    }

    private var momentSavedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.appPrimary, in: Circle())
            Text(AppStrings.watchingMomentAddedToLiveLog)
                .font(.custom("Geist-Medium", size: 13, relativeTo: .footnote))
            Divider().frame(height: 22)
            Button(AppStrings.watchingShareOnX, action: shareLatestLiveHeartScream)
                .font(.custom("Geist-SemiBold", size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.appPrimary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1))
        .padding(.top, 58)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func shareLatestLiveHeartScream() {
        guard let candidate = viewModel.momentCandidates.last else { return }
        let episode = viewModel.selection.episodeDisplayName
        let source = viewModel.selection.source.displayName
        let draft = XShareDraft(
            body: [candidate.comment, "\(source) · \(episode)"]
                .filter { !$0.isEmpty }
                .joined(separator: "\n"),
            autoHashtags: viewModel.selection.autoHashtags
        )
        guard !draft.exceedsRecommendedLength else {
            isXLengthAlertPresented = true
            return
        }
        xShareDraft = draft
    }

    private func saveMoment(heartScream: String, pair: PairSummary?) {
        let draft = viewModel.makeMomentDraft(
            heartScream: heartScream,
            pair: pair,
            timestampSeconds: momentTimestamp
        )
        viewModel.selection.pair = pair
        viewModel.recordMomentCandidate(
            draft: draft,
            comment: heartScream,
            elapsedSeconds: momentTimestamp
        )
        isMomentSheetPresented = false
        withAnimation(.easeOut(duration: 0.2)) {
            showsMomentToast = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.easeOut(duration: 0.2)) {
                showsMomentToast = false
            }
        }
    }

    private func finishAndSave() async {
        guard viewModel.shouldSaveHistory else {
            onDiscard()
            return
        }
        guard let session = await viewModel.finish() else { return }
        for candidate in viewModel.momentCandidates {
            guard
                let momentID = candidate.savedMomentID,
                momentStore.moment(id: momentID) == nil
            else {
                continue
            }
            momentStore.add(draft: candidate.draft, id: momentID)
        }
        onFinished(
            viewModel.selection.source.id,
            viewModel.selection.episode.id,
            session.id
        )
    }

    private func requestFinish(fromExit: Bool) {
        viewModel.prepareToFinish()
        if !fromExit, !viewModel.momentCandidates.isEmpty {
            presentMomentReview()
        } else if fromExit {
            isExitConfirmationPresented = true
        } else {
            isFinishConfirmationPresented = true
        }
    }

    private func presentMomentReview() {
        selectedMomentCandidateIDs = Set(viewModel.momentCandidates.map(\.id))
        isMomentReviewPresented = true
    }

    private func cancelMomentReview() {
        isMomentReviewPresented = false
        viewModel.cancelFinish()
    }

    private func finishFromMomentReview() {
        viewModel.stageMomentCandidates(selectedIDs: selectedMomentCandidateIDs)
        isMomentReviewPresented = false
        Task { await finishAndSave() }
    }
}

private struct WatchingMomentReviewView: View {
    let candidates: [WatchingMomentCandidate]
    @Binding var selectedIDs: Set<String>
    let onCancel: () -> Void
    let onFinish: () -> Void

    private var allSelected: Bool {
        !candidates.isEmpty && selectedIDs.count == candidates.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(AppStrings.watchingMomentReviewDescription)
                        .font(.custom("Geist-Regular", size: 14, relativeTo: .body))
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(allSelected ? AppStrings.watchingClearAll : AppStrings.watchingSelectAll) {
                        selectedIDs = allSelected ? [] : Set(candidates.map(\.id))
                    }
                    .font(.custom("Geist-SemiBold", size: 14, relativeTo: .body))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
                    .buttonStyle(.plain)

                    LazyVStack(spacing: 12) {
                        ForEach(candidates) { candidate in
                            candidateRow(candidate)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 96)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onFinish) {
                    Text(
                        selectedIDs.isEmpty
                            ? AppStrings.watchingFinishWithoutMoments
                            : AppStrings.watchingSaveSelectedMoments(selectedIDs.count)
                    )
                    .font(.custom("Geist-SemiBold", size: 16, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(EpisodeDetailPalette.actionGradient, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("watching_moment_review.finish")
            }
            .background(AppBackgroundView(theme: .home).opacity(0.55))
            .navigationTitle(AppStrings.watchingMomentReviewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.watchingCancel, action: onCancel)
                }
            }
        }
        .accessibilityIdentifier("watching_moment_review.view")
    }

    private func candidateRow(_ candidate: WatchingMomentCandidate) -> some View {
        let isSelected = selectedIDs.contains(candidate.id)
        return Button {
            if isSelected {
                selectedIDs.remove(candidate.id)
            } else {
                selectedIDs.insert(candidate.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.textSecondary.opacity(0.55))

                VStack(alignment: .leading, spacing: 9) {
                    Text(WatchingModeViewModel.timestampText(candidate.elapsedSeconds))
                        .font(.custom("Geist-SemiBold", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.appPrimary)
                    Text(candidate.comment)
                        .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let pairName = candidate.draft.selectedPairDisplayName {
                        Text(pairName)
                            .font(.custom("Geist-Medium", size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.appPrimarySoft)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(isSelected ? 0.62 : 0.34), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.appPrimary.opacity(0.55) : Color.white.opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? AppStrings.watchingSelected : AppStrings.watchingNotSelected)
    }
}

private struct WatchingMomentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let timestampSeconds: Int
    let pairs: [PairSummary]
    let onSave: (String, PairSummary?) -> Void

    @State private var heartScream = ""
    @State private var selectedPairID: String?
    @FocusState private var isHeartScreamFocused: Bool

    init(
        timestampSeconds: Int,
        pairs: [PairSummary],
        selectedPairID: String?,
        onSave: @escaping (String, PairSummary?) -> Void
    ) {
        self.timestampSeconds = timestampSeconds
        self.pairs = pairs
        self.onSave = onSave
        _selectedPairID = State(initialValue: selectedPairID)
    }

    private var selectedPair: PairSummary? {
        pairs.first(where: { $0.id == selectedPairID })
    }

    private var canSave: Bool {
        !heartScream.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldLabel(AppStrings.watchingTimestamp)
                    Label(
                        WatchingModeViewModel.timestampText(timestampSeconds),
                        systemImage: "clock"
                    )
                    .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                    .glassCard(cornerRadius: 16)

                    fieldLabel(AppStrings.watchingHeartScream)
                    TextField(
                        AppStrings.watchingHeartScreamPlaceholder,
                        text: $heartScream,
                        axis: .vertical
                    )
                    .lineLimit(4...7)
                    .focused($isHeartScreamFocused)
                    .padding(16)
                    .frame(minHeight: 110, alignment: .topLeading)
                    .glassCard(cornerRadius: 16)
                    .onChange(of: heartScream) { _, value in
                        let limited = HeartScreamTextPolicy.limited(value)
                        if limited != value { heartScream = limited }
                    }

                    fieldLabel(AppStrings.watchingPair)
                    Picker(AppStrings.watchingPair, selection: $selectedPairID) {
                        Text(AppStrings.watchingPairOptional).tag(String?.none)
                        ForEach(pairs) { pair in
                            Text(pair.displayName).tag(Optional(pair.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    .glassCard(cornerRadius: 16)

                    Button {
                        onSave(heartScream, selectedPair)
                    } label: {
                        HStack(spacing: 10) {
                            MomentSparkleIcon(color: .white, width: 15, height: 22)
                            Text(AppStrings.watchingAddToLiveLog)
                        }
                            .font(.custom("Geist-SemiBold", size: 16, relativeTo: .headline))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appPrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.45)
                    .accessibilityIdentifier("watching_moment.save")

                    if HeartScreamTextPolicy.shouldShowCounter(for: heartScream) {
                        Text("\(heartScream.count) / \(HeartScreamTextPolicy.maximumLength)")
                            .font(.caption)
                            .foregroundStyle(
                                heartScream.count >= HeartScreamTextPolicy.warningThreshold
                                    ? Color.orange
                                    : Color.textSecondary
                            )
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(24)
            }
            .background(Color.surfaceWhite.opacity(0.7))
            .navigationTitle(AppStrings.watchingMomentSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .accessibilityIdentifier("watching_moment.sheet")
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            isHeartScreamFocused = true
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.custom("Geist-SemiBold", size: 11, relativeTo: .caption2))
            .foregroundStyle(Color.appPrimarySoft)
    }
}

@MainActor
private struct WatchingReactionDock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false
    @State private var selectedSectionID = ReactionCatalog.sections.first?.id ?? "positive"
    @State private var lastTappedID: String?
    @State private var dockFrame = CGRect.zero
    @State private var chipFrames: [String: CGRect] = [:]

    let isEnabled: Bool
    let hapticFeedbackEnabled: Bool
    let onReaction: (NewMomentDraft.SelectedReaction, CGPoint) -> Void

    private var selectedSection: ReactionCatalog.Section {
        ReactionCatalog.sections.first(where: { $0.id == selectedSectionID })
            ?? ReactionCatalog.sections[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedDock
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Button {
                    guard isEnabled else { return }
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        isExpanded = true
                    }
                } label: {
                    Label(AppStrings.watchingReaction, systemImage: "chevron.up")
                        .font(.custom("Geist-SemiBold", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background(.regularMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1 : 0.42)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12).onEnded { value in
                        guard isEnabled, value.translation.height < -24 else { return }
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            isExpanded = true
                        }
                    }
                )
                .accessibilityIdentifier("watching_reaction.open")
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }

    private var expandedDock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isExpanded = false
                }
            } label: {
                Capsule()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 42, height: 5)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.watchingCloseReactions)

            categoryTabs

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: 3
                ),
                spacing: 8
            ) {
                ForEach(selectedSection.reactions) { reaction in
                    reactionChip(reaction)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(.regularMaterial, in: UnevenRoundedRectangle(
            topLeadingRadius: 26,
            topTrailingRadius: 26
        ))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
                .stroke(.white.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: Color.appPrimary.opacity(0.14), radius: 18, y: -6)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(WatchingMotionCoordinateSpace.name))
        } action: { frame in
            dockFrame = frame
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 46 {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        isExpanded = false
                    }
                }
            }
        )
        .accessibilityIdentifier("watching_reaction.dock")
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(ReactionCatalog.sections) { section in
                    let isSelected = selectedSectionID == section.id
                    Button {
                        selectedSectionID = section.id
                    } label: {
                        VStack(spacing: 5) {
                            Text(section.title)
                                .font(.custom(
                                    isSelected ? "Geist-SemiBold" : "Geist-Medium",
                                    size: 11,
                                    relativeTo: .caption2
                                ))
                                .foregroundStyle(
                                    isSelected ? Color.appPrimary : Color.textSecondary
                                )
                                .lineLimit(1)

                            Capsule()
                                .fill(isSelected ? Color.appPrimary : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .background(
                            isSelected ? Color.appPrimary.opacity(0.07) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityIdentifier("watching_reaction.category.\(section.id)")
                }
            }
        }
        .accessibilityIdentifier("watching_reaction.categories")
    }

    private func reactionChip(
        _ reaction: NewMomentDraft.SelectedReaction
    ) -> some View {
        Button {
            let chipFrame = chipFrames[reaction.id] ?? dockFrame
            let origin = CGPoint(
                x: chipFrame.midX,
                y: dockFrame.minY + 8
            )
            onReaction(reaction, origin)
            performHaptic()
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
                lastTappedID = reaction.id
            }
            Task {
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(.easeOut(duration: 0.12)) {
                    if lastTappedID == reaction.id {
                        lastTappedID = nil
                    }
                }
            }
        } label: {
            Text(reaction.displayText)
                .font(.custom("Geist-SemiBold", size: 12, relativeTo: .subheadline))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(0.54), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.95), lineWidth: 1))
                .scaleEffect(lastTappedID == reaction.id ? 1.08 : 1)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(WatchingMotionCoordinateSpace.name))
        } action: { frame in
            chipFrames[reaction.id] = frame
        }
        .accessibilityIdentifier("watching_reaction.\(reaction.id)")
    }

    private func performHaptic() {
        guard hapticFeedbackEnabled else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
