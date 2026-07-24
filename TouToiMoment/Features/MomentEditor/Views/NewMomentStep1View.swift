import Combine
import SwiftUI

struct NewMomentStep1View: View {
    private enum PairColorTarget {
        case member1
        case member2
    }

    private enum FormField: Hashable {
        case member1
        case member2
        case pairName
        case sourceName
    }

    private enum PickerKind {
        case pair
        case source
    }

    private enum ActiveSheet: Hashable {
        case newPair
        case newSource
    }

    private enum SourceMediumOption: String, CaseIterable, Identifiable {
        case anime = "anime"
        case tvDrama = "tv_drama"
        case movie = "movie"
        case manga = "manga"
        case novel = "novel"
        case doujinBook = "doujin_book"
        case youtubeVideo = "youtube_video"
        case youtubeLive = "youtube_live"
        case streaming = "streaming"
        case radioPodcast = "radio_podcast"
        case musicVideo = "music_video"
        case liveConcert = "live_concert"
        case stageMusical = "stage_musical"
        case eventFanmeeting = "event_fanmeeting"
        case magazine = "magazine"
        case bookInterview = "book_interview"
        case snsPost = "sns_post"
        case blogArticle = "blog_article"
        case game = "game"
        case voiceDrama = "voice_drama"
        case other = "other"

        var id: String { rawValue }

        var title: String {
            SourceLocatorSchema.schema(for: rawValue)?.mediaLabelJa ?? rawValue
        }

        var mediaType: String {
            rawValue
        }
    }

    private static let pairColorSwatches: [String] = [
        "#EF4444", "#F97316", "#EAB308", "#22C55E",
        "#14B8A6", "#3B82F6", "#6366F1", "#A855F7",
        "#EC4899", "#F472B6", "#FB7185", "#64748B",
        "#1E293B", "#6B7280", "#D97706", "#FFFFFF",
    ]

    @StateObject private var viewModel: NewMomentStep1ViewModel
    @State private var activePicker: PickerKind?
    @State private var activeSheet: ActiveSheet?
    @State private var isHelpPresented = false
    @State private var activePairColorTarget: PairColorTarget?
    @State private var newPairMember1Name = ""
    @State private var newPairMember2Name = ""
    @State private var newPairName = ""
    @State private var member1ColorHex = "#3B82F6"
    @State private var member2ColorHex = "#F472B6"
    @State private var newSourceName = ""
    @State private var selectedSourceMedium: SourceMediumOption?
    @State private var isCreatingSource = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: FormField?

    let onContinue: (NewMomentDraft) -> Void
    let onCancel: () -> Void

    init(
        viewModel: NewMomentStep1ViewModel,
        onContinue: @escaping (NewMomentDraft) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                progressDots
                    .padding(.top, 13)

                ScrollView(.vertical, showsIndicators: false) {
                    Group {
                        if let errorMessage = viewModel.errorMessage {
                            loadErrorView(message: errorMessage)
                        } else {
                            VStack(spacing: 8) {
                                chooseSection
                                separator
                                summaryRow(
                                    title: AppStrings.newMomentStep2Title,
                                    subtitle: AppStrings.newMomentStep2Subtitle
                                )
                                separator
                                summaryRow(
                                    title: AppStrings.newMomentStep3Title,
                                    subtitle: AppStrings.newMomentStep3Subtitle
                                )
                                separator
                                summaryRow(
                                    title: AppStrings.newMomentStep4Title,
                                    subtitle: AppStrings.newMomentStep4Subtitle
                                )
                            }
                        }
                    }
                    .padding(.top, 13)
                    .padding(.bottom, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            if activeSheet != nil {
                Color.black.opacity(0.14)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismissActiveSheet()
                    }

                GeometryReader { proxy in
                    activeSheetView
                        .padding(.bottom, bottomSheetBottomPadding(safeAreaBottom: proxy.safeAreaInsets.bottom))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(5)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if activeSheet == nil {
                nextButtonContainer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .animation(.spring(duration: 0.32, bounce: 0.12), value: activeSheet)
        .animation(.easeOut(duration: 0.24), value: keyboardHeight)
        .alert(AppStrings.newMomentStep1HelpTitle, isPresented: $isHelpPresented) {
            Button(AppStrings.newMomentStep1HelpDismiss, role: .cancel) {}
        } message: {
            Text(AppStrings.newMomentStep1HelpMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(notification: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onChange(of: newPairMember2Name) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               activePairColorTarget == .member2 {
                activePairColorTarget = nil
            }
        }
        .onTapGesture {
            guard activeSheet == nil else {
                return
            }
            activePicker = nil
            activePairColorTarget = nil
        }
    }

    private func loadErrorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.retry()
                }
            } label: {
                Text(AppStrings.newMomentStep1Retry)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.72))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 96)
    }

    private var header: some View {
        HStack {
            Text(AppStrings.newMomentStep1ScreenTitle)
                .font(.custom("InstrumentSerif-Regular", size: 26))
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 12)

            Button(action: onCancel) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.50))

