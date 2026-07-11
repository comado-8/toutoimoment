import SwiftUI

enum AppTheme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let screen: CGFloat = 24
        static let ctaScreen: CGFloat = 16
    }

    enum Layout {
        static let bottomTabBarReservedHeight: CGFloat = 128
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 18
        static let large: CGFloat = 22
        static let xLarge: CGFloat = 28
        static let full: CGFloat = 999
    }
}

extension Color {
    static let appPrimary = Color(hex: "#403CF8")
    static let appPrimarySoft = Color(hex: "#8382FC")
    static let appPrimaryTint = Color(hex: "#B2B8FD")
    static let appAccent = Color(hex: "#FCA8D9")
    static let appAccentSoft = Color(hex: "#FBD3ED")
    static let surfaceLight = Color(hex: "#E9EAF9")
    static let surfaceWhite = Color(hex: "#F3F2F6")
    static let sceneDisplay = Color(hex: "#3E4FAD")
    static let sceneHeart = Color(hex: "#953EAD")

    static let textPrimary = Color(hex: "#1F1C2F")
    static let textSecondary = Color(hex: "#8A86A4")
    static let textMuted = Color(hex: "#B0ABC3")
    static let tabBarMuted = Color(hex: "#A5A2BF")
    static let glassBorder = Color.white.opacity(0.72)
    static let glassFill = Color.white.opacity(0.60)
    static let glassFillSecondary = Color.white.opacity(0.48)
    static let floatingShadow = Color.appPrimary.opacity(0.14)

    init(hex: String, opacity: Double = 1) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        let r, g, b: UInt64
        switch sanitized.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xff, int & 0xff)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }
}

struct AppBackgroundView: View {
    let theme: BackgroundTheme
    var motionEnabled: Bool = true

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        GeometryReader { geometry in
            if shouldAnimate {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    backgroundContent(
                        size: geometry.size,
                        time: context.date.timeIntervalSinceReferenceDate
                    )
                }
            } else {
                backgroundContent(size: geometry.size, time: 0)
            }
        }
    }

    private var shouldAnimate: Bool {
        motionEnabled && !accessibilityReduceMotion && theme.motionProfile.speed > 0
    }

    @ViewBuilder
    private func backgroundContent(size: CGSize, time: TimeInterval) -> some View {
        ZStack {
            if let backgroundAssetName = theme.backgroundAssetName {
                Image(backgroundAssetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                ZStack {
                    Rectangle()
                        .fill(theme.baseGradient.linearGradient)

                    ForEach(theme.blobs) { blob in
                        blobView(blob, in: size, time: time)
                    }

                    if let noiseOverlay = theme.noiseOverlay {
                        BackgroundNoiseOverlay(spec: noiseOverlay)
                            .blendMode(noiseOverlay.blendMode)
                            .opacity(noiseOverlay.opacity)
                    }
                }
                .opacity(theme.overallOpacity)
            }

            ForEach(theme.animatedImageLayers) { layer in
                animatedImageLayerView(layer, in: size, time: time)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .allowsHitTesting(false)
    }

    private func blobView(_ blob: BlobSpec, in canvasSize: CGSize, time: TimeInterval) -> some View {
        let motion = blobMotion(for: blob, time: time)

        return Ellipse()
            .fill(blob.gradient)
            .frame(width: blob.size.width, height: blob.size.height)
            .blur(radius: blob.blur)
            .rotationEffect(.degrees(blob.rotation))
            .scaleEffect(motion.scale)
            .position(
                x: canvasSize.width * blob.xRatio,
                y: canvasSize.height * blob.yRatio
            )
            .offset(motion.offset)
            .blendMode(blob.blendMode)
    }

    private func animatedImageLayerView(
        _ layer: BackgroundImageLayerSpec,
        in canvasSize: CGSize,
        time: TimeInterval
    ) -> some View {
        let motion = motionState(seed: layer.motionSeed, weight: layer.motionWeight, time: time)

        return Image(layer.assetName)
            .resizable()
            .interpolation(.high)
            .frame(width: layer.size.width, height: layer.size.height)
            .scaleEffect(motion.scale)
            .position(
                x: canvasSize.width * layer.xRatio,
                y: canvasSize.height * layer.yRatio
            )
            .offset(motion.offset)
            .opacity(layer.opacity)
            .blendMode(layer.blendMode)
    }

    private func blobMotion(for blob: BlobSpec, time: TimeInterval) -> BlobMotionState {
        motionState(seed: blob.motionSeed, weight: blob.motionWeight, time: time)
    }

    private func motionState(seed: Double, weight: CGFloat, time: TimeInterval) -> BlobMotionState {
        guard shouldAnimate else {
            return .still
        }

        let profile = theme.motionProfile
        let speed = time * profile.speed
        let phase = profile.seed + seed

        let x =
            sin(speed + phase) * profile.primaryAmplitude.width * weight +
            cos(speed * 0.61 + phase * 0.73) * profile.secondaryAmplitude.width * weight

        let y =
            cos(speed * 0.88 + phase * 1.12) * profile.primaryAmplitude.height * weight +
            sin(speed * 0.54 + phase * 0.67) * profile.secondaryAmplitude.height * weight

        let scale = 1 + sin(speed * 0.42 + phase * 1.31) * profile.scaleAmplitude * weight

        return BlobMotionState(
            offset: CGSize(width: x, height: y),
            scale: scale
        )
    }
}

private struct BackgroundNoiseOverlay: View {
    let spec: NoiseOverlaySpec

    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: spec.seed)

            for _ in 0..<spec.particleCount {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let side = CGFloat.random(in: spec.sideRange, using: &generator)
                let alpha = Double.random(in: spec.alphaRange, using: &generator)
                let rect = CGRect(x: x, y: y, width: side, height: side)
                context.fill(Path(rect), with: .color(.white.opacity(alpha)))
            }
        }
    }
}

