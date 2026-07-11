import SwiftUI

struct RecordRippleButton: View {
  var momentCount: Int = 0
  var onSequenceCompleted: () -> Void = {}

  @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

  @State private var primaryRippleToken = 0
  @State private var secondaryRippleToken = 0
  @State private var primaryRippleActive = false
  @State private var secondaryRippleActive = false
  @State private var animationSequence = 0
  @State private var isHighlighting = false
  @State private var isTapSequenceRunning = false
  @State private var particleReactionActive = false
  @State private var breathingPhase = false
  @State private var reduceMotionBreathingPhase = false
  @State private var coreInteractionScale: CGFloat = 1

  private let footprintSize: CGFloat = 260
  private let coreDiameter: CGFloat = 148

  private static let ambientOrbThresholds = [
    1, 2, 3, 4, 5,
    6, 7, 8, 10, 12,
    14, 16, 18, 20, 23,
    26, 30, 34, 39, 45,
  ]
  private static let ambientOrbConfigs: [AmbientOrbSpec] = [
    AmbientOrbSpec(
      id: 0, size: 10, offset: CGPoint(x: -84, y: -54),
      reactionOffset: CGSize(width: -4, height: -3), color: .white),
    AmbientOrbSpec(
      id: 1, size: 4.5, offset: CGPoint(x: -71, y: -40),
      reactionOffset: CGSize(width: -2, height: 2), color: .white),
    AmbientOrbSpec(
      id: 2, size: 7, offset: CGPoint(x: 94, y: -40), reactionOffset: CGSize(width: 4, height: -3),
      color: .white),
    AmbientOrbSpec(
      id: 3, size: 4.2, offset: CGPoint(x: 108, y: -26),
      reactionOffset: CGSize(width: 2, height: 2), color: .white),
    AmbientOrbSpec(
      id: 4, size: 8, offset: CGPoint(x: -104, y: 22), reactionOffset: CGSize(width: -5, height: 2),
      color: .white),
    AmbientOrbSpec(
      id: 5, size: 4.8, offset: CGPoint(x: -90, y: 35),
      reactionOffset: CGSize(width: -2, height: 3), color: .white),
    AmbientOrbSpec(
      id: 6, size: 7.2, offset: CGPoint(x: 98, y: 28), reactionOffset: CGSize(width: 5, height: 2),
      color: .white),
    AmbientOrbSpec(
      id: 7, size: 4.4, offset: CGPoint(x: 112, y: 42), reactionOffset: CGSize(width: 2, height: 3),
      color: .white),
    AmbientOrbSpec(
      id: 8, size: 8.8, offset: CGPoint(x: -66, y: 88),
      reactionOffset: CGSize(width: -2, height: 5), color: .white),
    AmbientOrbSpec(
      id: 9, size: 4.7, offset: CGPoint(x: -52, y: 102),
      reactionOffset: CGSize(width: 2, height: 3), color: .white),
    AmbientOrbSpec(
      id: 10, size: 9.5, offset: CGPoint(x: 70, y: 88), reactionOffset: CGSize(width: 3, height: 4),
      color: .white),
    AmbientOrbSpec(
      id: 11, size: 4.6, offset: CGPoint(x: 84, y: 104),
      reactionOffset: CGSize(width: 2, height: 4), color: .white),
    AmbientOrbSpec(
      id: 12, size: 6.2, offset: CGPoint(x: -18, y: -112),
      reactionOffset: CGSize(width: -1, height: -3), color: .white),
    AmbientOrbSpec(
      id: 13, size: 4.1, offset: CGPoint(x: -6, y: -96),
      reactionOffset: CGSize(width: 1, height: 2), color: .white),
    AmbientOrbSpec(
      id: 14, size: 5.8, offset: CGPoint(x: 26, y: -104),
      reactionOffset: CGSize(width: 1, height: -3), color: .white),
    AmbientOrbSpec(
      id: 15, size: 4.3, offset: CGPoint(x: 38, y: -90),
      reactionOffset: CGSize(width: 2, height: 2), color: .white),
    AmbientOrbSpec(
      id: 16, size: 5.6, offset: CGPoint(x: -118, y: -12),
      reactionOffset: CGSize(width: -4, height: 1), color: .white),
    AmbientOrbSpec(
      id: 17, size: 4.0, offset: CGPoint(x: -104, y: -2),
      reactionOffset: CGSize(width: -2, height: 2), color: .white),
    AmbientOrbSpec(
      id: 18, size: 5.4, offset: CGPoint(x: 122, y: -6),
      reactionOffset: CGSize(width: 4, height: 1), color: .white),
    AmbientOrbSpec(
      id: 19, size: 4.2, offset: CGPoint(x: 108, y: 8), reactionOffset: CGSize(width: 2, height: 2),
      color: .white),
  ]

