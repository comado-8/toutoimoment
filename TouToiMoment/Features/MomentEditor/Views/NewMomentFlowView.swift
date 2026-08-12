import SwiftUI

struct NewMomentFlowView: View {
    @StateObject private var viewModel: NewMomentCreationViewModel
    @State private var activeSheet: NewMomentCreationSheet?

    let onSave: (NewMomentDraft) -> Void
    let onCancel: (Bool) -> Void

    init(
        viewModel: NewMomentCreationViewModel,
        onSave: @escaping (NewMomentDraft) -> Void,
        onCancel: @escaping (Bool) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            switch viewModel.phase {
            case .heartScream:
                NewMomentCaptureStepView(
                    viewModel: viewModel,
                    kind: .heartScream,
                    onClose: requestClose
                )
            case .scene:
                NewMomentCaptureStepView(
                    viewModel: viewModel,
                    kind: .scene,
                    onClose: requestClose
                )
            case .details:
                NewMomentDetailsView(
                    viewModel: viewModel,
                    onClose: requestClose,
                    onSave: { onSave(viewModel.draft) },
                    onPresentSheet: { activeSheet = $0 }
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadOptionsIfNeeded()
        }
        .task(id: viewModel.draft.selectedSourceID) {
            await viewModel.loadEpisodes()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .pair:
                PairEditPickerSheet(
                    options: viewModel.pairOptions,
                    selectedID: viewModel.draft.selectedPairID,
                    onSelect: {
                        viewModel.selectPair(id: $0)
                        activeSheet = nil
                    },
                    onCreate: { activeSheet = .newPair },
                    onCancel: { activeSheet = nil }
                )
            case .newPair:
                PairEditorSheet(
                    createAction: { try await viewModel.createPair(request: $0) },
                    onCreated: { _ in activeSheet = nil }
                )
            case .source:
                SourceEditPickerSheet(
                    options: viewModel.sourceOptions,
                    selectedID: viewModel.draft.selectedSourceID,
                    onSelect: {
                        viewModel.selectSource(id: $0)
                        activeSheet = nil
                    },
                    onCreate: {
                        activeSheet = .newSource
                    },
                    onCancel: { activeSheet = nil }
                )
            case .newSource:
                NewSourceSheet(
                    saveAction: { try await viewModel.createSource($0) },
                    onCreated: { _ in activeSheet = nil }
                )
            case .reaction:
                ReactionEditPickerSheet(
                    selection: viewModel.reactionSelectionIDs,
                    onToggle: viewModel.toggleReaction,
                    onCancel: {
                        viewModel.cancelReactionEditing()
                        activeSheet = nil
                    },
                    onSave: {
                        viewModel.commitReactionEditing()
                        activeSheet = nil
                    }
                )
            case .episode:
                NewEpisodeSheet(
                    schema: viewModel.sourceSchema,
                    saveAction: { try await viewModel.createEpisode($0) },
                    onCreated: { _ in activeSheet = nil }
                )
            case .timestamp(let key):
                TimestampEditSheet(
                    initialValue: viewModel.timestampComponents(for: key),
                    onCancel: { activeSheet = nil },
                    onSave: { hour, minute, second in
                        viewModel.updateTimestamp(
                            key: key,
                            hour: hour,
                            minute: minute,
                            second: second
                        )
                        activeSheet = nil
                    }
                )
            }
        }
    }

    private func requestClose() {
        if viewModel.phase != .details {
            viewModel.cancelCaptureEdit()
            if viewModel.phase == .details {
                return
            }
        }
        onCancel(viewModel.hasEnteredContent)
    }
}

private enum NewMomentCaptureKind {
    case heartScream
    case scene
}

private struct NewMomentCaptureStepView: View {
    @ObservedObject var viewModel: NewMomentCreationViewModel
    let kind: NewMomentCaptureKind
    let onClose: () -> Void

    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            captureHeader

