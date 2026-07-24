import SwiftUI

struct MomentCard: View {
    enum Layout: Equatable {
        case homeRail
        case momentGrid
    }

    let model: MomentCardModel
    let layout: Layout
    @Binding var face: MomentFace
    var onToggleFavorite: () -> Void
    var onOpen: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var settledAngle: Double
    @State private var dragAngle: Double = 0

    init(
        model: MomentCardModel,
        layout: Layout,
        face: Binding<MomentFace> = .constant(.scene),
        onToggleFavorite: @escaping () -> Void = {},
        onOpen: (() -> Void)? = nil
    ) {
        self.model = model
        self.layout = layout
        _face = face
        _settledAngle = State(
            initialValue: MomentCardFlipMotion.restingAngle(for: face.wrappedValue)
        )
        self.onToggleFavorite = onToggleFavorite
        self.onOpen = onOpen
    }

    var body: some View {
        Group {
            switch layout {
            case .homeRail:
                cardSurface(for: .scene)
                    .frame(width: 175, height: 170)
            case .momentGrid:
                flippableCard
                    .aspectRatio(175 / 170, contentMode: .fit)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .simultaneousGesture(flipGesture, including: layout == .momentGrid ? .all : .none)
        .gesture(
            TapGesture().onEnded { onOpen?() },
            including: onOpen == nil ? .none : .gesture
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: AppStrings.momentsShowScene) {
            updateFace(.scene)
        }
        .accessibilityAction(named: AppStrings.momentsShowHeart) {
            updateFace(.heart)
        }
        .onChange(of: face) { _, newFace in
            synchronizeAngle(to: newFace)
        }
    }

    @ViewBuilder
    private var flippableCard: some View {
        if accessibilityReduceMotion {
            cardSurface(for: face)
                .id(face)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.16), value: face)
        } else {
            MomentCardFlip(
                angle: settledAngle + dragAngle,
                front: cardSurface(for: .scene),
                back: cardSurface(for: .heart)
            )
        }
    }

