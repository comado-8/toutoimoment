import SwiftUI

struct NewSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NewSourceSheetViewModel
    @FocusState private var focusedField: Field?

    private let onCreated: (SourceSummary) -> Void
    private let isEditing: Bool

    private enum Field {
        case name
        case customPlatform
        case relatedURL
    }

    init(
        saveAction: @escaping NewSourceSheetViewModel.SaveAction,
        onCreated: @escaping (SourceSummary) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: NewSourceSheetViewModel(saveAction: saveAction)
        )
        self.onCreated = onCreated
        self.isEditing = false
    }

    init(
        source: SourceSummary,
        updateAction: @escaping @MainActor (SourceUpdateRequest) async throws -> SourceSummary,
        onUpdated: @escaping (SourceSummary) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: NewSourceSheetViewModel(
                draft: NewSourceDraft(source: source),
                saveAction: { request in
                    try await updateAction(
                        SourceUpdateRequest(
                            displayName: request.displayName,
                            streamingPlatform: request.streamingPlatform,
                            relatedURL: request.relatedURL
                        )
                    )
                }
            )
        )
        self.onCreated = onUpdated
        self.isEditing = true
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 28) {
                    nameSection
                    mediumSection
                    if viewModel.draft.mediaType == "streaming" {
                        streamingPlatformSection
                    }
                    relatedURLSection

                    if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.fraction(0.82), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemBackground))
        .interactiveDismissDisabled(viewModel.isSaving)
        .accessibilityAddTraits(.isModal)
    }

    private var header: some View {
        ZStack {
            Text(isEditing ? AppStrings.editSourceTitle : AppStrings.newMomentStep1NewSourceSheetTitle)
                .font(.custom("Geist-SemiBold", size: 20, relativeTo: .title3))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Button {
                    focusedField = nil
                    dismiss()
                } label: {
                    Text(AppStrings.newMomentStep1NewSourceCancel)
                        .font(.custom("Geist-Regular", size: 17, relativeTo: .body))
                        .foregroundStyle(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("new_source.cancel")

                Spacer()

                Button {
                    focusedField = nil
                    Task {
                        guard let source = await viewModel.save() else { return }
                        onCreated(source)
                        dismiss()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.appPrimary)
                    } else {
                        Text(AppStrings.newMomentStep1NewSourceSave)
                            .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                            .foregroundStyle(
                                viewModel.canSave
                                    ? Color.appPrimary
                                    : Color.appPrimary.opacity(0.35)
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSave)
                .accessibilityIdentifier("new_source.save")
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 64)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: "#E5E7EB"))
                .frame(height: 1)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.newMomentStep1NewSourceNameLabel)

            TextField(
                "",
                text: $viewModel.draft.displayName,
                prompt: Text(selectedSchema.sourceNameExample)
                    .foregroundStyle(Color(hex: "#9B9EC4"))
            )
            .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
            .foregroundStyle(Color.textPrimary)
            .textInputAutocapitalization(.words)
            .submitLabel(.next)
            .focused($focusedField, equals: .name)
            .onSubmit {
                focusedField = .relatedURL
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(inputBackground)
            .accessibilityLabel(AppStrings.newMomentStep1NewSourceNameLabel)
            .accessibilityIdentifier("new_source.name")
            .onChange(of: viewModel.draft.displayName) { _, value in
                let limited = SourceNamePolicy.limited(value)
                if limited != value { viewModel.draft.displayName = limited }
            }

            Text(selectedSchema.sourceNameExample)
                .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var mediumSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.newMomentStep1NewSourceMediumLabel)

            if isEditing {
                chip(title: selectedSchema.mediaLabelJa, isSelected: true) {}
                    .disabled(true)
                    .accessibilityIdentifier("new_source.medium.read_only")
            } else {
                NewSourceChipFlowLayout(spacing: 8) {
                    ForEach(SourceLocatorSchema.all) { schema in
                        chip(
                            title: schema.mediaLabelJa,
                            isSelected: viewModel.draft.mediaType == schema.mediaType
                        ) {
                            focusedField = nil
                            viewModel.draft.mediaType = schema.mediaType
                        }
                        .accessibilityLabel(schema.mediaLabelJa)
                        .accessibilityIdentifier("new_source.medium.\(schema.mediaType)")
                    }
                }
            }
        }
    }

    private var selectedSchema: SourceLocatorSchema {
        SourceLocatorSchema.schema(for: viewModel.draft.mediaType) ?? .fallback
    }

    private var streamingPlatformSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.streamingPlatformLabel)

            NewSourceChipFlowLayout(spacing: 8) {
                ForEach(StreamingPlatformID.allCases) { platformID in
                    chip(
                        title: platformID.displayName,
                        isSelected: viewModel.draft.streamingPlatformID == platformID
                    ) {
                        focusedField = nil
                        viewModel.draft.streamingPlatformID = platformID
                        if platformID == .other {
                            focusedField = .customPlatform
                        }
                    }
                    .accessibilityLabel(platformID.displayName)
                    .accessibilityIdentifier("new_source.streaming_platform.\(platformID.rawValue)")
                }
            }

            if viewModel.draft.streamingPlatformID == .other {
                TextField(
                    "",
                    text: $viewModel.draft.customStreamingPlatformName,
                    prompt: Text(AppStrings.streamingPlatformOtherPlaceholder)
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                )
                .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .customPlatform)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(inputBackground)
                .accessibilityLabel(AppStrings.streamingPlatformOtherLabel)
                .accessibilityIdentifier("new_source.streaming_platform.other_name")
                .onChange(of: viewModel.draft.customStreamingPlatformName) { _, value in
                    let limited = StreamingPlatformNamePolicy.limited(value)
                    if limited != value {
                        viewModel.draft.customStreamingPlatformName = limited
                    }
                }

                if viewModel.draft.customStreamingPlatformName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                {
                    Text(AppStrings.streamingPlatformOtherError)
                        .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.red)
                        .accessibilityIdentifier("new_source.streaming_platform.other_error")
                }
            }
        }
    }

    private var relatedURLSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.sourceRelatedURLLabel)

            TextField(
                "",
                text: $viewModel.draft.relatedURLText,
                prompt: Text(AppStrings.sourceRelatedURLPlaceholder)
                    .foregroundStyle(Color(hex: "#9B9EC4"))
            )
            .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
            .foregroundStyle(Color.textPrimary)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .relatedURL)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(inputBackground)
            .accessibilityLabel(AppStrings.sourceRelatedURLLabel)
            .accessibilityIdentifier("new_source.related_url")
            .onChange(of: viewModel.draft.relatedURLText) { _, value in
                let limited = RelatedURLInputPolicy.limited(value)
                if limited != value { viewModel.draft.relatedURLText = limited }
            }

            if !viewModel.draft.relatedURLText.isEmpty, !viewModel.draft.isURLValid {
                Text(AppStrings.sourceRelatedURLError)
                    .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.red)
                    .accessibilityIdentifier("new_source.related_url_error")
            }
        }
    }

    private func errorView(message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.red)

            Text(message)
                .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("new_source.error")
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
            .foregroundStyle(Color(hex: "#6B7280"))
    }

    private func chip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom(
                    isSelected ? "Geist-SemiBold" : "Geist-Medium",
                    size: 13,
                    relativeTo: .footnote
                ))
                .foregroundStyle(isSelected ? Color.white : Color(hex: "#6B7280"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.appPrimary : Color(.systemBackground))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    isSelected ? Color.appPrimary : Color(hex: "#E5E7EB"),
                                    lineWidth: 1
                                )
                        }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
            }
    }
}

private struct NewSourceChipFlowLayout: Layout {
    let spacing: CGFloat

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

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        guard maxWidth > 0 else { return [] }

        var rows: [Row] = []
        var current = Row(y: 0)

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextX = current.items.last.map { $0.x + $0.size.width + spacing } ?? 0

            if !current.items.isEmpty, nextX + size.width > maxWidth {
                rows.append(current)
                current = Row(y: current.y + current.height + spacing)
            }

            let x = current.items.last.map { $0.x + $0.size.width + spacing } ?? 0
            current.items.append(Item(index: index, x: x, size: size))
            current.height = max(current.height, size.height)
        }

        if !current.items.isEmpty {
            rows.append(current)
        }
        return rows
    }

    private struct Item {
        let index: Int
        let x: CGFloat
        let size: CGSize
    }

    private struct Row {
        let y: CGFloat
        var height: CGFloat = 0
        var items: [Item] = []
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NewSourceSheet(
                saveAction: { request in
                    SourceSummary(
                        id: UUID().uuidString,
                        displayName: request.displayName,
                        helperText: request.helperText,
                        mediaType: request.mediaType,
                        streamingPlatform: request.streamingPlatform,
                        relatedURL: request.relatedURL
                    )
                }
            )
        }
}