  private var visibleAmbientOrbs: [AmbientOrbSpec] {
    let unlockedCount = Self.ambientOrbThresholds.filter { momentCount >= $0 }.count
    return Array(Self.ambientOrbConfigs.prefix(unlockedCount))
  }

  private var breathingScale: CGFloat {
    guard !isTapSequenceRunning, !accessibilityReduceMotion else { return 1 }
    return breathingPhase ? 1.033 : 1
  }

  private var haloPulseOpacity: Double {
    guard !isTapSequenceRunning else { return 1 }
    if accessibilityReduceMotion {
      return reduceMotionBreathingPhase ? 1 : 0.93
    }
    return breathingPhase ? 1 : 0.94
  }

  private var haloPulseBlurBoost: CGFloat {
    guard !isTapSequenceRunning, !accessibilityReduceMotion else { return 0 }
    return breathingPhase ? 4 : 0
  }

  var body: some View {
    Button(action: handleTap) {
      ZStack {
        IdleHaloLayer(
          isHighlighting: isHighlighting,
          haloPulseOpacity: haloPulseOpacity,
          blurBoost: haloPulseBlurBoost,
          scale: breathingScale
        )

        if !accessibilityReduceMotion && primaryRippleActive {
          RecordRippleWave(
            token: primaryRippleToken,
            diameter: 162,
            strokeColors: [
              Color.white.opacity(0.98),
              Color(hex: "#FFD6E9", opacity: 0.94),
              Color(hex: "#B7B8FF", opacity: 0.90),
              Color(hex: "#E6D7FF", opacity: 0.92),
            ],
            glowColors: [
              Color(hex: "#FFD1E6", opacity: 0.74),
              Color(hex: "#CCB8FF", opacity: 0.80),
              Color(hex: "#AAB0FF", opacity: 0.66),
            ],
            fillColor: Color.white.opacity(0.09),
            duration: 0.68,
            maxScale: 2.02,
            lineWidth: 2.8,
            glowLineWidth: 18,
            startScale: 0.96,
            startOpacity: 0.88,
            endBlur: 4.8
          )
          .id("primary-\(primaryRippleToken)")
        }

        if !accessibilityReduceMotion && secondaryRippleActive {
          RecordRippleWave(
            token: secondaryRippleToken,
            diameter: 178,
            strokeColors: [
              Color(hex: "#B7B8FF", opacity: 0.92),
              Color(hex: "#F6CEE2", opacity: 0.92),
              Color.white.opacity(0.94),
              Color(hex: "#D7C7FF", opacity: 0.88),
            ],
            glowColors: [
              Color(hex: "#F7BFD9", opacity: 0.72),
              Color(hex: "#B0B4FF", opacity: 0.78),
              Color(hex: "#EBCBFF", opacity: 0.64),
            ],
            fillColor: Color(hex: "#FFF7FC", opacity: 0.06),
            duration: 0.78,
            maxScale: 2.08,
            lineWidth: 2.4,
            glowLineWidth: 20,
            startScale: 0.94,
            startOpacity: 0.80,
            endBlur: 5.6
          )
          .id("secondary-\(secondaryRippleToken)")
        }

        AmbientParticleLayer(
          orbs: visibleAmbientOrbs,
          isHighlighting: isHighlighting,
          isReacting: particleReactionActive
        )

        buttonCore
      }
      .frame(width: footprintSize, height: footprintSize)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(isTapSequenceRunning)
    .accessibilityLabel(Text("新しいMomentを作成"))
    .onAppear {
      restartBreathingAnimation()
    }
    .onChange(of: accessibilityReduceMotion) {
      restartBreathingAnimation()
    }
  }

  private var buttonCore: some View {
    ZStack {
      Image("RecordButtonSparkle")
        .renderingMode(.original)
        .resizable()
        .interpolation(.high)
        .antialiased(true)
        .aspectRatio(contentMode: .fit)
        .frame(width: coreDiameter, height: coreDiameter)

      Circle()
        .fill(
          LinearGradient(
            stops: [
              .init(color: Color.white.opacity(0.20), location: 0),
              .init(color: .clear, location: 0.56),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: coreDiameter, height: coreDiameter)
        .blur(radius: 8)
        .mask(Circle())
        .opacity(isHighlighting ? 0.68 : 0.54)
    }
    .frame(width: coreDiameter, height: coreDiameter)
    .scaleEffect(coreInteractionScale * breathingScale)
    .shadow(
      color: Color.white.opacity(isHighlighting ? 0.42 : 0.36), radius: isHighlighting ? 28 : 24,
      x: 0, y: 0
    )
    .shadow(
      color: Color(hex: "#F6D1E3", opacity: isHighlighting ? 0.28 : 0.20),
      radius: isHighlighting ? 34 : 30, x: 0, y: 3
    )
    .shadow(
      color: Color(hex: "#C8CCFF", opacity: isHighlighting ? 0.22 : 0.14),
      radius: isHighlighting ? 32 : 28, x: 0, y: 5
    )
    .animation(.easeOut(duration: 0.22), value: coreInteractionScale)
    .animation(.easeInOut(duration: 0.45), value: breathingScale)
    .animation(.easeOut(duration: 0.3), value: isHighlighting)
  }

  private func handleTap() {
    guard !isTapSequenceRunning else { return }
    triggerSequence()
  }

  private func restartBreathingAnimation() {
    breathingPhase = false
    reduceMotionBreathingPhase = false

    guard !isTapSequenceRunning else { return }

    if accessibilityReduceMotion {
      withAnimation(.easeInOut(duration: 4.4).repeatForever(autoreverses: true)) {
        reduceMotionBreathingPhase = true
      }
    } else {
      withAnimation(.easeInOut(duration: 4.4).repeatForever(autoreverses: true)) {
        breathingPhase = true
      }
    }
  }

  private func triggerSequence() {
    Task { @MainActor in
      animationSequence += 1
      let currentSequence = animationSequence

      isTapSequenceRunning = true
      breathingPhase = false
      reduceMotionBreathingPhase = false
      isHighlighting = true
      particleReactionActive = true

      withAnimation(.easeOut(duration: 0.12)) {
        coreInteractionScale = 0.975
      }

      try? await Task.sleep(for: .milliseconds(90))
      guard currentSequence == animationSequence else { return }

      withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
        coreInteractionScale = accessibilityReduceMotion ? 1.01 : 1.02
      }

      if accessibilityReduceMotion {
        try? await Task.sleep(for: .milliseconds(220))
        guard currentSequence == animationSequence else { return }

        withAnimation(.easeOut(duration: 0.22)) {
          coreInteractionScale = 1
          particleReactionActive = false
          isHighlighting = false
        }

        try? await Task.sleep(for: .milliseconds(120))
        guard currentSequence == animationSequence else { return }
        onSequenceCompleted()
        isTapSequenceRunning = false
        restartBreathingAnimation()
        return
      }

      primaryRippleActive = true
      primaryRippleToken += 1

      try? await Task.sleep(for: .milliseconds(120))
      guard currentSequence == animationSequence else { return }
      secondaryRippleActive = true
      secondaryRippleToken += 1

      try? await Task.sleep(for: .milliseconds(420))
      guard currentSequence == animationSequence else { return }
      withAnimation(.easeOut(duration: 0.28)) {
        particleReactionActive = false
      }

      try? await Task.sleep(for: .milliseconds(140))
      guard currentSequence == animationSequence else { return }
      primaryRippleActive = false
      withAnimation(.easeOut(duration: 0.18)) {
        coreInteractionScale = 1
      }

      try? await Task.sleep(for: .milliseconds(110))
      guard currentSequence == animationSequence else { return }
      secondaryRippleActive = false
      withAnimation(.easeOut(duration: 0.22)) {
        isHighlighting = false
      }

      try? await Task.sleep(for: .milliseconds(70))
      guard currentSequence == animationSequence else { return }
      onSequenceCompleted()
      isTapSequenceRunning = false
      restartBreathingAnimation()
    }
  }
}

private struct IdleHaloLayer: View {
  let isHighlighting: Bool
  let haloPulseOpacity: Double
  let blurBoost: CGFloat
  let scale: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.white.opacity(isHighlighting ? 0.16 : 0.12))
        .frame(width: 184, height: 184)
        .blur(radius: isHighlighting ? 26 + blurBoost : 22 + blurBoost)

      ZStack {
        Ellipse()
          .fill(Color(hex: "#F6D8EF", opacity: isHighlighting ? 0.44 : 0.34))
          .frame(width: 220, height: 212)
          .offset(x: -10, y: 9)
          .blur(radius: isHighlighting ? 36 + blurBoost : 31 + blurBoost)

        Ellipse()
          .fill(Color(hex: "#D7D5FF", opacity: isHighlighting ? 0.46 : 0.36))
          .frame(width: 226, height: 218)
          .offset(x: 12, y: -7)
          .blur(radius: isHighlighting ? 38 + blurBoost : 33 + blurBoost)

        Circle()
          .fill(
            AngularGradient(
              colors: [
                Color(hex: "#F7D6E8", opacity: isHighlighting ? 0.40 : 0.30),
                Color(hex: "#E5D5FF", opacity: isHighlighting ? 0.36 : 0.28),
                Color(hex: "#CCD6FF", opacity: isHighlighting ? 0.34 : 0.26),
                Color(hex: "#F4D8F4", opacity: isHighlighting ? 0.38 : 0.30),
                Color(hex: "#F7D6E8", opacity: isHighlighting ? 0.40 : 0.30),
              ],
              center: .center
            )
          )
          .frame(width: 238, height: 238)
          .blur(radius: isHighlighting ? 22 + blurBoost : 18 + blurBoost)
      }
      .mask {
        Circle()
          .stroke(lineWidth: 52)
          .frame(width: 194, height: 194)
          .blur(radius: 26)
      }
    }
    .compositingGroup()
    .opacity(haloPulseOpacity)
    .scaleEffect(scale)
    .animation(.easeInOut(duration: 0.45), value: scale)
    .animation(.easeOut(duration: 0.28), value: isHighlighting)
  }
}

