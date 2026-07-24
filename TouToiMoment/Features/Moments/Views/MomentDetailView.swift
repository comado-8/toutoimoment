import PhotosUI
import SwiftUI
import UIKit

struct MomentDetailView: View {
    @ObservedObject private var store: MomentStore
    let momentID: String
    let onEdit: (String) -> Void
    let onDelete: (String) -> Void
    let onOpenPair: (String) -> Void
    let onOpenMoment: (String) -> Void

    @State private var isSharePresented = false
    @State private var isPhotoPickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isImageProcessing = false
    @State private var viewerImageID: String?
    @State private var imagePendingDeletionID: String?
    @State private var isMomentDeleteConfirmationPresented = false
    @State private var isDeletingMoment = false
    @State private var errorMessage: String?

    init(
        store: MomentStore,
        momentID: String,
        onEdit: @escaping (String) -> Void = { _ in },
        onDelete: @escaping (String) -> Void = { _ in },
        onOpenPair: @escaping (String) -> Void = { _ in },
        onOpenMoment: @escaping (String) -> Void = { _ in }
    ) {
        self.store = store
        self.momentID = momentID
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onOpenPair = onOpenPair
        self.onOpenMoment = onOpenMoment
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home)
                .ignoresSafeArea()

            if let moment = store.moment(id: momentID) {
                detailContent(moment)
            } else {
                ContentUnavailableView(
                    AppStrings.momentDetailMissingTitle,
                    systemImage: "sparkles"
                )
                .foregroundStyle(Color.textSecondary)
            }
        }
        .navigationTitle(AppStrings.momentDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    onEdit(momentID)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.appPrimary.opacity(0.14))
                .accessibilityLabel(AppStrings.momentDetailEdit)
                .accessibilityIdentifier("moment.detail.edit")
                .disabled(store.moment(id: momentID) == nil)

                Menu {
                    Button {
                        isSharePresented = true
                    } label: {
                        Label(AppStrings.momentDetailShare, systemImage: "square.and.arrow.up")
                    }
                    .tint(Color.appPrimary)
                    .accessibilityIdentifier("moment.detail.share")

                    if let heartText = copyableHeartText {
                        Button {
                            UIPasteboard.general.string = heartText
                            UIAccessibility.post(
                                notification: .announcement,
                                argument: AppStrings.momentDetailHeartCopied
                            )
                        } label: {
                            Label(AppStrings.momentDetailCopyHeart, systemImage: "doc.on.doc")
                        }
                        .tint(Color.appPrimary)
                        .accessibilityIdentifier("moment.detail.copy-heart")
                    }

                    Divider()

                    Button(role: .destructive) {
                        isMomentDeleteConfirmationPresented = true
                    } label: {
                        Label(AppStrings.momentDetailDelete, systemImage: "trash")
                    }
                    .accessibilityIdentifier("moment.detail.delete")
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.white.opacity(0.72))
                .foregroundStyle(Color.appPrimary)
                .accessibilityLabel(AppStrings.momentDetailMore)
                .accessibilityIdentifier("moment.detail.more")
                .disabled(store.moment(id: momentID) == nil)
            }
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task { await importPhoto(item) }
        }
        .fullScreenCover(isPresented: $isSharePresented) {
            if let moment = store.moment(id: momentID) {
                MomentShareView(
                    moment: moment,
                    onDismiss: { isSharePresented = false }
                )
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { viewerImageID != nil },
                set: { if !$0 { viewerImageID = nil } }
            )
        ) {
            if let moment = store.moment(id: momentID), let viewerImageID {
                MomentImageViewer(
                    items: imageDisplayItems(for: moment),
                    initialImageID: viewerImageID,
                    loadStoredData: { image in
                        try await store.imageData(for: image, momentID: moment.id)
                    },
                    onDismiss: { self.viewerImageID = nil }
                )
            }
        }
        .confirmationDialog(
            AppStrings.momentImageDeleteConfirmationTitle,
            isPresented: Binding(
                get: { imagePendingDeletionID != nil },
                set: { if !$0 { imagePendingDeletionID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(AppStrings.momentImageDelete, role: .destructive) {
                guard let imageID = imagePendingDeletionID else { return }
                imagePendingDeletionID = nil
                Task { await removeImage(imageID) }
            }
            Button(AppStrings.momentImageDeleteCancel, role: .cancel) {
                imagePendingDeletionID = nil
            }
        } message: {
            Text(AppStrings.momentImageDeleteConfirmationMessage)
        }
        .confirmationDialog(
            AppStrings.momentDetailDeleteConfirmationTitle,
            isPresented: $isMomentDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.momentDetailDelete, role: .destructive) {
                Task { await deleteMoment() }
            }
            Button(AppStrings.momentImageDeleteCancel, role: .cancel) {}
        } message: {
            Text(AppStrings.momentDetailDeleteConfirmationMessage)
        }
        .alert(
            AppStrings.momentImageErrorTitle,
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(AppStrings.momentShareErrorDismiss, role: .cancel) {}
        } message: {
            Text(errorMessage ?? AppStrings.momentImageErrorMessage)
        }
    }

    private func detailContent(_ moment: MomentCardModel) -> some View {
        let related = store.relatedMoments(for: moment.id)

        return ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 12) {
                    heroCard(moment)

                    MomentImageStrip(
                        items: imageDisplayItems(for: moment),
                        isProcessing: isImageProcessing,
                        loadStoredData: { image in
                            try await store.imageData(for: image, momentID: moment.id)
                        },
                        onAdd: { isPhotoPickerPresented = true },
                        onOpen: { viewerImageID = $0 },
                        onDelete: { imagePendingDeletionID = $0 }
                    )
                }
                .frame(maxWidth: .infinity)

                if shouldShowHeartSection(moment) {
                    textSection(
                        title: AppStrings.momentDetailHeartScream,
                        text: moment.heartText,
                        color: Color.textPrimary,
                        font: AppTypography.jpAccent()
                    )
                }

                if !moment.reactionIDs.isEmpty {
                    reactionSection(moment)
                }

                if moment.sourceID != nil, moment.sourceName != "—" {
                    sourceSection(moment)
                }

                if let pairID = moment.pairID, moment.pairName != "—" {
                    pairSection(moment, pairID: pairID)
                }

                if !related.isEmpty {
                    relatedSection(related, pairName: moment.pairName)
                }

                detailsSection(moment)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
        .accessibilityIdentifier("moment.detail.scroll")
    }

    private func heroCard(_ moment: MomentCardModel) -> some View {
        let primary = primaryText(for: moment)
        let usesHeart = moment.sceneText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.40))

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: detailGlowColors(for: moment.glowPaletteIndex),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 20)

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    if moment.sourceName != "—" {
                        Text(moment.sourceName)
                            .font(.custom("Geist", size: 14, relativeTo: .subheadline).weight(.semibold))
                            .foregroundStyle(Color.sceneDisplay)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }

                    let context = MomentContextDisplayFormatter.compactSummary(for: moment)
                    if !context.isEmpty {
                        Text(context)
                            .font(.custom("Geist", size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }
                .multilineTextAlignment(.center)

                Spacer(minLength: 12)

                MomentHeroTextView(
                    text: primary,
                    usesHeartTypography: usesHeart
                )
                .layoutPriority(1)

                Spacer(minLength: 12)

                if moment.pairName != "—" {
                    Text(moment.pairName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.sceneDisplay)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.50), in: Capsule())
                        .overlay {
                            Capsule().stroke(Color.appPrimaryTint, lineWidth: 1)
                        }
                        .accessibilityIdentifier("moment.detail.hero.pair")
                }
            }
            .frame(maxWidth: .infinity, minHeight: 165)
            .padding(.horizontal, 32)
            .padding(.vertical, 28)

            Button {
                store.toggleFavorite(id: moment.id)
            } label: {
                FavoriteStarIcon(
                    variant: moment.isFavorite ? .on : .default,
                    width: 18,
                    height: 18
                )
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .tint(Color.white.opacity(0.32))
            .frame(width: 36, height: 36)
            .padding(.top, 18)
            .padding(.trailing, 18)
            .accessibilityLabel(AppStrings.momentsFavoriteToggle)
            .accessibilityValue(
                moment.isFavorite
                    ? AppStrings.momentsFavoriteOn
                    : AppStrings.momentsFavoriteOff
            )
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 221)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.70), lineWidth: 1)
        }
        .shadow(color: Color(hex: "#7C6FCD", opacity: 0.08), radius: 20, y: 4)
        .background {
            Color.clear
                .accessibilityElement()
                .accessibilityLabel(primary)
                .accessibilityIdentifier("moment.detail.hero")
                .allowsHitTesting(false)
        }
    }

    private var copyableHeartText: String? {
        let text = store.moment(id: momentID)?.heartText
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? nil : text
    }

    private func imageDisplayItems(for moment: MomentCardModel) -> [MomentImageDisplayItem] {
        moment.images
            .sorted { $0.order < $1.order }
            .map { MomentImageDisplayItem(id: $0.id, source: .stored($0)) }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        guard !isImageProcessing else { return }
        isImageProcessing = true
        defer {
            isImageProcessing = false
            selectedPhotoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw MomentImageRepositoryError.invalidImage
            }
            try await store.addImage(data: data, to: momentID)
        } catch {
            errorMessage = AppStrings.momentImageErrorMessage
        }
    }

    private func removeImage(_ imageID: String) async {
        guard !isImageProcessing else { return }
        isImageProcessing = true
        defer { isImageProcessing = false }
        do {
            try await store.removeImage(id: imageID, from: momentID)
        } catch {
            errorMessage = AppStrings.momentImageDeleteErrorMessage
        }
    }

    private func deleteMoment() async {
        guard !isDeletingMoment else { return }
        isDeletingMoment = true
        defer { isDeletingMoment = false }
        do {
            if try await store.delete(id: momentID) {
                onDelete(momentID)
            }
        } catch {
            errorMessage = AppStrings.momentDetailDeleteErrorMessage
        }
    }

    private func textSection(
        title: String,
        text: String,
        color: Color,
        font: Font
    ) -> some View {
        detailSection(title) {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func reactionSection(_ moment: MomentCardModel) -> some View {
        detailSection(AppStrings.momentDetailReaction) {
            MomentDetailFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(Array(moment.reactionIDs.enumerated()), id: \.element) { index, reactionID in
                    let reaction = ReactionCatalog.reaction(withID: reactionID)
                    let title = reaction?.displayText
                        ?? moment.reactionLabels[safe: index]
                        ?? reactionID

                    Text(title)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.72), in: Capsule())
                        .overlay {
                            Capsule().stroke(Color.appPrimary.opacity(0.18), lineWidth: 0.5)
                        }
                }
            }
        }
    }

    private func sourceSection(_ moment: MomentCardModel) -> some View {
        let items = MomentContextDisplayFormatter.items(for: moment)

        return detailSection(AppStrings.momentDetailSource) {
            VStack(spacing: 12) {
                detailRow(
                    label: AppStrings.momentDetailSourceName,
                    value: moment.sourceName
                )

                ForEach(items) { item in
                    Divider().overlay(Color.white.opacity(0.45))
                    detailRow(label: item.label, value: item.value)
                }
            }
        }
    }

    private func pairSection(_ moment: MomentCardModel, pairID: String) -> some View {
        detailSection(AppStrings.momentDetailPair) {
            PairListCard(
                pair: PairListCardModel(
                    id: pairID,
                    displayName: moment.pairName,
                    nickname: "",
                    favoriteCount: 0,
                    leadingColor: moment.leadingDotColor,
                    trailingColor: moment.trailingDotColor,
                    isFavorite: false
                ),
                onTap: { onOpenPair(pairID) },
                onToggleFavorite: {},
                showsFavoriteControls: false
            )
            .accessibilityHint(AppStrings.momentDetailOpenPairHint)
        }
    }

    private func relatedSection(
        _ related: MomentRelatedMoments,
        pairName: String
    ) -> some View {
        detailSection(AppStrings.momentDetailRelated) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(related.sameSource) { relatedMoment in
                    relatedRow(relatedMoment)
                }

                if !related.samePair.isEmpty {
                    Text(AppStrings.momentDetailMoreFromPair(pairName))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, related.sameSource.isEmpty ? 0 : 8)

                    ForEach(related.samePair) { relatedMoment in
                        relatedRow(relatedMoment)
                    }
                }
            }
        }
    }

    private func relatedRow(_ moment: MomentCardModel) -> some View {
        Button {
            onOpenMoment(moment.id)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: detailGlowColors(for: moment.glowPaletteIndex),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(primaryText(for: moment))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.sceneDisplay)
                        .lineLimit(1)

                    Text(moment.episodeLabel)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(10)
            .frame(height: 72)
            .glassCard(cornerRadius: 16, fillOpacity: 0.42)
        }
        .buttonStyle(.plain)
    }

    private func detailsSection(_ moment: MomentCardModel) -> some View {
        detailSection(AppStrings.momentDetailDetails) {
            detailRow(
                label: AppStrings.momentDetailCreated,
                value: moment.createdAt.formatted(date: .long, time: .omitted)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("moment.detail.details")
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 2)

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    private func detailSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "#4A4A68"))

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func primaryText(for moment: MomentCardModel) -> String {
        let scene = moment.sceneText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !scene.isEmpty { return scene }

        let heart = moment.heartText.trimmingCharacters(in: .whitespacesAndNewlines)
        return heart.isEmpty ? "—" : heart
    }

    private func shouldShowHeartSection(_ moment: MomentCardModel) -> Bool {
        !moment.sceneText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !moment.heartText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func detailGlowColors(for index: Int) -> [Color] {
        switch index {
        case 0: [Color(hex: "#FBD3ED", opacity: 0.50), Color(hex: "#B2B8FD", opacity: 0.42)]
        case 1: [Color(hex: "#B2B8FD", opacity: 0.55), Color(hex: "#E9EAF9", opacity: 0.48)]
        case 2: [Color(hex: "#E9EAF9", opacity: 0.52), Color(hex: "#FCA8D9", opacity: 0.42)]
        case 3: [Color(hex: "#C4B5FD", opacity: 0.48), Color(hex: "#FBD3ED", opacity: 0.46)]
        case 4: [Color(hex: "#A5B4FC", opacity: 0.48), Color(hex: "#C4B5FD", opacity: 0.44)]
        default: [Color(hex: "#FCA8D9", opacity: 0.46), Color(hex: "#E9EAF9", opacity: 0.50)]
        }
    }
}

private struct MomentDetailFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, points: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var points: [CGPoint] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            points.append(CGPoint(x: x, y: y))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        return (
            CGSize(width: proposal.width ?? x, height: y + rowHeight),
            points
        )
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Moment Detail") {
    NavigationStack {
        MomentDetailView(
            store: MomentStore(),
            momentID: MomentCardModel.preview[0].id
        )
    }
}