struct BackgroundTheme {
    let backgroundAssetName: String?
    let overallOpacity: Double
    let baseGradient: BackgroundGradientSpec
    let blobs: [BlobSpec]
    let animatedImageLayers: [BackgroundImageLayerSpec]
    let noiseOverlay: NoiseOverlaySpec?
    let motionProfile: BackgroundMotionProfile
}

struct BackgroundGradientSpec {
    let stops: [Gradient.Stop]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    var linearGradient: LinearGradient {
        LinearGradient(
            stops: stops,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

struct BlobSpec: Identifiable {
    let id: String
    let color: Color
    let opacity: Double
    let size: CGSize
    let blur: CGFloat
    let rotation: Double
    let xRatio: CGFloat
    let yRatio: CGFloat
    let blendMode: BlendMode
    let motionSeed: Double
    let motionWeight: CGFloat

    var gradient: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: color.opacity(opacity), location: 0),
                .init(color: color.opacity(opacity * 0.44), location: 0.46),
                .init(color: color.opacity(opacity * 0.16), location: 0.72),
                .init(color: .clear, location: 1)
            ],
            center: .center,
            startRadius: 0,
            endRadius: max(size.width, size.height) * 0.5
        )
    }
}

struct BackgroundImageLayerSpec: Identifiable {
    let id: String
    let assetName: String
    let size: CGSize
    let xRatio: CGFloat
    let yRatio: CGFloat
    let opacity: Double
    let blendMode: BlendMode
    let motionSeed: Double
    let motionWeight: CGFloat
}

struct NoiseOverlaySpec {
    let opacity: Double
    let blendMode: BlendMode
    let particleCount: Int
    let sideRange: ClosedRange<CGFloat>
    let alphaRange: ClosedRange<Double>
    let seed: UInt64
}

struct BackgroundMotionProfile {
    let primaryAmplitude: CGSize
    let secondaryAmplitude: CGSize
    let speed: Double
    let scaleAmplitude: CGFloat
    let seed: Double
}

private struct BlobMotionState {
    let offset: CGSize
    let scale: CGFloat

    static let still = BlobMotionState(offset: .zero, scale: 1)
}

