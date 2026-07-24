import SwiftUI
import UIKit

struct MomentShareView: View {
    let moment: MomentCardModel
    let onDismiss: () -> Void

    private let photoLibrarySaver: any MomentPhotoLibrarySaving

    @State private var configuration: MomentShareConfiguration
    @State private var sharePayload: MomentActivityPayload?
    @State private var activeAlert: MomentShareAlert?
    @State private var isSaving = false
    @State private var saveConfirmationToken: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @MainActor
    init(
        moment: MomentCardModel,
        onDismiss: @escaping () -> Void,
        photoLibrarySaver: (any MomentPhotoLibrarySaving)? = nil
    ) {
        self.moment = moment
        self.onDismiss = onDismiss
        self.photoLibrarySaver = photoLibrarySaver ?? SystemMomentPhotoLibrarySaver()
        _configuration = State(initialValue: .initial(for: moment))
    }

    var body: some View {
        ZStack {
            AppBackgroundView(theme: .home, motionEnabled: false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(Color.textSecondary)
                    .accessibilityLabel(AppStrings.momentShareClose)
                    .accessibilityIdentifier("moment.share.close")
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 16) {
                        MomentSharePreview(
                            moment: moment,
                            configuration: configuration
                        )

                        customizationSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 116)
                }
            }
        }
        .tint(Color.appPrimary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
        .sheet(item: $sharePayload) { payload in
            MomentActivityView(activityItems: payload.items)
                .presentationDetents([.medium, .large])
        }
        .alert(item: $activeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(AppStrings.momentShareErrorDismiss))
            )
        }
    }

    private var customizationSection: some View {
        VStack(spacing: 0) {
            Label(
                AppStrings.momentShareCustomizationTitle,
                systemImage: "slider.horizontal.3"
            )
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .accessibilityIdentifier("moment.share.customize")

            informationDivider

            VStack(spacing: 0) {
                informationToggle(
                    AppStrings.momentShareShowPair,
                    isOn: $configuration.showsPair,
                    identifier: "moment.share.toggle.pair"
                )
                informationDivider
                if hasReactionCustomization {
                    informationToggle(
                        AppStrings.momentShareShowReaction,
                        isOn: $configuration.showsReaction,
                        identifier: "moment.share.toggle.reaction"
                    )
                    informationDivider
                }
                informationToggle(
                    AppStrings.momentShareShowHashtag,
                    isOn: $configuration.showsHashtag,
                    identifier: "moment.share.toggle.hashtag"
                )
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, fillOpacity: 0.52)
    }

    private var hasReactionCustomization: Bool {
        !MomentContextDisplayFormatter.reactionLabels(for: moment).isEmpty
    }

    private func informationToggle(
        _ title: String,
        isOn: Binding<Bool>,
        identifier: String
    ) -> some View {
        Toggle(title, isOn: isOn)
            .font(.body.weight(.medium))
            .padding(.vertical, 10)
            .accessibilityIdentifier(identifier)
    }

    private var informationDivider: some View {
        Divider()
            .overlay(Color.textSecondary.opacity(0.14))
    }

    private var actionBar: some View {
        VStack(spacing: 8) {
            if saveConfirmationToken != nil {
                Label(AppStrings.momentShareSaved, systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .move(edge: .bottom).combined(with: .opacity)
                    )
                    .accessibilityIdentifier("moment.share.saved")
            }

            HStack(spacing: 12) {
                Button(action: saveToPhotos) {
                    HStack(spacing: 7) {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(
                            isSaving
                                ? AppStrings.momentShareSavingPhoto
                                : AppStrings.momentShareSavePhoto
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isSaving)
                .accessibilityIdentifier("moment.share.save_photo")

                Button(action: prepareShare) {
                    Label(AppStrings.momentShareShare, systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint(AppStrings.momentShareActionHint)
                .accessibilityIdentifier("moment.share.action")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .animation(.easeOut(duration: 0.18), value: saveConfirmationToken)
    }

    @MainActor
    private func renderedImage() -> UIImage? {
        MomentShareImageRenderer.image(
            for: moment,
            configuration: configuration
        )
    }

    @MainActor
    private func prepareShare() {
        guard let image = renderedImage() else {
            activeAlert = .rendering
            return
        }

        sharePayload = MomentActivityPayload(
            items: [
                image,
                MomentShareTextFormatter.text(
                    for: moment,
                    configuration: configuration
                )
            ]
        )
    }

    @MainActor
    private func saveToPhotos() {
        guard !isSaving else { return }
        guard let image = renderedImage() else {
            activeAlert = .rendering
            return
        }

        isSaving = true
        Task { @MainActor in
            let outcome = await MomentPhotoSaveCoordinator.save(
                image,
                using: photoLibrarySaver
            )
            isSaving = false

            switch outcome {
            case .success:
                showSaveConfirmation()
            case .accessDenied, .accessRestricted:
                activeAlert = .photoAccess
            case .saveFailed:
                activeAlert = .photoSave
            }
        }
    }

    @MainActor
    private func showSaveConfirmation() {
        let token = UUID()
        withAnimation(.easeOut(duration: 0.18)) {
            saveConfirmationToken = token
        }
        UIAccessibility.post(
            notification: .announcement,
            argument: AppStrings.momentShareSaved
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard saveConfirmationToken == token else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                saveConfirmationToken = nil
            }
        }
    }
}

struct MomentShareExportCanvas: View {
    let moment: MomentCardModel
    let configuration: MomentShareConfiguration

    var body: some View {
        MomentShareCard(
            moment: moment,
            configuration: configuration
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: MomentShareImageRenderer.cornerRadius,
                style: .continuous
            )
        )
        .frame(
            width: MomentShareImageRenderer.cardSize.width,
            height: MomentShareImageRenderer.cardSize.height
        )
    }
}

private struct MomentSharePreview: View {
    let moment: MomentCardModel
    let configuration: MomentShareConfiguration

    private let maximumHeight: CGFloat = 440

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / MomentShareImageRenderer.cardSize.width,
                maximumHeight / MomentShareImageRenderer.cardSize.height,
                1
            )
            let width = MomentShareImageRenderer.cardSize.width * scale
            let height = MomentShareImageRenderer.cardSize.height * scale

            MomentShareExportCanvas(moment: moment, configuration: configuration)
                .frame(
                    width: MomentShareImageRenderer.cardSize.width,
                    height: MomentShareImageRenderer.cardSize.height
                )
                .scaleEffect(scale)
                .frame(
                    width: width,
                    height: height
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: maximumHeight)
        .accessibilityIdentifier("moment.share.preview")
    }
}

struct MomentShareCard: View {
    let moment: MomentCardModel
    let configuration: MomentShareConfiguration

    init(
        moment: MomentCardModel,
        configuration: MomentShareConfiguration? = nil
    ) {
        self.moment = moment
        self.configuration = configuration ?? .initial(for: moment)
    }

    private var primaryText: String {
        configuration.heartText(for: moment) ?? "—"
    }

    private var visibleSourceName: String? {
        moment.sourceName.nilIfPlaceholder
    }

    private var visibleLocation: String? {
        MomentContextDisplayFormatter.locationSummary(for: moment).trimmedOrNil
    }

    private var visibleTimestamp: String? {
        MomentContextDisplayFormatter.timestamp(for: moment)?.trimmedOrNil
    }

    private var visiblePairName: String? {
        guard configuration.showsPair else { return nil }
        return moment.pairName.nilIfPlaceholder
    }

    private var visibleReactionLabels: [String] {
        guard configuration.showsReaction else { return [] }
        return MomentContextDisplayFormatter.reactionLabels(for: moment)
    }

    private var hasFooter: Bool {
        visiblePairName != nil || !visibleReactionLabels.isEmpty || configuration.showsHashtag
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                sourceHeader
                    .layoutPriority(2)

                shareDivider

                primaryHeartText(primaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                shareDivider
            }
            .padding(.top, 34)
            .padding(.horizontal, 28)
            .frame(height: 410)

            if hasFooter {
                VStack(spacing: 10) {
                    if let visiblePairName {
                        Text(visiblePairName)
                            .font(.custom("Geist-Bold", size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.sceneDisplay)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.surfaceLight.opacity(0.86), in: Capsule())
                            .overlay {
                                Capsule().stroke(Color.appPrimaryTint, lineWidth: 1)
                            }
                    }

                    if !visibleReactionLabels.isEmpty {
                        Text(visibleReactionLabels.joined(separator: "  "))
                            .font(.custom("ZenKakuGothicNew-Medium", size: 14, relativeTo: .subheadline))
                            .foregroundStyle(Color(hex: "#6B6F9A"))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if configuration.showsHashtag {
                        Text("#TouToiMoment")
                            .font(.custom("ZenKakuGothicNew-Medium", size: 16, relativeTo: .body))
                            .foregroundStyle(Color(hex: "#6B6F9A"))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            } else {
                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(Color(hex: "#E8E6F4"))
                .frame(height: 1)

            Text(AppStrings.momentShareCreatedWith)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .tracking(0.3)
                .foregroundStyle(Color.sceneDisplay.opacity(0.34))
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .frame(width: 342, height: 612)
        .background {
            ZStack {
                RoundedRectangle(
                    cornerRadius: MomentShareImageRenderer.cornerRadius,
                    style: .continuous
                )
                    .fill(Color.white)

                RoundedRectangle(
                    cornerRadius: MomentShareImageRenderer.cornerRadius,
                    style: .continuous
                )
                    .fill(Color.white.opacity(0.40))

                RoundedRectangle(
                    cornerRadius: MomentShareImageRenderer.cornerRadius,
                    style: .continuous
                )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#C4B5F0", opacity: 0.19),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FBD3ED", opacity: 0.25),
                                Color(hex: "#B2B8FD", opacity: 0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 12)
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: MomentShareImageRenderer.cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: MomentShareImageRenderer.cornerRadius,
                style: .continuous
            )
                .stroke(Color.white, lineWidth: 1)
        }
        .shadow(color: Color(hex: "#7C6FCD", opacity: 0.12), radius: 32, y: 12)
        .accessibilityElement(children: .combine)
    }

    private func primaryHeartText(_ text: String) -> some View {
        ViewThatFits(in: .vertical) {
            primaryHeartTextCandidate(text, size: 16)
            primaryHeartTextCandidate(text, size: 15)
            primaryHeartTextCandidate(text, size: 14)
            primaryHeartTextCandidate(text, size: 13)
            primaryHeartTextCandidate(text, size: 12)
        }
        .layoutPriority(3)
        .padding(.horizontal, 4)
        .padding(.vertical, 24)
    }

    private func primaryHeartTextCandidate(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.custom("ZenKakuGothicNew-Medium", size: size, relativeTo: .body))
            .foregroundStyle(Color(hex: "#6B6F9A"))
            .multilineTextAlignment(.center)
            .lineSpacing(size * 0.7)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(color: Color.sceneDisplay.opacity(0.25), radius: 5, y: 2)
    }

    private var sourceHeader: some View {
        VStack(spacing: 5) {
            MomentSparkleIcon(color: Color.appPrimary, width: 16, height: 26)
                .frame(width: 49, height: 49)
                .background(Color.white.opacity(0.42), in: Circle())

            if let visibleSourceName {
                Text(visibleSourceName)
                    .font(.custom("ZenAntique-Regular", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.sceneDisplay)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let visibleLocation {
                Text(visibleLocation)
                    .font(MomentShareEpisodeTypography.font(for: visibleLocation))
                    .foregroundStyle(Color.sceneDisplay)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            if let visibleTimestamp {
                Text(visibleTimestamp)
                    .font(.custom("EBGaramond-SemiBold", size: 24, relativeTo: .title2))
                    .foregroundStyle(Color.sceneDisplay)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var shareDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.57))
            .frame(width: 286, height: 1)
    }
}

enum MomentShareEpisodeTypography {
    static func font(for text: String) -> Font {
        if usesJapaneseFont(for: text) {
            return .custom("ZenAntique-Regular", size: 20, relativeTo: .title3)
        }

        return .custom("EBGaramond-Regular", size: 20, relativeTo: .title3)
    }

    static func usesJapaneseFont(for text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3040...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xFF66...0xFF9F:
                return true
            default:
                return false
            }
        }
    }
}

private enum MomentShareAlert: String, Identifiable {
    case rendering
    case photoAccess
    case photoSave

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rendering: AppStrings.momentShareErrorTitle
        case .photoAccess: AppStrings.momentSharePhotoAccessErrorTitle
        case .photoSave: AppStrings.momentSharePhotoSaveErrorTitle
        }
    }

    var message: String {
        switch self {
        case .rendering: AppStrings.momentShareErrorMessage
        case .photoAccess: AppStrings.momentSharePhotoAccessErrorMessage
        case .photoSave: AppStrings.momentSharePhotoSaveErrorMessage
        }
    }
}

private struct MomentActivityPayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct MomentActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

#Preview("Moment Share") {
    MomentShareView(moment: MomentCardModel.preview[0], onDismiss: {})
}
