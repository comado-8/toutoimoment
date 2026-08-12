import SwiftUI

struct PairEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PairEditorViewModel
    @FocusState private var focusedField: Field?

    private let isEditing: Bool
    private let onSaved: (PairSummary) -> Void

    private enum Field {
        case member1
        case member2
        case nickname
    }

    init(
        createAction: @escaping @MainActor (PairCreateRequest) async throws -> PairSummary,
        onCreated: @escaping (PairSummary) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: PairEditorViewModel { draft in
                guard let request = draft.makeCreateRequest() else {
                    throw PairRepositoryError.invalidPair
                }
                return try await createAction(request)
            }
        )
        isEditing = false
        onSaved = onCreated
    }

    init(
        pair: PairSummary,
        updateAction: @escaping @MainActor (PairUpdateRequest) async throws -> PairSummary,
        onUpdated: @escaping (PairSummary) -> Void = { _ in }
    ) {
        _viewModel = StateObject(
            wrappedValue: PairEditorViewModel(draft: PairEditorDraft(pair: pair)) { draft in
                guard let request = draft.makeUpdateRequest() else {
                    throw PairRepositoryError.invalidPair
                }
                return try await updateAction(request)
            }
        )
        isEditing = true
        onSaved = onUpdated
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 28) {
                    identitySection
                    colorSection
                    previewSection

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
            Text(isEditing ? AppStrings.pairEditorEditTitle : AppStrings.newMomentStep1NewPairSheetTitle)
                .font(.custom("Geist-SemiBold", size: 20, relativeTo: .title3))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Button {
                    focusedField = nil
                    dismiss()
                } label: {
                    Text(AppStrings.newMomentStep1NewPairCancel)
                        .font(.custom("Geist-Regular", size: 17, relativeTo: .body))
                        .foregroundStyle(Color(hex: "#6B7280"))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("pair_editor.cancel")

                Spacer()

                Button {
                    focusedField = nil
                    Task {
                        guard let pair = await viewModel.save() else { return }
                        onSaved(pair)
                        dismiss()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.appPrimary)
                    } else {
                        Text(AppStrings.newMomentStep1NewPairSave)
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
                .accessibilityIdentifier("pair_editor.save")
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

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(AppStrings.newMomentStep1NewPairMember1Label)

                TextField(
                    "",
                    text: $viewModel.draft.member1Name,
                    prompt: Text(AppStrings.newMomentStep1NewPairMember1Placeholder)
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                )
                .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($focusedField, equals: .member1)
                .onSubmit { focusedField = .member2 }
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(inputBackground)
                .accessibilityIdentifier("pair_editor.member1")
                .onChange(of: viewModel.draft.member1Name) { _, value in
                    let limited = PairTextPolicy.limitedMember(value)
                    if limited != value { viewModel.draft.member1Name = limited }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(AppStrings.newMomentStep1NewPairMember2Label)

                TextField(
                    "",
                    text: $viewModel.draft.member2Name,
                    prompt: Text(AppStrings.newMomentStep1NewPairMember2Placeholder)
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                )
                .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($focusedField, equals: .member2)
                .onSubmit { focusedField = .nickname }
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(inputBackground)
                .accessibilityIdentifier("pair_editor.member2")
                .onChange(of: viewModel.draft.member2Name) { _, value in
                    let limited = PairTextPolicy.limitedMember(value)
                    if limited != value { viewModel.draft.member2Name = limited }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel(AppStrings.pairEditorNicknameOptional)

                TextField(
                    "",
                    text: $viewModel.draft.nickname,
                    prompt: Text(AppStrings.newMomentStep1NewPairNicknamePlaceholder)
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                )
                .font(.custom("Geist-Regular", size: 16, relativeTo: .body))
                .foregroundStyle(Color.textPrimary)
                .submitLabel(.done)
                .focused($focusedField, equals: .nickname)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
                .background(inputBackground)
                .accessibilityIdentifier("pair_editor.nickname")
                .onChange(of: viewModel.draft.nickname) { _, value in
                    let limited = PairTextPolicy.limitedMember(value)
                    if limited != value { viewModel.draft.nickname = limited }
                }

                Text(AppStrings.pairEditorDisplayNameHelp)
                    .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel(AppStrings.newMomentStep1NewPairColorLabel)

            colorPalette(
                title: AppStrings.pairEditorFirstColor,
                selection: $viewModel.draft.leadingColorHex,
                identifierPrefix: "pair_editor.color.primary"
            )

            colorPalette(
                title: AppStrings.pairEditorSecondaryColor,
                selection: $viewModel.draft.trailingColorHex,
                identifierPrefix: "pair_editor.color.secondary",
                enabled: $viewModel.draft.usesTrailingColor
            )
        }
        .animation(.easeOut(duration: 0.18), value: viewModel.draft.usesTrailingColor)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(AppStrings.newMomentStep1NewPairPreviewLabel)

            HStack(spacing: 14) {
                VStack(spacing: 7) {
                    Circle()
                        .fill(Color(hex: viewModel.draft.leadingColorHex))
                        .frame(width: 11, height: 11)
                        .overlay {
                            Circle().stroke(Color.black.opacity(0.16), lineWidth: 0.75)
                        }

                    if viewModel.draft.usesTrailingColor {
                        Circle()
                            .fill(Color(hex: viewModel.draft.trailingColorHex))
                            .frame(width: 11, height: 11)
                            .overlay {
                                Circle().stroke(Color.black.opacity(0.16), lineWidth: 0.75)
                            }
                    }
                }
                .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        viewModel.draft.displayName.isEmpty
                            ? AppStrings.pairEditorPreviewPlaceholder
                            : viewModel.draft.displayName
                    )
                    .font(.custom("Geist-Bold", size: 17, relativeTo: .headline))
                    .foregroundStyle(
                        viewModel.draft.displayName.isEmpty
                            ? Color.textMuted
                            : Color.textPrimary
                    )
                    .lineLimit(1)

                    if !viewModel.draft.normalizedNickname.isEmpty,
                       !viewModel.draft.memberDisplayName.isEmpty {
                        Text(viewModel.draft.memberDisplayName)
                            .font(.custom("Geist-Regular", size: 13, relativeTo: .footnote))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                FavoriteHeartIcon(isFilled: false)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 92)
            .glassCard(cornerRadius: 20, fillOpacity: 0.58)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("pair_editor.preview")
        }
    }

    private func colorPalette(
        title: String,
        selection: Binding<String>,
        identifierPrefix: String,
        enabled: Binding<Bool>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.custom("Geist-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.textSecondary)

                Spacer(minLength: 0)

                if let enabled {
                    Toggle("", isOn: enabled)
                        .labelsHidden()
                        .tint(Color.appPrimary)
                        .accessibilityLabel(AppStrings.pairEditorSecondColor)
                        .accessibilityIdentifier("pair_editor.color.secondary_enabled")
                }
            }

            if enabled?.wrappedValue != false {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                    spacing: 10
                ) {
                    ForEach(PairColorChoice.palette) { choice in
                        Button {
                            selection.wrappedValue = choice.hex
                        } label: {
                            Circle()
                                .fill(Color(hex: choice.hex))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            choice.hex == "#FFFFFF"
                                                ? Color(hex: "#C7CAD1")
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                }
                                .padding(4)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            selection.wrappedValue == choice.hex
                                                ? Color.appPrimary
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                }
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(choice.hex)
                        .accessibilityAddTraits(
                            selection.wrappedValue == choice.hex ? .isSelected : []
                        )
                        .accessibilityIdentifier("\(identifierPrefix).\(choice.hex)")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
        .accessibilityIdentifier("pair_editor.error")
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
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
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PairEditorSheet(createAction: { request in
                PairSummary(
                    id: UUID().uuidString,
                    member1Name: request.member1Name,
                    member2Name: request.member2Name,
                    nickname: request.nickname,
                    momentCount: 0,
                    leadingColorHex: request.leadingColorHex,
                    trailingColorHex: request.trailingColorHex,
                    isFavorite: false
                )
            })
        }
}
