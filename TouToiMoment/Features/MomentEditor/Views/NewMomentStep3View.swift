import SwiftUI

struct NewMomentStep3View: View {
    @ObservedObject private var viewModel: NewMomentStep3ViewModel
    @FocusState private var focusedFieldID: String?
    @State private var keyboardHeight: CGFloat = 0

    let onContinue: (NewMomentDraft) -> Void
    let onCancel: () -> Void
    let onBackToStep1: () -> Void
    let onBackToStep2: (NewMomentDraft) -> Void

    init(
        viewModel: NewMomentStep3ViewModel,
        onContinue: @escaping (NewMomentDraft) -> Void = { _ in },
        onCancel: @escaping () -> Void = {},
        onBackToStep1: @escaping () -> Void = {},
        onBackToStep2: @escaping (NewMomentDraft) -> Void = { _ in }
    ) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.onContinue = onContinue
        self.onCancel = onCancel
        self.onBackToStep1 = onBackToStep1
        self.onBackToStep2 = onBackToStep2
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                NewMomentFlowHeader(onDismiss: onCancel)

                NewMomentProgressDots(
                    activeCount: 3,
                    accessibilityLabel: AppStrings.newMomentStep3Progress
                )
                .padding(.top, 13)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 9) {
                        NewMomentCompletedSummary(
                            title: AppStrings.newMomentStep2ChooseCompletedTitle,
                            summary: viewModel.chooseSummary,
                            onTap: onBackToStep1
                        )
                        NewMomentFlowSeparator()
                        NewMomentCompletedSummary(
                            title: AppStrings.newMomentStep4ContextCompletedTitle,
                            summary: viewModel.contextSummary,
                            onTap: { onBackToStep2(viewModel.draft) }
                        )
                        NewMomentFlowSeparator()
                        captureSection
                        NewMomentFlowSeparator()
                        NewMomentInactiveSummaryRow(title: AppStrings.newMomentStep4Title)
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 96)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(alignment: .bottom) {
            if shouldShowNextButton {
                nextButtonContainer
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .offset(y: keyboardHeight)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(keyboardToolbarTitle) {
                    focusedFieldID = focusedFieldID == "sceneSummary" ? "heartScream" : nil
                }
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .animation(.easeOut(duration: 0.24), value: keyboardHeight)
        .animation(.easeOut(duration: 0.18), value: shouldShowNextButton)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(notification: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    private var captureSection: some View {
        HStack(alignment: .top, spacing: 8) {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimarySoft.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 3)
            .frame(maxHeight: .infinity)
            .clipShape(Capsule(style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(AppStrings.newMomentStep3Title)
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(Color.appPrimary)

                captureTextField(
                    id: "sceneSummary",
                    title: AppStrings.newMomentStep3SceneSummaryLabel,
                    placeholder: AppStrings.newMomentStep3SceneSummaryPlaceholder,
                    height: 96,
                    value: Binding(
                        get: { viewModel.draft.sceneSummary },
                        set: { viewModel.updateSceneSummary($0) }
                    )
                )

                captureTextField(
                    id: "heartScream",
                    title: AppStrings.newMomentStep3HeartScreamLabel,
                    placeholder: AppStrings.newMomentStep3HeartScreamPlaceholder,
                    height: 140,
                    value: Binding(
                        get: { viewModel.draft.heartScream },
                        set: { viewModel.updateHeartScream($0) }
                    )
                )
            }
        }
        .frame(width: 342, alignment: .leading)
    }

    private func captureTextField(
        id: String,
        title: String,
        placeholder: String,
        height: CGFloat,
        value: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color(hex: "#4A4A68"))

            ZStack(alignment: .topLeading) {
                if value.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(hex: "#9B9EC4"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .allowsHitTesting(false)
                }

                TextEditor(text: value)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($focusedFieldID, equals: id)
                    .submitLabel(id == "sceneSummary" ? .next : .done)
            }
            .frame(height: height)
            .background(NewMomentGlassFieldBackground())

            if id == "sceneSummary" {
                MomentSceneCharacterCounter(text: value.wrappedValue)
            }
        }
    }

    private var nextButtonContainer: some View {
        VStack(spacing: 0) {
            Button(action: { onContinue(viewModel.draft) }) {
                Text(AppStrings.newMomentStep3Next)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule(style: .continuous)
                            .fill(viewModel.canContinue ? Color.appPrimary : Color.appPrimary.opacity(0.26))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canContinue)
            .accessibilityHint(viewModel.canContinue ? "" : AppStrings.newMomentStep3NextDisabledHint)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.clear)
    }

    private var keyboardToolbarTitle: String {
        focusedFieldID == "sceneSummary"
            ? AppStrings.newMomentStep2KeyboardNext
            : AppStrings.newMomentStep2KeyboardDone
    }

    private var shouldShowNextButton: Bool {
        focusedFieldID == nil && keyboardHeight == 0
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
}

#Preview {
    NewMomentStep3View(
        viewModel: NewMomentStep3ViewModel(
            draft: NewMomentDraft(
                selectedPair: .init(
                    id: "pair",
                    displayName: "Member 1 ・ Member 2",
                    nickname: ""
                ),
                selectedSource: .init(
                    id: "source",
                    displayName: "テスト用ソース",
                    helperText: "アニメ",
                    mediaType: "anime",
                    totalCount: nil,
                    isFavorite: false
                )
            )
        )
    )
}