private struct RecordRippleWave: View {
  let token: Int
  let diameter: CGFloat
  let strokeColors: [Color]
  let glowColors: [Color]
  let fillColor: Color
  let duration: Double
  let maxScale: CGFloat
  let lineWidth: CGFloat
  let glowLineWidth: CGFloat
  let startScale: CGFloat
  let startOpacity: Double
  let endBlur: CGFloat

  @State private var isAnimating = false

  var body: some View {
    Circle()
      .fill(fillColor)
      .overlay {
        Circle()
          .stroke(
            AngularGradient(
              colors: strokeColors,
              center: .center
            ),
            lineWidth: lineWidth
          )
      }
      .overlay {
        Circle()
          .stroke(
            AngularGradient(
              colors: glowColors,
              center: .center
            ),
            lineWidth: glowLineWidth
          )
          .blur(radius: 14)
      }
      .frame(width: diameter, height: diameter)
      .scaleEffect(isAnimating ? maxScale : startScale)
      .opacity(isAnimating ? 0 : startOpacity)
      .blur(radius: isAnimating ? endBlur : 1)
      .allowsHitTesting(false)
      .onAppear {
        guard token > 0 else { return }
        replay()
      }
      .onChange(of: token) {
        guard token > 0 else { return }
        replay()
      }
  }