extension BackgroundTheme {
    static let home = BackgroundTheme(
        backgroundAssetName: "HomeBackgroundOfficial",
        overallOpacity: 0.60,
        baseGradient: BackgroundGradientSpec(
            stops: [
                .init(color: .white, location: 0),
                .init(color: Color(hex: "#F8F5FD"), location: 0.48),
                .init(color: Color(hex: "#E6E9FF"), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        blobs: [
            BlobSpec(
                id: "peach-top-left",
                color: Color(hex: "#FFDCCB"),
                opacity: 0.26,
                size: CGSize(width: 596.374, height: 542.762),
                blur: 96,
                rotation: 37.74,
                xRatio: 0.4025,
                yRatio: 0.2340,
                blendMode: .normal,
                motionSeed: 0.4,
                motionWeight: 0.82
            ),
            BlobSpec(
                id: "peach-mid",
                color: Color(hex: "#FFD7CC"),
                opacity: 0.22,
                size: CGSize(width: 504.357, height: 336.552),
                blur: 90,
                rotation: -18.4,
                xRatio: 0.5689,
                yRatio: 0.5211,
                blendMode: .normal,
                motionSeed: 1.8,
                motionWeight: 0.70
            ),
            BlobSpec(
                id: "periwinkle-bottom-left",
                color: Color(hex: "#CED6FF"),
                opacity: 0.22,
                size: CGSize(width: 558.578, height: 327.887),
                blur: 96,
                rotation: 15.67,
                xRatio: 0.2908,
                yRatio: 0.9741,
                blendMode: .normal,
                motionSeed: 2.7,
                motionWeight: 0.76
            ),
            BlobSpec(
                id: "lilac-right-column",
                color: Color(hex: "#DCCFFF"),
                opacity: 0.18,
                size: CGSize(width: 592.139, height: 746.95),
                blur: 126,
                rotation: -27.84,
                xRatio: 1.1045,
                yRatio: 0.9489,
                blendMode: .normal,
                motionSeed: 4.2,
                motionWeight: 0.58
            ),
            BlobSpec(
                id: "lilac-left-mid",
                color: Color(hex: "#DCCFFF"),
                opacity: 0.14,
                size: CGSize(width: 363.636, height: 294.791),
                blur: 82,
                rotation: 60.6,
                xRatio: 0.1573,
                yRatio: 0.6824,
                blendMode: .normal,
                motionSeed: 5.1,
                motionWeight: 0.52
            ),
            BlobSpec(
                id: "lavender-left-center",
                color: Color(hex: "#E8E1FF"),
                opacity: 0.16,
                size: CGSize(width: 370, height: 175),
                blur: 78,
                rotation: 0,
                xRatio: 0.2748,
                yRatio: 0.3973,
                blendMode: .normal,
                motionSeed: 6.4,
                motionWeight: 0.48
            ),
            BlobSpec(
                id: "ice-top-right",
                color: Color(hex: "#DCE7FF"),
                opacity: 0.18,
                size: CGSize(width: 300.851, height: 444.814),
                blur: 102,
                rotation: -15.43,
                xRatio: 0.8102,
                yRatio: 0.2587,
                blendMode: .screen,
                motionSeed: 7.1,
                motionWeight: 0.62
            ),
            BlobSpec(
                id: "blush-lower-mid",
                color: Color(hex: "#F8DDEB"),
                opacity: 0.17,
                size: CGSize(width: 389.123, height: 354.675),
                blur: 90,
                rotation: 142.38,
                xRatio: 0.3500,
                yRatio: 0.8314,
                blendMode: .normal,
                motionSeed: 8.6,
                motionWeight: 0.60
            ),
            BlobSpec(
                id: "ice-center-left",
                color: Color(hex: "#D5E4FF"),
                opacity: 0.14,
                size: CGSize(width: 477.12, height: 373.097),
                blur: 98,
                rotation: 63.37,
                xRatio: 0.1821,
                yRatio: 0.5441,
                blendMode: .screen,
                motionSeed: 9.3,
                motionWeight: 0.54
            ),
            BlobSpec(
                id: "periwinkle-top",
                color: Color(hex: "#C9D2FF"),
                opacity: 0.18,
                size: CGSize(width: 478.318, height: 327.465),
                blur: 88,
                rotation: 19.74,
                xRatio: 0.5216,
                yRatio: 0.0408,
                blendMode: .normal,
                motionSeed: 10.2,
                motionWeight: 0.66
            )
        ],
        animatedImageLayers: [
            BackgroundImageLayerSpec(
                id: "layer-peach-top-left",
                assetName: "HomeBlobPeachTopLeft",
                size: CGSize(width: 393, height: 472),
                xRatio: 0.4025,
                yRatio: 0.2340,
                opacity: 0.30,
                blendMode: .normal,
                motionSeed: 0.6,
                motionWeight: 0.70
            ),
            BackgroundImageLayerSpec(
                id: "layer-peach-mid",
                assetName: "HomeBlobPeachMid",
                size: CGSize(width: 393, height: 390),
                xRatio: 0.5689,
                yRatio: 0.5211,
                opacity: 0.24,
                blendMode: .normal,
                motionSeed: 1.7,
                motionWeight: 0.60
            ),
            BackgroundImageLayerSpec(
                id: "layer-periwinkle-bottom-left",
                assetName: "HomeBlobPeriwinkleBottomLeft",
                size: CGSize(width: 393, height: 224),
                xRatio: 0.2908,
                yRatio: 0.9741,
                opacity: 0.22,
                blendMode: .normal,
                motionSeed: 2.8,
                motionWeight: 0.58
            ),
            BackgroundImageLayerSpec(
                id: "layer-lilac-right-column",
                assetName: "HomeBlobLilacRightColumn",
                size: CGSize(width: 284, height: 468),
                xRatio: 1.1045,
                yRatio: 0.9489,
                opacity: 0.18,
                blendMode: .normal,
                motionSeed: 4.1,
                motionWeight: 0.48
            ),
            BackgroundImageLayerSpec(
                id: "layer-lavender-left-center",
                assetName: "HomeBlobLavenderLeftCenter",
                size: CGSize(width: 393, height: 375),
                xRatio: 0.2748,
                yRatio: 0.3973,
                opacity: 0.18,
                blendMode: .normal,
                motionSeed: 5.5,
                motionWeight: 0.52
            ),
            BackgroundImageLayerSpec(
                id: "layer-ice-top-right",
                assetName: "HomeBlobIceTopRight",
                size: CGSize(width: 265, height: 498),
                xRatio: 0.8102,
                yRatio: 0.2587,
                opacity: 0.20,
                blendMode: .screen,
                motionSeed: 6.9,
                motionWeight: 0.56
            ),
            BackgroundImageLayerSpec(
                id: "layer-blush-lower-mid",
                assetName: "HomeBlobBlushLowerMid",
                size: CGSize(width: 379, height: 363),
                xRatio: 0.3500,
                yRatio: 0.8314,
                opacity: 0.20,
                blendMode: .normal,
                motionSeed: 8.2,
                motionWeight: 0.54
            ),
            BackgroundImageLayerSpec(
                id: "layer-periwinkle-top",
                assetName: "HomeBlobPeriwinkleTop",
                size: CGSize(width: 393, height: 236),
                xRatio: 0.5216,
                yRatio: 0.0408,
                opacity: 0.18,
                blendMode: .normal,
                motionSeed: 9.8,
                motionWeight: 0.56
            )
        ],
        noiseOverlay: NoiseOverlaySpec(
            opacity: 0.16,
            blendMode: .softLight,
            particleCount: 700,
            sideRange: 0.6...1.8,
            alphaRange: 0.02...0.11,
            seed: 42
        ),
        motionProfile: BackgroundMotionProfile(
            primaryAmplitude: CGSize(width: 15, height: 18),
            secondaryAmplitude: CGSize(width: 6, height: 7),
            speed: 0.18,
            scaleAmplitude: 0.015,
            seed: 8.4
        )
    )
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}