            NewMomentThreeStepProgress(activeCount: kind == .heartScream ? 1 : 2)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("InstrumentSerif-Regular", size: 20, relativeTo: .title3))
                        .foregroundStyle(Color.textPrimary)

                    Text(subtitle)
                        .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.textSecondary)
                }

                ZStack(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                            .foregroundStyle(Color(hex: "#9B9EC4"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: text)
                        .font(.custom("Geist-Medium", size: 15, relativeTo: .body))
                        .foregroundStyle(Color.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .focused($isEditorFocused)
                        .accessibilityIdentifier(
                            kind == .heartScream
                                ? "new_moment.heart_scream.input"
                                : "new_moment.scene.input"
                        )
                }
                .frame(maxHeight: .infinity)
                .background(
                    NewMomentGlassFieldBackground(cornerRadius: 24)
                )

                if kind == .scene {
                    MomentSceneCharacterCounter(text: viewModel.draft.sceneSummary)
                } else if HeartScreamTextPolicy.shouldShowCounter(
                    for: viewModel.draft.heartScream
                ) {
                    Text("\(viewModel.draft.heartScream.count) / \(HeartScreamTextPolicy.maximumLength)")
                        .font(.caption)
                        .foregroundStyle(
                            viewModel.draft.heartScream.count >= HeartScreamTextPolicy.warningThreshold
                                ? Color.orange
                                : Color.textSecondary
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if kind == .scene {
                Button {
                    isEditorFocused = false
                    viewModel.returnFromScene()
                } label: {
                    Label(AppStrings.newMomentBack, systemImage: "chevron.left")
                        .font(.custom("Geist-SemiBold", size: 15, relativeTo: .body))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("new_moment.scene.back")
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                isEditorFocused = true
            }
        }
    }

    private var captureHeader: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.50), in: Circle())
                    .overlay {
                        Circle().stroke(Color(hex: "#E8E6F4"), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.newMomentDismiss)

            Spacer(minLength: 0)

            Text(AppStrings.newMomentStep1ScreenTitle)
                .font(.custom("InstrumentSerif-Regular", size: 26, relativeTo: .title2))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 0)

            Button {
                isEditorFocused = false
                switch kind {
                case .heartScream:
                    viewModel.advanceFromHeartScream()
                case .scene:
                    viewModel.advanceFromScene()
                }
            } label: {
                Text(AppStrings.newMomentStep1Next)
                    .font(.custom("Geist-Bold", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Color.appPrimary.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(kind == .heartScream && !viewModel.canAdvanceHeartScream)
            .opacity(kind == .heartScream && !viewModel.canAdvanceHeartScream ? 0.36 : 1)
            .accessibilityIdentifier(
                kind == .heartScream
                    ? "new_moment.heart_scream.next"
                    : "new_moment.scene.next"
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(height: 60)
    }

    private var title: String {
        kind == .heartScream
            ? AppStrings.newMomentHeartScreamTitle
            : AppStrings.newMomentSceneTitle
    }

    private var subtitle: String {
        kind == .heartScream
            ? AppStrings.newMomentHeartScreamSubtitle
            : AppStrings.newMomentSceneSubtitle
    }

    private var placeholder: String {
        kind == .heartScream
            ? AppStrings.newMomentStep3HeartScreamPlaceholder
            : AppStrings.newMomentStep3SceneSummaryPlaceholder
    }

    private var text: Binding<String> {
        switch kind {
        case .heartScream:
            Binding(
                get: { viewModel.draft.heartScream },
                set: viewModel.updateHeartScream
            )
        case .scene:
            Binding(
                get: { viewModel.draft.sceneSummary },
                set: viewModel.updateScene
            )
        }
    }
}

private struct NewMomentDetailsView: View {
    @ObservedObject var viewModel: NewMomentCreationViewModel
    let onClose: () -> Void
    let onSave: () -> Void
    let onPresentSheet: (NewMomentCreationSheet) -> Void

    @FocusState private var focusedField: String?

    var body: some View {
        VStack(spacing: 0) {
            NewMomentFlowHeader(onDismiss: onClose)

            NewMomentThreeStepProgress(activeCount: 3)
                .padding(.top, 12)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    momentTitleField

                    momentDateField

                    capturePreviewCard(
                        title: AppStrings.newMomentHeartScreamCardTitle,
                        value: viewModel.draft.heartScream,
                        emptyValue: AppStrings.newMomentRequiredHeartScream,
                        isRequiredError: !viewModel.draft.hasRequiredHeartScream,
                        editAction: viewModel.editHeartScream
                    )

                    capturePreviewCard(
                        title: AppStrings.newMomentSceneCardTitle,
                        value: viewModel.draft.sceneSummary,
                        emptyValue: AppStrings.newMomentSceneEmpty,
                        isRequiredError: false,
                        editAction: viewModel.editScene
                    )

                    reactionSection

                    Rectangle()
                        .fill(Color(hex: "#D4D0E8", opacity: 0.7))
                        .frame(height: 1)

                    metadataSection

                    saveButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppStrings.newMomentStep2KeyboardDone) {
                    focusedField = nil
                }
            }
        }
        .accessibilityIdentifier("new_moment.details")
    }

    private var momentTitleField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppStrings.momentTitleOptionalLabel)
                .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                .tracking(1)
                .foregroundStyle(Color.appPrimary)

            TextField(
                AppStrings.momentTitlePlaceholder,
                text: Binding(
                    get: { viewModel.draft.momentTitle },
                    set: viewModel.updateMomentTitle
                )
            )
            .focused($focusedField, equals: "moment-title")
            .font(.custom("Geist-Medium", size: 15, relativeTo: .body))
            .foregroundStyle(Color.textPrimary)
            .accessibilityIdentifier("new_moment.details.title")

            if MomentTitlePolicy.shouldShowCounter(for: viewModel.draft.momentTitle) {
                Text("\(viewModel.draft.momentTitle.count) / \(MomentTitlePolicy.maximumLength)")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20, fillOpacity: 0.63)
    }

    private var momentDateField: some View {
        HStack(spacing: 12) {
            Text(AppStrings.momentDate)
                .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                .tracking(1)
                .foregroundStyle(Color.appPrimary)

            Spacer(minLength: 12)

            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.draft.momentDate.date() },
                    set: viewModel.updateMomentDate
                ),
                in: ...Date.now,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .accessibilityLabel(AppStrings.momentDate)
            .accessibilityIdentifier("new_moment.details.date")
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .glassCard(cornerRadius: 20, fillOpacity: 0.63)
    }

    private func capturePreviewCard(
        title: String,
        value: String,
        emptyValue: String,
        isRequiredError: Bool,
        editAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                    .tracking(1)
                    .foregroundStyle(Color.appPrimary)

                Spacer()

                Button(action: editAction) {
                    Label(AppStrings.newMomentEdit, systemImage: "square.and.pencil")
                        .font(.custom("Geist-Medium", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color(hex: "#8382FC"))
                }
                .buttonStyle(.plain)
            }

            Text(value.isEmpty ? emptyValue : value)
                .font(.custom("Geist-Medium", size: 15, relativeTo: .body))
                .foregroundStyle(value.isEmpty ? Color.textSecondary : Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isRequiredError {
                Text(AppStrings.newMomentRequiredHeartScream)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20, fillOpacity: 0.63)
    }

    private var reactionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppStrings.newMomentReactionTags)
                .font(.custom("Geist-Bold", size: 12, relativeTo: .caption))
                .tracking(1)
                .foregroundStyle(Color(hex: "#4A4A68"))

            Button {
                viewModel.beginReactionEditing()
                onPresentSheet(.reaction)
            } label: {
                if viewModel.draft.selectedReactions.isEmpty {
                    Text(AppStrings.newMomentStep4AddReactions)
                        .font(.custom("Geist-SemiBold", size: 14, relativeTo: .subheadline))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    Color.appPrimarySoft.opacity(0.7),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        }
                } else {
                    NewMomentDetailsFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(viewModel.draft.selectedReactions) { reaction in
                            Text(reaction.displayText)
                                .font(.custom("Geist-Medium", size: 12, relativeTo: .caption))
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 29)
                                .background(Color.white.opacity(0.82), in: Capsule())
                        }

                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.72), in: Circle())
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("new_moment.details.reactions")
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            selectionSection(
                title: AppStrings.newMomentStep1PairLabel,
                value: viewModel.draft.selectedPairDisplayName
                    ?? AppStrings.newMomentStep1PairPlaceholder,
                isSelected: viewModel.draft.selectedPairID != nil,
                action: { onPresentSheet(.pair) },
                newTitle: AppStrings.newMomentStep1NewPair,
                newAction: { onPresentSheet(.newPair) }
            )

            selectionSection(
                title: AppStrings.newMomentStep1SourceLabel,
                value: viewModel.draft.selectedSourceDisplayName
                    ?? AppStrings.newMomentStep1SourcePlaceholder,
                isSelected: viewModel.draft.selectedSourceID != nil,
                action: { onPresentSheet(.source) },
                newTitle: AppStrings.newMomentStep1NewSource,
                newAction: { onPresentSheet(.newSource) }
            )

            if viewModel.draft.selectedSourceID != nil,
               viewModel.sourceSchema.supportsEpisodes
                || !viewModel.sourceSchema.momentLocationFields.isEmpty {
                sourceDetailSection
            }

            if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                    Button(AppStrings.newMomentStep1Retry) {
                        Task { await viewModel.retryOptions() }
                    }
                }
            }
        }
    }

    private func selectionSection(
        title: String,
        value: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        newTitle: String,
        newAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                .tracking(1)
                .foregroundStyle(Color(hex: "#4A4A68"))

            Button(action: action) {
                HStack {
                    Text(value)
                        .font(.custom("Geist-Regular", size: 15, relativeTo: .body))
                        .foregroundStyle(isSelected ? Color.textPrimary : Color(hex: "#9B9EC4"))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appPrimarySoft)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(NewMomentGlassFieldBackground())
            }
            .buttonStyle(.plain)

            Button(newTitle, action: newAction)
                .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                .foregroundStyle(Color.appPrimarySoft)
        }
    }

    private var sourceDetailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSourceDetailExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AppStrings.newMomentEpisodeSectionTitle)
                            .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                            .tracking(1)
                            .foregroundStyle(Color(hex: "#4A4A68"))
                        Text(viewModel.sourceSchema.mediaLabelJa)
                            .font(.custom("Geist-Regular", size: 11, relativeTo: .caption2))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appPrimarySoft)
                        .rotationEffect(.degrees(viewModel.isSourceDetailExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("new_moment.details.source_detail.toggle")

            if viewModel.isSourceDetailExpanded {
                if viewModel.sourceSchema.supportsEpisodes {
                    episodePicker
                }

                ForEach(viewModel.contextFields) { field in
                    contextField(field)
                }
            }
        }
    }

    private var episodePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(AppStrings.newMomentEpisodeSectionTitle.uppercased())
                    .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                    .foregroundStyle(Color(hex: "#4A4A68"))
                Spacer()
                Button {
                    onPresentSheet(.episode)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .tint(Color.appPrimary)
                .accessibilityIdentifier("new_moment.details.episode.add")
            }

            Menu {
                Button(AppStrings.newMomentEpisodeNone) {
                    viewModel.selectEpisode(id: nil)
                }
                ForEach(viewModel.episodes) { episode in
                    Button(episodeDisplayName(episode)) {
                        viewModel.selectEpisode(id: episode.id)
                    }
                }
            } label: {
                HStack {
                    Text(selectedEpisodeDisplayName)
                        .foregroundStyle(
                            viewModel.draft.selectedEpisode == nil
                                ? Color.textSecondary
                                : Color.textPrimary
                        )
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.appPrimarySoft)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(NewMomentGlassFieldBackground())
            }

            if let episodeErrorMessage = viewModel.episodeErrorMessage {
                Text(episodeErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
        }
    }

    private func contextField(_ field: MomentLocationField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label)
                .font(.custom("Geist-Bold", size: 11, relativeTo: .caption))
                .foregroundStyle(Color(hex: "#4A4A68"))

            if field.inputKind == .timestamp {
                Button {
                    focusedField = nil
                    onPresentSheet(.timestamp(field.key))
                } label: {
                    HStack {
                        Text(
                            viewModel.value(for: field.key).isEmpty
                                ? field.placeholder
                                : viewModel.value(for: field.key)
                        )
                        .foregroundStyle(
                            viewModel.value(for: field.key).isEmpty
                                ? Color.textSecondary
                                : Color.textPrimary
                        )
                        Spacer()
                        Image(systemName: "clock")
                            .foregroundStyle(Color.appPrimary)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(NewMomentGlassFieldBackground())
                }
                .buttonStyle(.plain)
            } else if field.inputKind == .choice {
                Menu {
                    ForEach(field.options) { option in
                        Button(option.label) {
                            viewModel.updateValue(for: field, value: option.id)
                        }
                    }
                } label: {
                    HStack {
                        Text(
                            field.options.first {
                                $0.id == viewModel.value(for: field.key)
                            }?.label ?? field.placeholder
                        )
                        .foregroundStyle(
                            viewModel.value(for: field.key).isEmpty
                                ? Color.textSecondary
                                : Color.textPrimary
                        )
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Color.appPrimarySoft)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(NewMomentGlassFieldBackground())
                }
            } else {
                HStack {
                    TextField(
                        field.placeholder,
                        text: Binding(
                            get: { viewModel.value(for: field.key) },
                            set: { viewModel.updateValue(for: field, value: $0) }
                        )
                    )
                    .keyboardType(field.inputKind == .decimal ? .decimalPad : .numberPad)
                    .focused($focusedField, equals: field.key)

                    if let unit = field.unit {
                        Text(unit)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(NewMomentGlassFieldBackground())
            }

            if let schemaField = viewModel.sourceSchema.momentLocationFields.first(
                where: { $0.key == field.key }
            ), !LocatorValuePolicy.isValid(viewModel.value(for: field.key), for: schemaField) {
                Text(AppStrings.newEpisodeInvalidValue)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
        }
    }

    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: 8) {
                MomentSparkleIcon(color: .white, width: 13, height: 21)
                Text(AppStrings.newMomentStep4SaveMoment)
                    .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(
                        viewModel.canSave
                            ? Color.appPrimary
                            : Color.appPrimary.opacity(0.26)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .accessibilityIdentifier("new_moment.details.save")
    }

    private var selectedEpisodeDisplayName: String {
        guard let episode = viewModel.draft.selectedEpisode else {
            return AppStrings.newMomentEpisodeNone
        }
        return episode.displayName
    }

    private func episodeDisplayName(_ episode: EpisodeSummary) -> String {
        viewModel.sourceSchema.episodeDisplayName(for: episode.locatorValues)
    }
}

enum NewMomentCreationSheet: Identifiable {
    case pair
    case newPair
    case source
    case newSource
    case reaction
    case episode
    case timestamp(String)

    var id: String {
        switch self {
        case .pair: "pair"
        case .newPair: "new-pair"
        case .source: "source"
        case .newSource: "new-source"
        case .reaction: "reaction"
        case .episode: "episode"
        case .timestamp(let key): "timestamp-\(key)"
        }
    }
}

private struct NewMomentThreeStepProgress: View {
    let activeCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < activeCount ? Color.appPrimary : Color(hex: "#D7D4EA"))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppStrings.newMomentThreeStepProgress(activeCount))
    }
}

private struct NewMomentDetailsFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layout(maxWidth: proposal.width ?? 0, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(maxWidth: bounds.width, subviews: subviews)
        for item in result.items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func layout(maxWidth: CGFloat, subviews: Subviews) -> (
        items: [(index: Int, origin: CGPoint, size: CGSize)],
        height: CGFloat
    ) {
        var items: [(Int, CGPoint, CGSize)] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            items.append((index, CGPoint(x: x, y: y), size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return (items, y + rowHeight)
    }
}
