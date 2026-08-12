import SwiftUI

struct MomentEditView: View {
    @StateObject private var viewModel: MomentEditViewModel
    let onSave: (NewMomentDraft, MomentImageChangeSet) async -> Bool
    let onClose: () -> Void

    @State private var activeSheet: EditSheet?
    @State private var isDiscardConfirmationPresented = false
    @State private var isSaving = false
    @FocusState private var focusedField: String?

    init(
        viewModel: MomentEditViewModel,
        onSave: @escaping (NewMomentDraft, MomentImageChangeSet) async -> Bool,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 26) {
                    chooseSection

                    if viewModel.draft.selectedSource != nil {
                        contextSection
                    }

                    captureSection
                    reactionSection

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(Color.red)
                            .font(.footnote)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard(cornerRadius: 20, fillOpacity: 0.52)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 56)
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("moment.edit.form")
        }
        .navigationTitle(AppStrings.momentEditTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .tint(Color.appPrimary)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: requestClose) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel(AppStrings.momentEditBack)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(action: save) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(Color.appPrimary)
                .disabled(!viewModel.canSave || isSaving)
                .accessibilityLabel(AppStrings.momentEditSave)
                .accessibilityIdentifier("moment.edit.save")
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(AppStrings.newMomentStep2KeyboardDone) {
                    focusedField = nil
                }
            }
        }
        .confirmationDialog(
            AppStrings.momentEditDiscardTitle,
            isPresented: $isDiscardConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.momentEditDiscardConfirm, role: .destructive, action: onClose)
            Button(AppStrings.momentEditKeepEditing, role: .cancel) {}
        } message: {
            Text(AppStrings.momentEditDiscardMessage)
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
                    onCreate: { activeSheet = .newSource },
                    onCancel: { activeSheet = nil }
                )
            case .newSource:
                NewSourceSheet(
                    saveAction: { request in try await viewModel.createSource(request) },
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
        .task {
            await viewModel.loadOptionsIfNeeded()
        }
        .task(id: viewModel.draft.selectedSourceID) {
            await viewModel.loadEpisodes()
        }
    }

    private var chooseSection: some View {
        editSection(title: AppStrings.newMomentStep1ChooseTitle) {
            VStack(spacing: 0) {
                DatePicker(
                    AppStrings.momentDate,
                    selection: Binding(
                        get: { viewModel.draft.momentDate.date() },
                        set: viewModel.updateMomentDate
                    ),
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .padding(.vertical, 16)
                .accessibilityIdentifier("moment.edit.date")

                editDivider

                editSelectionRow(
                    title: AppStrings.newMomentStep1PairLabel,
                    value: viewModel.draft.selectedPairDisplayName
                        ?? AppStrings.newMomentStep1PairPlaceholder,
                    isPlaceholder: viewModel.draft.selectedPairID == nil,
                    action: { activeSheet = .pair }
                )

                editDivider

                editSelectionRow(
                    title: AppStrings.newMomentStep1SourceLabel,
                    value: viewModel.draft.selectedSourceDisplayName
                        ?? AppStrings.newMomentStep1SourcePlaceholder,
                    isPlaceholder: viewModel.draft.selectedSourceID == nil,
                    action: { activeSheet = .source }
                )
            }
        }
    }

    private var contextSection: some View {
        editSection(title: AppStrings.newMomentStep2Title) {
            VStack(spacing: 0) {
                if viewModel.sourceSchema.supportsEpisodes {
                    episodeSelectionRow

                    if !viewModel.contextFields.isEmpty {
                        editDivider
                    }
                }

                ForEach(Array(viewModel.contextFields.enumerated()), id: \.element.id) { index, field in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(field.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)

                        if field.inputKind == .timestamp {
                            Button {
                                activeSheet = .timestamp(field.key)
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
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else if field.inputKind == .choice {
                            Menu {
                                ForEach(field.options) { option in
                                    Button(option.label) {
                                        viewModel.updateContextValue(
                                            field: field,
                                            value: option.id
                                        )
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
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        } else {
                            HStack {
                                TextField(
                                    field.placeholder,
                                    text: Binding(
                                        get: { viewModel.value(for: field.key) },
                                        set: { viewModel.updateContextValue(field: field, value: $0) }
                                    )
                                )
                                .keyboardType(
                                    keyboardType(for: field.inputKind)
                                )
                                .focused($focusedField, equals: field.key)

                                if let unit = field.unit {
                                    Text(unit)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }

                        if let schemaField = viewModel.sourceSchema.momentLocationFields.first(
                            where: { $0.key == field.key }
                        ), !LocatorValuePolicy.isValid(
                            viewModel.value(for: field.key),
                            for: schemaField
                        ) {
                            Text(AppStrings.newEpisodeInvalidValue)
                                .font(.footnote)
                                .foregroundStyle(Color.red)
                        }
                    }
                    .padding(.vertical, 16)

                    if index < viewModel.contextFields.count - 1 {
                        editDivider
                    }
                }
            }
        }
    }

    private func keyboardType(for inputKind: LocatorInputKind) -> UIKeyboardType {
        switch inputKind {
        case .decimal: .decimalPad
        case .integer: .numberPad
        case .choice, .timestamp, .date: .default
        }
    }

    private var episodeSelectionRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(AppStrings.newMomentEpisodeSectionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Button {
                    activeSheet = .episode
                } label: {
                    Label(AppStrings.sourceDetailAddEpisode, systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .controlSize(.small)
                .accessibilityIdentifier("moment.edit.episode.add")
            }

            Menu {
                Button(AppStrings.newMomentEpisodeNone) {
                    viewModel.selectEpisode(id: nil)
                }
                ForEach(viewModel.episodes) { episode in
                    Button(
                        viewModel.sourceSchema.episodeDisplayName(
                            for: episode.locatorValues
                        )
                    ) {
                        viewModel.selectEpisode(id: episode.id)
                    }
                }
            } label: {
                HStack {
                    Text(
                        viewModel.draft.selectedEpisode?.displayName
                            ?? AppStrings.newMomentEpisodeNone
                    )
                    .foregroundStyle(
                        viewModel.draft.selectedEpisode == nil
                            ? Color.textSecondary
                            : Color.textPrimary
                    )
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.appPrimary)
                }
                .contentShape(Rectangle())
            }

            if let episodeErrorMessage = viewModel.episodeErrorMessage {
                Text(episodeErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.vertical, 16)
    }

    private var captureSection: some View {
        editSection(title: AppStrings.newMomentStep3Title) {
            VStack(spacing: 0) {
                editTextArea(
                    id: "moment-title",
                    title: AppStrings.momentTitleOptionalLabel,
                    placeholder: AppStrings.momentTitlePlaceholder,
                    text: Binding(
                        get: { viewModel.draft.momentTitle },
                        set: viewModel.updateMomentTitle
                    )
                )

                if MomentTitlePolicy.shouldShowCounter(for: viewModel.draft.momentTitle) {
                    Text("\(viewModel.draft.momentTitle.count) / \(MomentTitlePolicy.maximumLength)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                editDivider

                editTextArea(
                    id: "scene",
                    title: AppStrings.sceneNoteLabel,
                    placeholder: AppStrings.newMomentStep3SceneSummaryPlaceholder,
                    text: Binding(
                        get: { viewModel.draft.sceneSummary },
                        set: viewModel.updateScene
                    )
                )

                editDivider

                editTextArea(
                    id: "heart",
                    title: AppStrings.newMomentStep3HeartScreamLabel,
                    placeholder: AppStrings.newMomentStep3HeartScreamPlaceholder,
                    text: Binding(
                        get: { viewModel.draft.heartScream },
                        set: viewModel.updateHeart
                    )
                )

                if !viewModel.draft.hasRequiredHeartScream {
                    Text(AppStrings.newMomentRequiredHeartScream)
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
            }
        }
    }

    private var reactionSection: some View {
        editSection(title: AppStrings.newMomentStep4Title) {
            Button {
                viewModel.beginReactionEditing()
                activeSheet = .reaction
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.draft.selectedReactions.isEmpty {
                        Text(AppStrings.newMomentStep4AddReactions)
                            .foregroundStyle(Color.appPrimary)
                    } else {
                        MomentEditReactionFlowLayout(horizontalSpacing: 5, verticalSpacing: 5) {
                            ForEach(viewModel.draft.selectedReactions) { reaction in
                                Text(reaction.displayText)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(Color.white, in: Capsule())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func editSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .padding(.horizontal, 16)

            content()
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(cornerRadius: 28, fillOpacity: 0.52)
        }
    }

    private var editDivider: some View {
        Rectangle()
            .fill(Color.textSecondary.opacity(0.16))
            .frame(height: 1)
    }

    private func editSelectionRow(
        title: String,
        value: String,
        isPlaceholder: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                    Text(value)
                        .foregroundStyle(isPlaceholder ? Color.textSecondary : Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func editTextArea(
        id: String,
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 104)
                    .focused($focusedField, equals: id)
                    .accessibilityIdentifier("moment.edit.\(id)")
            }

            if id == "scene" {
                MomentSceneCharacterCounter(text: text.wrappedValue)
            } else if id == "heart", HeartScreamTextPolicy.shouldShowCounter(for: text.wrappedValue) {
                Text("\(text.wrappedValue.count) / \(HeartScreamTextPolicy.maximumLength)")
                    .font(.caption)
                    .foregroundStyle(
                        text.wrappedValue.count >= HeartScreamTextPolicy.warningThreshold
                            ? Color.orange
                            : Color.textSecondary
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 16)
    }

    private func requestClose() {
        focusedField = nil
        if viewModel.hasChanges {
            isDiscardConfirmationPresented = true
        } else {
            onClose()
        }
    }

    private func save() {
        focusedField = nil
        guard viewModel.canSave, !isSaving else { return }
        isSaving = true
        Task {
            let didSave = await onSave(viewModel.draft, viewModel.imageChangeSet)
            isSaving = false
            if didSave {
                onClose()
            } else {
                viewModel.showSaveError()
            }
        }
    }

}

private enum EditSheet: Identifiable {
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

struct PairEditPickerSheet: View {
    let options: [NewMomentSelectableOption]
    let selectedID: String?
    let onSelect: (String?) -> Void
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        onSelect(nil)
                    } label: {
                        HStack {
                            Text(AppStrings.newMomentStep1PairNoneOption)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            if selectedID == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                    }

                    ForEach(options) { option in
                        Button {
                            onSelect(option.id)
                        } label: {
                            HStack {
                                Text(option.title)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                if selectedID == option.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(AppStrings.newMomentStep1NewPair, action: onCreate)
                        .foregroundStyle(Color.appPrimary)
                        .accessibilityIdentifier("moment.edit.pair.new")
                }
            }
            .navigationTitle(AppStrings.newMomentStep1PairLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.newMomentStep1NewPairCancel, action: onCancel)
                }
            }
        }
    }
}

struct SourceEditPickerSheet: View {
    let options: [NewMomentSelectableOption]
    let selectedID: String?
    let onSelect: (String?) -> Void
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        onSelect(nil)
                    } label: {
                        HStack {
                            Text(AppStrings.newMomentStep2NoSource)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            if selectedID == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                    }

                    ForEach(options) { option in
                        Button {
                            onSelect(option.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(option.title)
                                        .foregroundStyle(Color.textPrimary)
                                    if let subtitle = option.subtitle, !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                }
                                Spacer()
                                if selectedID == option.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(AppStrings.newMomentStep1NewSource, action: onCreate)
                        .foregroundStyle(Color.appPrimary)
                        .accessibilityIdentifier("moment.edit.source.new")
                }
            }
            .navigationTitle(AppStrings.newMomentStep1SourceLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.newMomentStep1NewSourceCancel, action: onCancel)
                }
            }
        }
    }
}

struct ReactionEditPickerSheet: View {
    let selection: Set<String>
    let onToggle: (NewMomentDraft.SelectedReaction) -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReactionCatalog.sections) { section in
                    Section(section.title) {
                        ForEach(section.reactions) { reaction in
                            Button {
                                onToggle(reaction)
                            } label: {
                                HStack {
                                    Text(reaction.displayText)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    if selection.contains(reaction.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                }
                            }
                            .accessibilityAddTraits(selection.contains(reaction.id) ? .isSelected : [])
                        }
                    }
                }
            }
            .navigationTitle(AppStrings.newMomentReactionPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.newMomentReactionPickerCancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.newMomentReactionPickerSave, action: onSave)
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct TimestampEditSheet: View {
    let initialValue: (Int, Int, Int)
    let onCancel: () -> Void
    let onSave: (Int, Int, Int) -> Void

    @State private var hour: Int
    @State private var minute: Int
    @State private var second: Int

    init(
        initialValue: (Int, Int, Int),
        onCancel: @escaping () -> Void,
        onSave: @escaping (Int, Int, Int) -> Void
    ) {
        self.initialValue = initialValue
        self.onCancel = onCancel
        self.onSave = onSave
        _hour = State(initialValue: initialValue.0)
        _minute = State(initialValue: initialValue.1)
        _second = State(initialValue: initialValue.2)
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("hour", selection: $hour) {
                    ForEach(0..<100, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                Picker("minute", selection: $minute) {
                    ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                Picker("second", selection: $second) {
                    ForEach(0..<60, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .navigationTitle(AppStrings.newMomentStep2TimestampTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.newMomentStep2TimestampCancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.newMomentStep2TimestampDone) {
                        onSave(hour, minute, second)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct MomentEditReactionFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let rows = rows(maxWidth: proposal.width ?? 0, subviews: subviews)
        return CGSize(
            width: proposal.width ?? 0,
            height: rows.last.map { $0.y + $0.height } ?? 0
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for row in rows(maxWidth: bounds.width, subviews: subviews) {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [MomentEditReactionRow] {
        guard maxWidth > 0 else { return [] }
        var rows: [MomentEditReactionRow] = []
        var items: [MomentEditReactionItem] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextX = items.isEmpty ? 0 : x + horizontalSpacing
            if nextX + size.width > maxWidth, !items.isEmpty {
                rows.append(.init(y: y, height: rowHeight, items: items))
                y += rowHeight + verticalSpacing
                items = []
                x = 0
                rowHeight = 0
            }

            let itemX = items.isEmpty ? 0 : x + horizontalSpacing
            items.append(.init(index: index, x: itemX, size: size))
            x = itemX + size.width
            rowHeight = max(rowHeight, size.height)
        }

        if !items.isEmpty {
            rows.append(.init(y: y, height: rowHeight, items: items))
        }
        return rows
    }
}

private struct MomentEditReactionRow {
    let y: CGFloat
    let height: CGFloat
    let items: [MomentEditReactionItem]
}

private struct MomentEditReactionItem {
    let index: Int
    let x: CGFloat
    let size: CGSize
}