                    Circle()
                        .stroke(Color(hex: "#E8E6F4"), lineWidth: 1)

                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.newMomentDismiss)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(height: 60)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == 0 ? Color.appPrimary : Color(hex: "#D7D4EA"))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppStrings.newMomentStep1Progress)
    }

    private var chooseSection: some View {
        HStack(alignment: .top, spacing: 8) {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimarySoft.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 3, height: 232)
            .clipShape(Capsule(style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(AppStrings.newMomentStep1ChooseTitle)
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(Color.appPrimary)

                Text(AppStrings.newMomentStep1PairLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "#4A4A68"))

                VStack(alignment: .leading, spacing: 6) {
                    selectField(
                        title: viewModel.pairFieldValue,
                        textColor: viewModel.draft.selectedPairID == nil ? Color.textSecondary : Color.textPrimary,
                        action: { togglePicker(.pair) }
                    )
                    .overlay(alignment: .topLeading) {
                        if activePicker == .pair {
                            dropdownList(
                                options: viewModel.pairDropdownOptions,
                                rowTextColor: Color.textPrimary,
                                selectedOptionID: viewModel.draft.selectedPairID,
                                noneOptionID: nil,
                                action: { option in
                                    viewModel.selectPair(id: option.id)
                                    activePicker = nil
                                }
                            )
                            .offset(y: 48)
                        }
                    }
                    .zIndex(activePicker == .pair ? 3 : 0)

                    actionLink(
                        title: AppStrings.newMomentStep1NewPair,
                        action: { presentNewPairSheet() }
                    )
                }
                .zIndex(activePicker == .pair ? 3 : 0)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .top, spacing: 4) {
                        Text(AppStrings.newMomentStep1SourceLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(Color(hex: "#4A4A68"))

                        Button(action: { isHelpPresented = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#D9D9D9"))
                                Text("?")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.white)
                            }
                            .frame(width: 14, height: 14)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppStrings.newMomentStep1HelpTitle)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        selectField(
                            title: viewModel.sourceFieldValue,
                            textColor: viewModel.draft.selectedSourceID == nil ? Color.textSecondary : Color.textPrimary,
                            action: { togglePicker(.source) }
                        )
                        .overlay(alignment: .topLeading) {
                            if activePicker == .source {
                                dropdownList(
                                    options: viewModel.sourceOptions,
                                    rowTextColor: Color(hex: "#1A1A1A"),
                                    selectedOptionID: viewModel.draft.selectedSourceID,
                                    noneOptionID: nil,
                                    action: { option in
                                        viewModel.selectSource(id: option.id)
                                        activePicker = nil
                                    }
                                )
                                .offset(y: 48)
                            }
                        }
                        .zIndex(activePicker == .source ? 3 : 0)

                        actionLink(
                            title: AppStrings.newMomentStep1NewSource,
                            action: { presentNewSourceSheet() }
                        )
                    }
                    .zIndex(activePicker == .source ? 3 : 0)
                }
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .zIndex(1)
    }

    private var nextButtonContainer: some View {
        VStack(spacing: 0) {
            Button(action: { onContinue(viewModel.draft) }) {
                Text(AppStrings.newMomentStep1Next)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule(style: .continuous)
                            .fill(viewModel.draft.selectedPairID == nil ? Color.appPrimary.opacity(0.35) : Color.appPrimary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.draft.selectedPairID == nil)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.clear)
    }

    @ViewBuilder
    private var activeSheetView: some View {
        switch activeSheet {
        case .newPair:
            newPairSheet
        case .newSource:
            newSourceSheet
        case .none:
            EmptyView()
        }
    }

    private func selectField(
        title: String,
        textColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(textColor)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(fieldBackground)
        }
        .buttonStyle(.plain)
    }

    private func dropdownList(
        options: [NewMomentSelectableOption],
        rowTextColor: Color,
        selectedOptionID: String?,
        noneOptionID: String?,
        action: @escaping (NewMomentSelectableOption) -> Void
    ) -> some View {
        let visibleRowCount = min(options.count, 5)

        return ScrollView(.vertical, showsIndicators: options.count > 5) {
            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    let isNoneOption = option.id == noneOptionID
                    let isSelected = isNoneOption ? selectedOptionID == nil : selectedOptionID == option.id

                    Button(action: { action(option) }) {
                        HStack {
                            Text(option.title)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(isNoneOption ? Color.textPrimary.opacity(0.82) : rowTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(
                            dropdownRowBackground(
                                isLast: index == options.count - 1,
                                isMuted: isNoneOption
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    if index != options.count - 1 {
                        Rectangle()
                            .fill(Color(hex: "#D4D0E8", opacity: 0.7))
                            .frame(height: 1)
                    }
                }
            }
        }
        .frame(width: 320, height: CGFloat(visibleRowCount * 48))
        .background(dropdownContainerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var dropdownContainerBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.60))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "#C4B5F0", opacity: 0.19), location: 0),
                                .init(color: Color.white.opacity(0), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
    }

    private func dropdownRowBackground(isLast: Bool, isMuted: Bool) -> some View {
        RoundedRectangle(cornerRadius: isLast ? 20 : 0, style: .continuous)
            .fill(Color.white.opacity(isMuted ? 0.34 : 0.40))
            .overlay {
                RoundedRectangle(cornerRadius: isLast ? 20 : 0, style: .continuous)
                    .stroke(Color.white, lineWidth: 1)
            }
            .shadow(color: Color(hex: "#7C6FCD", opacity: 0.08), radius: 20, x: 0, y: 4)
    }

    private func actionLink(title: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appPrimarySoft)
        }
        .buttonStyle(.plain)
    }

    private var newPairSheet: some View {
        bottomSheetContainer {
            HStack {
                Button(action: { dismissNewPairSheet() }) {
                    Text(AppStrings.newMomentStep1NewPairCancel)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 12)

                Text(AppStrings.newMomentStep1NewPairSheetTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 12)

                Button(action: { saveNewPair() }) {
                    Text(AppStrings.newMomentStep1NewPairSave)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(canSaveNewPair ? Color.appPrimary : Color.appPrimary.opacity(0.35))
                }
                .buttonStyle(.plain)
                .disabled(!canSaveNewPair)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 28) {
                newPairMemberSection(
                    title: AppStrings.newMomentStep1NewPairMember1Label,
                    text: $newPairMember1Name,
                    placeholder: AppStrings.newMomentStep1NewPairMember1Placeholder,
                    colorHex: member1ColorHex,
                    target: .member1
                )

                newPairMemberSection(
                    title: AppStrings.newMomentStep1NewPairMember2Label,
                    text: $newPairMember2Name,
                    placeholder: AppStrings.newMomentStep1NewPairMember2Placeholder,
                    colorHex: member2ColorHex,
                    target: .member2,
                    isColorEnabled: isMember2ColorEnabled
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text(AppStrings.newMomentStep1NewPairNameLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "#6B7280"))

                        Text(AppStrings.newMomentStep1NewPairOptional)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color(hex: "#9B9EC4"))
                    }

                    TextField("", text: $newPairName, prompt: Text(AppStrings.newMomentStep1NewPairNamePlaceholder).foregroundStyle(Color(hex: "#9B9EC4")))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.textPrimary)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .pairName)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(sheetInputBackground)
                        .onSubmit {
                            focusedField = nil
                        }
                        .onTapGesture {
                            activePairColorTarget = nil
                        }

                    Text(AppStrings.newMomentStep1NewPairNameNote)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }

    private var newSourceSheet: some View {
        bottomSheetContainer {
            HStack {
                Button(action: { dismissNewSourceSheet() }) {
                    Text(AppStrings.newMomentStep1NewSourceCancel)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 12)

                Text(AppStrings.newMomentStep1NewSourceSheetTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer(minLength: 12)

                Button(action: {
                    Task { await saveNewSource() }
                }) {
                    Text(AppStrings.newMomentStep1NewSourceSave)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(canSaveNewSource ? Color.appPrimary : Color.appPrimary.opacity(0.35))
                }
                .buttonStyle(.plain)
                .disabled(!canSaveNewSource || isCreatingSource)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppStrings.newMomentStep1NewSourceNameLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#6B7280"))

                    TextField("", text: $newSourceName, prompt: Text(AppStrings.newMomentStep1NewSourceNamePlaceholder).foregroundStyle(Color(hex: "#9B9EC4")))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.textPrimary)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .sourceName)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(sheetInputBackground)
                        .onSubmit {
                            focusedField = nil
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(AppStrings.newMomentStep1NewSourceMediumLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#6B7280"))

                    ChipFlowLayout(spacing: 8) {
                        ForEach(SourceMediumOption.allCases) { medium in
                            sheetChip(
                                title: medium.title,
                                isSelected: selectedSourceMedium == medium,
                                action: { selectSourceMedium(medium) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }

    private func bottomSheetContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(Color(hex: "#D1D5DB"))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 10)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sheetBackground)
        .clipShape(sheetShape)
    }

    private func newPairMemberSection(
        title: String,
        text: Binding<String>,
        placeholder: String,
        colorHex: String,
        target: PairColorTarget,
        isColorEnabled: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#6B7280"))

                Spacer(minLength: 12)

                Button(action: { togglePairColorPicker(target) }) {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .overlay {
                            if !isColorEnabled {
                                slashOverlay
                            }
                        }
                        .frame(width: 22, height: 22)
                        .opacity(isColorEnabled ? 1 : 0.35)
                }
                .buttonStyle(.plain)
                .disabled(!isColorEnabled)
            }
            .overlay(alignment: .topTrailing) {
                if isColorEnabled, activePairColorTarget == target {
                    pairColorPopup(selectedHex: colorHex)
                        .offset(y: 18)
                        .zIndex(10)
                }
            }

            TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Color(hex: "#9B9EC4")))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($focusedField, equals: target == .member1 ? .member1 : .member2)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(sheetInputBackground)
                .onSubmit {
                    switch target {
                    case .member1:
                        focusedField = .member2
                    case .member2:
                        focusedField = .pairName
                    }
                }
                .onTapGesture {
                    activePairColorTarget = nil
                }
        }
        .zIndex(activePairColorTarget == target ? 10 : 0)
    }

    private func pairColorPopup(selectedHex: String) -> some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { column in
                        let index = row * 4 + column
                        let hex = Self.pairColorSwatches[index]

                        Button(action: {
                            applyPairColor(hex, for: activePairColorTarget)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)

                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)

                                if hex == "#FFFFFF" {
                                    Circle()
                                        .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                                        .frame(width: 36, height: 36)
                                }

                                if selectedHex == hex {
                                    Circle()
                                        .stroke(Color(hex: "#3B82F6"), lineWidth: 3)
                                        .frame(width: 36, height: 36)

                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(13)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func sheetChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color(hex: "#5D617D"))
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.appPrimary : Color.white.opacity(0.88))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(isSelected ? Color.appPrimary : Color(hex: "#E5E7EB"), lineWidth: 1)
                        }
                )
        }
        .buttonStyle(.plain)
    }

    private var sheetInputBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
            }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.60))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "#C4B5F0", opacity: 0.19), location: 0),
                                .init(color: Color.white.opacity(0), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "#E8E6F4"), lineWidth: 1)
            }
    }

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24,
            style: .continuous
        )
    }

    private var sheetBackground: some View {
        ZStack {
            sheetShape
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#C4B6F0", opacity: 0.19), location: 0),
                            .init(color: .white.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            sheetShape
                .fill(Color.white.opacity(0.82))
        }
        .overlay {
            sheetShape
                .inset(by: 0.5)
                .stroke(Color.white, lineWidth: 1)
        }
        .shadow(color: Color(hex: "#7D70CC", opacity: 0.08), radius: 10, x: 0, y: 4)
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(hex: "#D4D0E8", opacity: 0.7))
            .frame(width: 342, height: 1)
    }

    private var slashOverlay: some View {
        Circle()
            .stroke(Color.white.opacity(0.92), lineWidth: 1)
            .overlay {
                Rectangle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 1.5, height: 22)
                    .rotationEffect(.degrees(45))
            }
    }

    private func summaryRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color(hex: "#9B9EC4"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "#9B9EC4"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 16)
        .frame(width: 342, alignment: .leading)
    }

    private func presentNewPairSheet() {
        activePicker = nil
        activePairColorTarget = nil
        focusedField = nil
        activeSheet = .newPair
    }

    private func dismissNewPairSheet() {
        activePairColorTarget = nil
        focusedField = nil
        keyboardHeight = 0
        activeSheet = nil
        newPairMember1Name = ""
        newPairMember2Name = ""
        newPairName = ""
        member1ColorHex = "#3B82F6"
        member2ColorHex = "#F472B6"
    }

    private func saveNewPair() {
        viewModel.createPair(
            displayName: resolvedPairDisplayName,
            nickname: generatedDisplayName,
            leadingColorHex: member1ColorHex,
            trailingColorHex: isMember2ColorEnabled ? member2ColorHex : nil
        )
        dismissNewPairSheet()
    }

    private func presentNewSourceSheet() {
        activePicker = nil
        activePairColorTarget = nil
        focusedField = nil
        activeSheet = .newSource
    }

    private func dismissNewSourceSheet() {
        focusedField = nil
        keyboardHeight = 0
        activeSheet = nil
        newSourceName = ""
        selectedSourceMedium = nil
    }

    private func dismissActiveSheet() {
        switch activeSheet {
        case .newPair:
            dismissNewPairSheet()
        case .newSource:
            dismissNewSourceSheet()
        case .none:
            break
        }
    }

    private func selectSourceMedium(_ medium: SourceMediumOption) {
        focusedField = nil
        selectedSourceMedium = medium
    }

    private func saveNewSource() async {
        guard let medium = selectedSourceMedium, !isCreatingSource else {
            return
        }

        isCreatingSource = true
        defer {
            isCreatingSource = false
        }

        let didCreate = await viewModel.createSource(
            displayName: newSourceName.trimmingCharacters(in: .whitespacesAndNewlines),
            helperText: makeSourceHelperText(medium: medium),
            mediaType: medium.mediaType,
            totalCount: nil,
            isFavorite: false
        )

        if didCreate {
            dismissNewSourceSheet()
        }
    }

    private func makeSourceHelperText(medium: SourceMediumOption) -> String {
        medium.title
    }

    private var canSaveNewSource: Bool {
        !newSourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedSourceMedium != nil
    }

    private func togglePairColorPicker(_ target: PairColorTarget) {
        if target == .member2, !isMember2ColorEnabled {
            activePairColorTarget = nil
            return
        }

        focusedField = nil
        activePairColorTarget = activePairColorTarget == target ? nil : target
    }

    private func applyPairColor(_ hex: String, for target: PairColorTarget?) {
        switch target {
        case .member1:
            member1ColorHex = hex
        case .member2:
            member2ColorHex = hex
        case .none:
            break
        }

        activePairColorTarget = nil
    }

    private var generatedDisplayName: String {
        let member1 = newPairMember1Name.trimmingCharacters(in: .whitespacesAndNewlines)
        let member2 = newPairMember2Name.trimmingCharacters(in: .whitespacesAndNewlines)

        if member1.isEmpty && member2.isEmpty {
            return AppStrings.newMomentStep1NewPairDisplayNamePlaceholder
        }

        if member1.isEmpty {
            return member2
        }

        if member2.isEmpty {
            return member1
        }

        return PairDisplayNameFormatter.joined(member1, member2)
    }

    private var resolvedPairDisplayName: String {
        let trimmedPairName = newPairName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPairName.isEmpty {
            return generatedDisplayName
        }

        return trimmedPairName
    }

    private var canSaveNewPair: Bool {
        !newPairMember1Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isMember2ColorEnabled: Bool {
        !newPairMember2Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func bottomSheetBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
        max(0, keyboardHeight - safeAreaBottom)
    }

    private func updateKeyboardHeight(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        keyboardHeight = max(0, keyboardFrame.height)
    }

    private func togglePicker(_ picker: PickerKind) {
        guard activeSheet == nil else {
            return
        }
        activePicker = activePicker == picker ? nil : picker
    }
}

private struct ChipFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let spacingBefore = currentRowWidth == 0 ? 0 : spacing

            if currentRowWidth + spacingBefore + size.width > maxWidth, currentRowWidth > 0 {
                totalHeight += currentRowHeight + spacing
                maxRowWidth = max(maxRowWidth, currentRowWidth)
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth += spacingBefore + size.width
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        totalHeight += currentRowHeight
        maxRowWidth = max(maxRowWidth, currentRowWidth)

        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let spacingBefore = x == bounds.minX ? 0 : spacing

            if x + spacingBefore + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            } else {
                x += spacingBefore
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            x += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NewMomentStep1View(
        viewModel: NewMomentStep1ViewModel(
            pairRepository: InMemoryPairRepository(),
            sourceRepository: InMemorySourceRepository()
        )
    )
}