    private func cardSurface(for requestedFace: MomentFace) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.4))

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#C4B5F0", opacity: 0.19), location: 0),
                            .init(color: .white.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: glowColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 131, height: 130)
                .blur(radius: 12.3)

            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    PairColorDot(color: model.leadingDotColor)
                    PairColorDot(color: model.trailingDotColor)
                }
                .padding(.top, 15)

                Spacer(minLength: 0)

                momentText(for: requestedFace)

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 8) {
                    Text(model.caption)
                        .font(AppTypography.momentCardCaption())
                        .foregroundStyle(Color.appPrimary.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 8)

                    Text(model.episodeLabel)
                        .font(AppTypography.momentCardEpisode())
                        .foregroundStyle(Color.appPrimary.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }

            favoriteControl(for: requestedFace)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.white.opacity(0.67), lineWidth: 1)
        }
        .shadow(color: Color(hex: "#7C6FCD", opacity: 0.08), radius: 20, x: 0, y: 4)
    }

    private func momentText(for requestedFace: MomentFace) -> some View {
        let text = displayedText(for: requestedFace)
        let isScene = requestedFace == .scene

        return Text(text)
            .font(isScene ? AppTypography.momentCardScene() : AppTypography.momentCardHeart())
            .tracking(0.7)
            .foregroundStyle(isScene ? Color.sceneDisplay : Color.sceneHeart)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .accessibilityLabel(text)
            .accessibilityValue(
                isScene ? AppStrings.momentsScene : AppStrings.momentsHeart
            )
    }

    @ViewBuilder
    private func favoriteControl(for requestedFace: MomentFace) -> some View {
        VStack {
            HStack {
                Spacer()

                if layout == .momentGrid, requestedFace == face {
                    Button(action: onToggleFavorite) {
                        favoriteIcon
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("moments.card.favorite")
                    .accessibilityLabel(AppStrings.momentsFavoriteToggle)
                    .accessibilityValue(
                        model.isFavorite
                            ? AppStrings.momentsFavoriteOn
                            : AppStrings.momentsFavoriteOff
                    )
                } else {
                    favoriteIcon
                        .padding(8)
                        .accessibilityHidden(true)
                }
            }

            Spacer()
        }
        .padding(.top, 2)
        .padding(.trailing, 1)
    }

    private var favoriteIcon: some View {
        FavoriteStarIcon(
            variant: model.isFavorite ? .on : .default,
            width: 20,
            height: 20
        )
    }

    private var flipGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard layout == .momentGrid, !accessibilityReduceMotion else { return }
                dragAngle = MomentCardFlipMotion.dragAngle(
                    horizontal: value.translation.width,
                    vertical: value.translation.height
                )
            }
            .onEnded { value in
                guard layout == .momentGrid else { return }
                guard MomentCardFlipMotion.isHorizontal(
                    horizontal: value.translation.width,
                    vertical: value.translation.height
                ) else {
                    settleDragWithoutFlip()
                    return
                }

                guard MomentCardFlipMotion.shouldCommit(
                    horizontal: value.translation.width,
                    predictedHorizontal: value.predictedEndTranslation.width
                ) else {
                    settleDragWithoutFlip()
                    return
                }

                let direction = MomentCardFlipMotion.direction(
                    for: value.translation.width
                )
                commitFlip(direction: direction)
            }
    }

    private func commitFlip(direction: MomentCardFlipDirection) {
        rebaseAngleIfNeeded()
        let targetAngle = MomentCardFlipMotion.targetAngle(
            from: settledAngle,
            direction: direction
        )

        if accessibilityReduceMotion {
            settledAngle = targetAngle
            dragAngle = 0
            var nextFace = face
            nextFace.toggle()
            face = nextFace
        } else {
            withAnimation(.spring(duration: 0.32, bounce: 0.04)) {
                settledAngle = targetAngle
                dragAngle = 0
                var nextFace = face
                nextFace.toggle()
                face = nextFace
            }
        }
    }

    private func settleDragWithoutFlip() {
        guard dragAngle != 0 else { return }
        if accessibilityReduceMotion {
            dragAngle = 0
        } else {
            withAnimation(.spring(duration: 0.24, bounce: 0.02)) {
                dragAngle = 0
            }
        }
    }

    private func synchronizeAngle(to newFace: MomentFace) {
        guard MomentCardFlipMotion.face(for: settledAngle) != newFace else { return }
        rebaseAngleIfNeeded()
        let targetAngle = MomentCardFlipMotion.semanticTargetAngle(
            from: settledAngle,
            face: newFace
        )

        if accessibilityReduceMotion {
            settledAngle = targetAngle
            dragAngle = 0
        } else {
            withAnimation(.spring(duration: 0.32, bounce: 0.04)) {
                settledAngle = targetAngle
                dragAngle = 0
            }
        }
    }

    private func rebaseAngleIfNeeded() {
        guard abs(settledAngle) >= 720 else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            settledAngle = MomentCardFlipMotion.rebasedAngle(settledAngle)
        }
    }

    private func updateFace(_ newFace: MomentFace) {
        guard face != newFace else { return }
        face = newFace
    }

    private func displayedText(for requestedFace: MomentFace) -> String {
        let value = requestedFace == .scene ? model.sceneText : model.heartText
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "—" : value
    }

    private var glowColors: [Color] {
        switch model.glowPaletteIndex {
        case 0:
            return [Color(hex: "#FBD3ED", opacity: 0.65), Color(hex: "#B2B8FD", opacity: 0.65)]
        case 1:
            return [Color(hex: "#B2B8FD", opacity: 0.85), Color(hex: "#E9EAF9", opacity: 0.85)]
        case 2:
            return [Color(hex: "#E9EAF9", opacity: 0.65), Color(hex: "#FCA8D9", opacity: 0.65)]
        case 3:
            return [Color(hex: "#C4B5FD", opacity: 0.65), Color(hex: "#FBD3ED", opacity: 0.65)]
        case 4:
            return [Color(hex: "#A5B4FC", opacity: 0.65), Color(hex: "#C4B5FD", opacity: 0.65)]
        default:
            return [Color(hex: "#FCA8D9", opacity: 0.65), Color(hex: "#E9EAF9", opacity: 0.65)]
        }
    }
}

