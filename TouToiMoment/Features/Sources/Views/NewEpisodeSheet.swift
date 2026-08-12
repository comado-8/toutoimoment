import SwiftUI

struct NewEpisodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NewEpisodeSheetViewModel
    @FocusState private var focusedFieldKey: String?

    let schema: SourceLocatorSchema
    private let isEditing: Bool
    private let onCreated: (EpisodeSummary) -> Void

    init(
        schema: SourceLocatorSchema,
        episode: EpisodeSummary? = nil,
        saveAction: @escaping NewEpisodeSheetViewModel.SaveAction,
        onCreated: @escaping (EpisodeSummary) -> Void = { _ in }
    ) {
        self.schema = schema
        self.isEditing = episode != nil
        _viewModel = StateObject(
            wrappedValue: NewEpisodeSheetViewModel(
                schema: schema,
                episode: episode,
                saveAction: saveAction
            )
        )
        self.onCreated = onCreated
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    displayTitleSection

                    ForEach(schema.episodeFields) { field in
                        inputSection(field)
                    }

                    relatedURLSection

                    Text(AppStrings.newEpisodeRequirement)
                        .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.textSecondary)

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                            .foregroundStyle(Color.red)
                            .accessibilityIdentifier("new_episode.error")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.fraction(0.72), .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isSaving)
        .accessibilityAddTraits(.isModal)
    }

    private var displayTitleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(AppStrings.episodeDisplayTitleLabel)
            TextField(
                "",
                text: $viewModel.draft.displayTitle,
                prompt: Text(AppStrings.episodeDisplayTitlePlaceholder)
                    .foregroundStyle(Color(hex: "#9B9EC4"))
            )
            .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(inputBackground)
            .accessibilityIdentifier("new_episode.display_title")
            .onChange(of: viewModel.draft.displayTitle) { _, value in
                let limited = EpisodeDisplayTitlePolicy.limited(value)
                if limited != value { viewModel.draft.displayTitle = limited }
            }
        }
    }

    private var header: some View {
        ZStack {
            Text(isEditing ? AppStrings.editEpisodeTitle : AppStrings.newEpisodeTitle)
                .font(.custom("Geist-SemiBold", size: 20, relativeTo: .title3))

            HStack {
                Button(AppStrings.newMomentStep1NewSourceCancel) {
                    focusedFieldKey = nil
                    dismiss()
                }
                .foregroundStyle(Color(hex: "#6B7280"))
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("new_episode.cancel")

                Spacer()

                Button {
                    focusedFieldKey = nil
                    Task {
                        guard let episode = await viewModel.save() else { return }
                        onCreated(episode)
                        dismiss()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(AppStrings.newMomentStep1NewSourceSave)
                            .font(.custom("Geist-SemiBold", size: 17, relativeTo: .headline))
                    }
                }
                .disabled(!viewModel.canSave)
                .foregroundStyle(
                    viewModel.canSave ? Color.appPrimary : Color.appPrimary.opacity(0.35)
                )
                .accessibilityIdentifier("new_episode.save")
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 64)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func inputSection(_ field: LocatorField) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(field.label)

            switch field.inputKind {
            case .choice:
                Picker(
                    field.label,
                    selection: valueBinding(for: field)
                ) {
                    ForEach(field.options) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("new_episode.\(field.key)")

            case .date:
                optionalDateField(field)

            case .integer, .decimal:
                HStack {
                    TextField(
                        "",
                        text: valueBinding(for: field),
                        prompt: Text(field.placeholder).foregroundStyle(Color(hex: "#9B9EC4"))
                    )
                    .keyboardType(field.inputKind == .integer ? .numberPad : .decimalPad)
                    .focused($focusedFieldKey, equals: field.key)

                    if let unit = field.unit {
                        Text(unit)
                            .font(.custom("Geist-SemiBold", size: 13, relativeTo: .footnote))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(inputBackground)
                .accessibilityIdentifier("new_episode.\(field.key)")

                let value = viewModel.draft.value(for: field.key)
                if !value.isEmpty, !LocatorValuePolicy.isValid(value, for: field) {
                    Text(AppStrings.newEpisodeInvalidValue)
                        .font(.caption)
                        .foregroundStyle(Color.red)
                }

            case .timestamp:
                EmptyView()
            }
        }
    }

    private func optionalDateField(_ field: LocatorField) -> some View {
        let value = viewModel.draft.value(for: field.key)
        return VStack(alignment: .leading, spacing: 8) {
            Toggle(
                AppStrings.newEpisodeUseDate,
                isOn: Binding(
                    get: { !value.isEmpty },
                    set: { isEnabled in
                        viewModel.updateValue(
                            isEnabled ? Self.isoDateFormatter.string(from: Date()) : "",
                            for: field
                        )
                    }
                )
            )
            .tint(Color.appPrimary)

            if !value.isEmpty {
                DatePicker(
                    field.label,
                    selection: Binding(
                        get: { Self.isoDateFormatter.date(from: value) ?? Date() },
                        set: { viewModel.updateValue(Self.isoDateFormatter.string(from: $0), for: field) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
        }
        .accessibilityIdentifier("new_episode.\(field.key)")
    }

    private var relatedURLSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel(AppStrings.episodeRelatedURLLabel)

            TextField(
                "",
                text: $viewModel.draft.relatedURLText,
                prompt: Text(AppStrings.episodeRelatedURLPlaceholder)
                    .foregroundStyle(Color(hex: "#9B9EC4"))
            )
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(inputBackground)
            .accessibilityIdentifier("new_episode.related_url")
            .onChange(of: viewModel.draft.relatedURLText) { _, value in
                let limited = RelatedURLInputPolicy.limited(value)
                if limited != value { viewModel.draft.relatedURLText = limited }
            }

            if !viewModel.draft.isRelatedURLValid {
                Text(AppStrings.sourceRelatedURLError)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
    }

    private func valueBinding(for field: LocatorField) -> Binding<String> {
        Binding(
            get: { viewModel.draft.value(for: field.key) },
            set: { viewModel.updateValue($0, for: field) }
        )
    }

    private func fieldLabel(_ value: String) -> some View {
        Text(value.uppercased())
            .font(.custom("Geist-SemiBold", size: 12, relativeTo: .caption))
            .foregroundStyle(Color(hex: "#6B7280"))
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.systemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
            }
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