  private func replay() {
    isAnimating = false
    DispatchQueue.main.async {
      withAnimation(.easeOut(duration: duration)) {
        isAnimating = true
      }
    }
  }
}

private struct AmbientOrbSpec: Identifiable {
  let id: Int
  let size: CGFloat
  let offset: CGPoint
  let reactionOffset: CGSize
  let color: Color
}

private struct AmbientParticleLayer: View {
  let orbs: [AmbientOrbSpec]
  let isHighlighting: Bool
  let isReacting: Bool

  var body: some View {
    ZStack {
      ForEach(orbs) { orb in
        AmbientOrb(
          spec: orb,
          isHighlighting: isHighlighting,
          isReacting: isReacting
        )
      }
    }
  }
}

private struct AmbientOrb: View {
  let spec: AmbientOrbSpec
  let isHighlighting: Bool
  let isReacting: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(spec.color.opacity(isReacting ? 0.15 : (isHighlighting ? 0.11 : 0.06)))
        .frame(width: spec.size * 2.4, height: spec.size * 2.4)
        .blur(radius: spec.size)

      Circle()
        .fill(spec.color.opacity(isReacting ? 0.42 : (isHighlighting ? 0.28 : 0.18)))
        .frame(width: spec.size, height: spec.size)

      Circle()
        .fill(Color.white.opacity(isReacting ? 0.44 : (isHighlighting ? 0.32 : 0.22)))
        .frame(width: spec.size * 0.24, height: spec.size * 0.24)
        .offset(x: -spec.size * 0.12, y: -spec.size * 0.12)
    }
    .scaleEffect(isReacting ? 1.1 : (isHighlighting ? 1.04 : 1))
    .opacity(isReacting ? 0.74 : (isHighlighting ? 0.56 : 0.72))
    .offset(
      x: spec.offset.x + (isReacting ? spec.reactionOffset.width : 0),
      y: spec.offset.y + (isReacting ? spec.reactionOffset.height : 0)
    )
    .animation(.easeOut(duration: 0.42), value: isReacting)
    .allowsHitTesting(false)
  }
}

#Preview {
  ZStack {
    AppBackgroundView(theme: .home)
      .ignoresSafeArea()

    RecordRippleButton(momentCount: 14)
  }
}
