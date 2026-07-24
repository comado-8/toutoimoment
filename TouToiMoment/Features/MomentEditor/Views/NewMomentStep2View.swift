import SwiftUI

struct NewMomentStep2View: View {
    @StateObject private var viewModel: NewMomentStep2ViewModel
    @FocusState private var focusedFieldID: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var isTimestampPickerPresented = false
    @State private var timestampHour = 0
    @State private var timestampMinute = 0
    @State private var timestampSecond = 0
    @State private var activeTimestampFieldKey: String?

    let onContinue: (NewMomentDraft) -> Void
    let onCancel: () -> Void
    let onBackToStep1: () -> Void

    init(
        viewModel: NewMomentStep2ViewModel,
        onContinue: @escaping (NewMomentDraft) -> Void = { _ in },
        onCancel: @escaping () -> Void = {},
        onBackToStep1: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
        self.onCancel = onCancel
        self.onBackToStep1 = onBackToStep1
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
                    VStack(spacing: 9) {
                        completedChooseSection
                        separator
                        contextSection
                        separator
                        summaryRow(title: AppStrings.newMomentStep3Title)
                        separator
                        summaryRow(title: AppStrings.newMomentStep4Title)
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 96)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .accessibilityHidden(isTimestampPickerPresented)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(alignment: .bottom) {
            if shouldShowNextButton {
                nextButtonContainer
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .offset(y: keyboardHeight)
                    .accessibilityHidden(isTimestampPickerPresented)
            }
        }
        .overlay {
            if isTimestampPickerPresented {
                timestampPickerOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(keyboardToolbarTitle) {
                    focusedFieldID = focusedFieldID.flatMap { nextFieldID(after: $0) }
                }
                .font(.system(size: 15, weight: .semibold))
            }
        }
        .animation(.easeOut(duration: 0.24), value: keyboardHeight)
        .animation(.easeOut(duration: 0.24), value: isTimestampPickerPresented)
        .animation(.easeOut(duration: 0.18), value: shouldShowNextButton)
        .onTapGesture {
            focusedFieldID = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(notification: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
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
                    .fill(index < 2 ? Color.appPrimary : Color(hex: "#D7D4EA"))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppStrings.newMomentStep2Progress)
    }

    private var completedChooseSection: some View {
        NewMomentCompletedSummary(
            title: AppStrings.newMomentStep2ChooseCompletedTitle,
            summary: viewModel.chooseSummary,
            onTap: onBackToStep1
        )
    }

    private var contextSection: some View {
        HStack(alignment: .top, spacing: 8) {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimarySoft.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 3)
            .frame(maxHeight: .infinity)
            .clipShape(Capsule(style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(AppStrings.newMomentStep2Title)
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(Color.appPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.contextFieldRows, id: \.self) { row in
                        HStack(alignment: .top, spacing: 8) {
                            ForEach(row) { field in
                                contextInputField(
                                    field: field,
                                    value: Binding(
                                        get: { viewModel.value(for: field.key) },
                                        set: { viewModel.updateValue(for: field, value: $0) }
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 342, alignment: .leading)
    }

    private func contextInputField(
        field: NewMomentStep2ContextField,
        value: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color(hex: "#4A4A68"))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if field.inputKind == .timestamp {
                Button(action: { presentTimestampPicker(for: field.key) }) {
                    HStack {
                        Text(value.wrappedValue.isEmpty ? field.placeholder : value.wrappedValue)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(value.wrappedValue.isEmpty ? Color(hex: "#9B9EC4") : Color.textPrimary)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "#747391"))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(fieldBackground)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 6) {
                    TextField("", text: value, prompt: Text(field.placeholder).foregroundStyle(Color(hex: "#9B9EC4")))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.textPrimary)
                        .keyboardType(keyboardType(for: field.inputKind))
                        .textInputAutocapitalization(.never)
                        .submitLabel(submitLabel(for: field.id))
                        .focused($focusedFieldID, equals: field.id)
                        .onSubmit {
                            focusedFieldID = nextFieldID(after: field.id)
                        }

                    if let unit = field.unit {
                        Text(unit)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "#747391"))
                            .fixedSize()
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(fieldBackground)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var timestampPickerOverlay: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissTimestampPicker()
                    }

                VStack(spacing: 0) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: "#C9CBD3", opacity: 0.75))
                        .frame(width: 42, height: 5)
                        .padding(.top, 10)

                    HStack {
                        Button(AppStrings.newMomentStep2TimestampCancel, action: dismissTimestampPicker)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color(hex: "#6E7482"))

                        Spacer()

                        Text(AppStrings.newMomentStep2TimestampTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        Button(AppStrings.newMomentStep2TimestampDone, action: commitTimestampPicker)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 18)

                    Rectangle()
                        .fill(Color(hex: "#D8D4E8", opacity: 0.55))
                        .frame(height: 1)

                    HStack(spacing: 0) {
                        timestampWheel(selection: $timestampHour, range: 0...99, label: "HH")
                        timestampWheel(selection: $timestampMinute, range: 0...59, label: "MM")
                        timestampWheel(selection: $timestampSecond, range: 0...59, label: "SS")
                    }
                    .frame(height: 204)
                    .padding(.horizontal, 18)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 0))
                }
                .frame(maxWidth: .infinity)
                .background(timestampSheetBackground)
                .clipShape(timestampSheetShape)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .accessibilityAddTraits(.isModal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func timestampWheel(
        selection: Binding<Int>,
        range: ClosedRange<Int>,
        label: String
    ) -> some View {
        VStack(spacing: 0) {
            Picker(label, selection: selection) {
                ForEach(Array(range), id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(size: 22, weight: .semibold))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .clipped()

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color(hex: "#8E91B0"))
                .padding(.top, -8)
        }
        .frame(maxWidth: .infinity)
    }

    private var nextButtonContainer: some View {
        VStack(spacing: 0) {
            Button(action: { onContinue(viewModel.draft) }) {
                Text(AppStrings.newMomentStep2Next)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.appPrimary)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.clear)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.80))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "#D6D1F2", opacity: 0.28), lineWidth: 1)
            }
            .shadow(color: Color(hex: "#6652CC", opacity: 0.06), radius: 4, x: 0, y: 1)
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(hex: "#C4BCE4", opacity: 0.35))
            .frame(width: 342, height: 1)
    }

    private func summaryRow(title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Color(hex: "#9B9EC4"))
            .frame(width: 342, alignment: .leading)
            .frame(height: 22, alignment: .topLeading)
    }

    private var orderedFieldIDs: [String] {
        viewModel.orderedTextFieldIDs
    }

    private var shouldShowNextButton: Bool {
        focusedFieldID == nil && keyboardHeight == 0
    }

    private func nextFieldID(after id: String) -> String? {
        guard let index = orderedFieldIDs.firstIndex(of: id) else {
            return nil
        }

        let nextIndex = orderedFieldIDs.index(after: index)
        guard nextIndex < orderedFieldIDs.endIndex else {
            return nil
        }

        return orderedFieldIDs[nextIndex]
    }

    private func submitLabel(for id: String) -> SubmitLabel {
        nextFieldID(after: id) == nil ? .done : .next
    }

    private var keyboardToolbarTitle: String {
        guard
            let focusedFieldID,
            nextFieldID(after: focusedFieldID) != nil
        else {
            return AppStrings.newMomentStep2KeyboardDone
        }

        return AppStrings.newMomentStep2KeyboardNext
    }

    private func keyboardType(for inputKind: LocatorInputKind) -> UIKeyboardType {
        inputKind == .number ? .numberPad : .default
    }

    private func presentTimestampPicker(for key: String) {
        focusedFieldID = nil
        activeTimestampFieldKey = key
        let components = viewModel.timestampComponents(for: key)
        timestampHour = components.hour
        timestampMinute = components.minute
        timestampSecond = components.second
        isTimestampPickerPresented = true
    }

    private func dismissTimestampPicker() {
        isTimestampPickerPresented = false
        activeTimestampFieldKey = nil
    }

    private func commitTimestampPicker() {
        guard let activeTimestampFieldKey else {
            dismissTimestampPicker()
            return
        }

        viewModel.updateTimestamp(
            key: activeTimestampFieldKey,
            hour: timestampHour,
            minute: timestampMinute,
            second: timestampSecond
        )
        dismissTimestampPicker()
    }

    private var timestampSheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24,
            style: .continuous
        )
    }

    private var timestampSheetBackground: some View {
        ZStack {
            timestampSheetShape
                .fill(.ultraThinMaterial)

            timestampSheetShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.86),
                            Color(hex: "#F8F6FF", opacity: 0.74),
                            Color(hex: "#EEF4FF", opacity: 0.70),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            timestampSheetShape
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        }
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
    NewMomentStep2View(
        viewModel: NewMomentStep2ViewModel(
            draft: NewMomentDraft(
                selectedPair: .init(
                    id: "levi-erwin",
                    displayName: "Levi ・ Erwin",
                    nickname: "リヴァエル"
                ),
                selectedSource: .init(
                    id: "aot-s3",
                    displayName: "Attack on Titan Season 3",
                    helperText: "アニメ",
                    mediaType: "anime",
                    totalCount: 24,
                    isFavorite: true
                )
            )
        )
    )
}