enum MomentCardFlipDirection {
    case left
    case right

    var angleDelta: Double {
        switch self {
        case .left: -180
        case .right: 180
        }
    }
}

enum MomentCardFlipMotion {
    static let referenceCardWidth: CGFloat = 175
    static let commitFraction: CGFloat = 0.25
    static let predictedCommitFraction: CGFloat = 0.5
    static let horizontalDominance: CGFloat = 1.1
    static let maximumShadeOpacity = 0.08
    static let maximumScaleReduction = 0.015

    static func restingAngle(for face: MomentFace) -> Double {
        face == .scene ? 0 : 180
    }

    static func isHorizontal(horizontal: CGFloat, vertical: CGFloat) -> Bool {
        abs(horizontal) > abs(vertical) * horizontalDominance
    }

    static func dragAngle(horizontal: CGFloat, vertical: CGFloat) -> Double {
        guard isHorizontal(horizontal: horizontal, vertical: vertical) else { return 0 }
        let angle = Double(horizontal / referenceCardWidth) * 180
        return min(max(angle, -180), 180)
    }

    static func shouldCommit(
        horizontal: CGFloat,
        predictedHorizontal: CGFloat
    ) -> Bool {
        abs(horizontal) >= referenceCardWidth * commitFraction
            || abs(predictedHorizontal) >= referenceCardWidth * predictedCommitFraction
    }

    static func direction(for horizontal: CGFloat) -> MomentCardFlipDirection {
        horizontal < 0 ? .left : .right
    }

    static func targetAngle(
        from currentAngle: Double,
        direction: MomentCardFlipDirection
    ) -> Double {
        currentAngle + direction.angleDelta
    }

    static func semanticTargetAngle(from currentAngle: Double, face: MomentFace) -> Double {
        currentAngle + (face == .heart ? -180 : 180)
    }

    static func face(for angle: Double) -> MomentFace {
        let normalized = normalizedAngle(angle)
        return normalized < 90 || normalized >= 270 ? .scene : .heart
    }

    static func edgeProgress(for angle: Double) -> Double {
        abs(sin(normalizedAngle(angle) * .pi / 180))
    }

    static func shadeOpacity(for angle: Double) -> Double {
        edgeProgress(for: angle) * maximumShadeOpacity
    }

    static func scale(for angle: Double) -> Double {
        1 - edgeProgress(for: angle) * maximumScaleReduction
    }

    static func rebasedAngle(_ angle: Double) -> Double {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        if remainder > 180 { return remainder - 360 }
        if remainder < -180 { return remainder + 360 }
        return remainder
    }

    private static func normalizedAngle(_ angle: Double) -> Double {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        return remainder >= 0 ? remainder : remainder + 360
    }
}

private struct MomentCardFlip<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        ZStack {
            front
                .opacity(showsFront ? 1 : 0)
                .allowsHitTesting(showsFront)
                .accessibilityHidden(!showsFront)

            back
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.72
                )
                .opacity(showsFront ? 0 : 1)
                .allowsHitTesting(!showsFront)
                .accessibilityHidden(showsFront)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(MomentCardFlipMotion.shadeOpacity(for: angle)))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .scaleEffect(MomentCardFlipMotion.scale(for: angle))
        .rotation3DEffect(
            .degrees(angle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.72
        )
    }

    private var showsFront: Bool {
        let remainder = angle.truncatingRemainder(dividingBy: 360)
        let normalizedAngle = remainder >= 0 ? remainder : remainder + 360
        return normalizedAngle < 90 || normalizedAngle >= 270
    }
}

private struct PairColorDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .inset(by: 0.5)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: Color.white.opacity(0.16), radius: 1.5)
    }
}

#Preview {
    ZStack {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        MomentCard(
            model: .preview[1],
            layout: .momentGrid
        )
        .frame(width: 175)
    }
}
