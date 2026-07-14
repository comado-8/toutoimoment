import SwiftUI

struct NewMomentStep4View: View {
    @StateObject private var viewModel: NewMomentStep4ViewModel
    @State private var isReactionPickerPresented = false

    let onSave: (NewMomentDraft) -> Void
    let onCancel: () -> Void
    let onBackToStep1: () -> Void
    let onBackToStep2: (NewMomentDraft) -> Void
    let onBackToStep3: (NewMomentDraft) -> Void

    init(
        viewModel: NewMomentStep4ViewModel,
        onSave: @escaping (NewMomentDraft) -> Void = { _ in },
        onCancel: @escaping () -> Void = {},
        onBackToStep1: @escaping () -> Void = {},
        onBackToStep2: @escaping (NewMomentDraft) -> Void = { _ in },
        onBackToStep3: @escaping (NewMomentDraft) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
        self.onCancel = onCancel
        self.onBackToStep1 = onBackToStep1
        self.onBackToStep2 = onBackToStep2
        self.onBackToStep3 = onBackToStep3
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                NewMomentFlowHeader(onDismiss: onCancel)

                NewMomentProgressDots(
                    activeCount: 4,
                    accessibilityLabel: AppStrings.newMomentStep4Progress
                )
                .padding(.top, 13)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 9) {
                        NewMomentCompletedSummary(
                            title: AppStrings.newMomentStep4ChooseCompletedTitle,
                            summary: viewModel.chooseSummary,
                            width: 348,
                            onTap: onBackToStep1
                        )
                        NewMomentFlowSeparator(width: 348)
                        NewMomentCompletedSummary(
                            title: AppStrings.newMomentStep4ContextCompletedTitle,
                            summary: viewModel.contextSummary,
                            width: 348,
                            onTap: { onBackToStep2(viewModel.draft) }
                        )
                        NewMomentFlowSeparator(width: 348)
                        NewMomentCompletedSummary(
                            title: AppStrings.newMomentStep4CaptureCompletedTitle,
                            summary: viewModel.captureSummary,
                            width: 348,
                            onTap: { onBackToStep3(viewModel.draft) }
                        )
                        NewMomentFlowSeparator(width: 348)
                        reactSection
                    }
                    .padding(.top, 15)
                    .padding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveButtonContainer
        }
        .overlay {
            if isReactionPickerPresented {
                reactionPickerOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.easeOut(duration: 0.24), value: isReactionPickerPresented)
    }

    private var reactSection: some View {
        HStack(alignment: .top, spacing: 8) {
            LinearGradient(
                colors: [Color.appPrimary, Color.appPrimarySoft.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 3)
            .frame(maxHeight: .infinity)
            .clipShape(Capsule(style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.newMomentStep4Title)
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(Color.appPrimary)

                Text(AppStrings.newMomentStep4ReactionPickerPrompt)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "#4A4A68"))

                Button(action: presentReactionPicker) {
                    if viewModel.selectedReactions.isEmpty {
                        emptyReactionPicker
                    } else {
                        selectedReactionChips
                    }
                }
                .buttonStyle(.plain)

                Text(AppStrings.newMomentStep4ReactionHelp)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "#8E91B0"))
            }
        }
        .frame(width: 348, alignment: .leading)
    }

    private var emptyReactionPicker: some View {
        Text(AppStrings.newMomentStep4AddReactions)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.62))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: "#D6D1F2", opacity: 0.34), lineWidth: 1)
                    }
            )
    }

    private var selectedReactionChips: some View {
        FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(viewModel.selectedReactions) { reaction in
                ReactionChip(
                    title: reaction.displayText,
                    isSelected: true,
                    compact: true
                )
            }

            Text("+")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.70))
                        .overlay {
                            Circle()
                                .stroke(Color(hex: "#D6D1F2", opacity: 0.45), lineWidth: 1)
                        }
                )
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.44))
        )
    }

    private var saveButtonContainer: some View {
        VStack(spacing: 0) {
            Button(action: { onSave(viewModel.draft) }) {
                HStack(spacing: 8) {
                    MomentSparkleIcon(color: .white, width: 13, height: 21)

                    Text(AppStrings.newMomentStep4SaveMoment)
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule(style: .continuous)
                        .fill(viewModel.canSave ? Color.appPrimary : Color.appPrimary.opacity(0.26))
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSave)
            .accessibilityHint(viewModel.canSave ? "" : AppStrings.newMomentStep4SaveDisabledHint)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.clear)
    }

    private var reactionPickerOverlay: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()
                    .onTapGesture {
                        cancelReactionPicker()
                    }

                VStack(spacing: 0) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: "#C9CBD3", opacity: 0.75))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    HStack {
                        Button(AppStrings.newMomentReactionPickerCancel, action: cancelReactionPicker)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(Color(hex: "#6E7482"))

                        Spacer()

                        Text(AppStrings.newMomentReactionPickerTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        Button(AppStrings.newMomentReactionPickerSave, action: commitReactionPicker)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 17)
                    .padding(.bottom, 17)

                    Rectangle()
                        .fill(Color(hex: "#D8D4E8", opacity: 0.55))
                        .frame(height: 1)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(ReactionCatalog.sections) { section in
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(section.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .tracking(0.5)
                                        .foregroundStyle(Color(hex: "#4A4A68"))
                                        .padding(.top, 24)
                                        .padding(.bottom, 12)

                                    FlowLayout(horizontalSpacing: 12, verticalSpacing: 12) {
                                        ForEach(section.reactions) { reaction in
                                            Button(action: { viewModel.toggleReaction(reaction) }) {
                                                ReactionChip(
                                                    title: reaction.displayText,
                                                    isSelected: viewModel.isReactionSelected(reaction),
                                                    compact: false
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, max(proxy.safeAreaInsets.bottom, 0) + 24)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: min(660, proxy.size.height - 80))
                .background(sheetBackground)
                .clipShape(sheetShape)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func presentReactionPicker() {
        viewModel.beginReactionEditing()
        isReactionPickerPresented = true
    }

    private func cancelReactionPicker() {
        viewModel.cancelReactionEditing()
        isReactionPickerPresented = false
    }

    private func commitReactionPicker() {
        viewModel.commitReactionEditing()
        isReactionPickerPresented = false
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
                .fill(.ultraThinMaterial)

            sheetShape
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

            sheetShape
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct ReactionChip: View {
    let title: String
    let isSelected: Bool
    let compact: Bool

    var body: some View {
        Text(title)
            .font(.system(size: compact ? 12 : 14, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : Color(hex: "#55566F"))
            .padding(.horizontal, compact ? 12 : 16)
            .frame(height: compact ? 29 : 34)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.appPrimary : Color.white.opacity(0.82))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(
                                isSelected ? Color.clear : Color(hex: "#D8D4E8", opacity: 0.70),
                                lineWidth: 1
                            )
                    }
            )
    }
}

private struct FlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0
        let rows = rows(in: maxWidth, subviews: subviews)
        return CGSize(
            width: maxWidth,
            height: rows.last.map { $0.maxY } ?? 0
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = rows(in: bounds.width, subviews: subviews)

        for row in rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func rows(in maxWidth: CGFloat, subviews: Subviews) -> [FlowRow] {
        guard maxWidth > 0 else {
            return []
        }

        var rows: [FlowRow] = []
        var currentItems: [FlowItem] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentHeight: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextX = currentItems.isEmpty ? size.width : currentX + horizontalSpacing + size.width

            if nextX > maxWidth, !currentItems.isEmpty {
                rows.append(FlowRow(y: currentY, height: currentHeight, items: currentItems))
                currentY += currentHeight + verticalSpacing
                currentItems = []
                currentX = 0
                currentHeight = 0
            }

            let x = currentItems.isEmpty ? 0 : currentX + horizontalSpacing
            currentItems.append(FlowItem(index: index, x: x, size: size))
            currentX = x + size.width
            currentHeight = max(currentHeight, size.height)
        }

        if !currentItems.isEmpty {
            rows.append(FlowRow(y: currentY, height: currentHeight, items: currentItems))
        }

        return rows
    }
}

private struct FlowRow {
    let y: CGFloat
    let height: CGFloat
    let items: [FlowItem]

    var maxY: CGFloat {
        y + height
    }
}

private struct FlowItem {
    let index: Int
    let x: CGFloat
    let size: CGSize
}

#Preview {
    NewMomentStep4View(
        viewModel: NewMomentStep4ViewModel(
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
                ),
                sceneSummary: "印象に残った場面",
                heartScream: "尊い"
            )
        )
    )
}
