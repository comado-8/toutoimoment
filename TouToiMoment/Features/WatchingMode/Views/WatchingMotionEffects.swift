import SwiftUI

struct ReactionFlightOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let events: [ReactionFlightEvent]

    var body: some View {
        if !events.isEmpty {
            TimelineView(.animation(minimumInterval: 1 / 30, paused: events.isEmpty)) { timeline in
                Canvas { context, _ in
                    for event in events {
                        draw(
                            event,
                            at: timeline.date,
                            in: &context
                        )
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func draw(
        _ event: ReactionFlightEvent,
        at date: Date,
        in context: inout GraphicsContext
    ) {
        let elapsed = max(0, date.timeIntervalSince(event.startedAt))
        let progress = min(1, elapsed / event.duration)
        guard progress < 1 else { return }

        let metrics = reduceMotion
            ? reducedMotionMetrics(for: event, progress: progress)
            : flightMetrics(for: event, progress: progress)
        let emoji = context.resolve(
            Text(event.emoji)
                .font(.system(size: 32))
        )

        context.drawLayer { layer in
            layer.opacity = metrics.opacity
            layer.translateBy(x: metrics.position.x, y: metrics.position.y)
            layer.scaleBy(x: metrics.scale, y: metrics.scale)
            layer.draw(emoji, at: .zero, anchor: .center)
        }
    }

    private func flightMetrics(
        for event: ReactionFlightEvent,
        progress: Double
    ) -> ReactionFlightMetrics {
        let path = ReactionFlightPath.paths[event.lane % ReactionFlightPath.paths.count]
        let easedProgress = 1 - pow(1 - progress, 2)
        let arcEnvelope = sin(.pi * progress)
        let sway = sin((progress * 2 * .pi) + Double(event.lane) * 0.72)
            * Double(path.sway)
            * arcEnvelope
        let x = event.origin.x + (path.drift * easedProgress) + CGFloat(sway)
        let y = event.origin.y - (path.rise * easedProgress)

        let opacity: Double
        if progress < 0.1 {
            opacity = progress / 0.1
        } else if progress > 0.7 {
            opacity = max(0, (1 - progress) / 0.3)
        } else {
            opacity = 1
        }

        let scale: CGFloat
        if progress < 0.2 {
            scale = 0.72 + CGFloat(progress / 0.2) * 0.36
        } else {
            scale = 1.08 - CGFloat((progress - 0.2) / 0.8) * 0.16
        }

        return ReactionFlightMetrics(
            position: CGPoint(x: x, y: y),
            opacity: opacity,
            scale: scale
        )
    }

    private func reducedMotionMetrics(
        for event: ReactionFlightEvent,
        progress: Double
    ) -> ReactionFlightMetrics {
        let opacity = sin(.pi * progress)
        return ReactionFlightMetrics(
            position: CGPoint(x: event.origin.x, y: event.origin.y - 8),
            opacity: opacity,
            scale: 1
        )
    }
}

struct PlaybackMotionBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let phase: WatchingPlaybackPhase
    let elapsedTime: (Date) -> TimeInterval

    private var isMoving: Bool {
        phase == .running && !reduceMotion
    }

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1 / 20,
                paused: !isMoving
            )
        ) { timeline in
            Canvas { context, size in
                drawTrack(
                    in: &context,
                    size: size,
                    elapsed: elapsedTime(timeline.date)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .opacity(phase.hasStarted ? 1 : 0)
        .animation(.easeOut(duration: 0.35), value: phase.hasStarted)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawTrack(
        in context: inout GraphicsContext,
        size: CGSize,
        elapsed: TimeInterval
    ) {
        guard phase.hasStarted else { return }

        let centerY = size.height / 2
        let centerEnergy = drawSineRibbons(
            in: &context,
            size: size,
            elapsed: elapsed
        )
        drawPlayhead(
            in: &context,
            center: CGPoint(x: size.width / 2, y: centerY),
            energy: centerEnergy
        )
    }

    private func drawSineRibbons(
        in context: inout GraphicsContext,
        size: CGSize,
        elapsed: TimeInterval
    ) -> Double {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let motionOpacity = phase == .running ? 1.0 : 0.62
        let highlight = activeHighlight(elapsed: elapsed, width: size.width)
        let ribbons = [
            SineRibbon(
                amplitude: 10.5,
                wavelength: 142,
                speed: 24,
                envelopeLength: 330,
                envelopeSpeed: 5.5,
                phaseOffset: 0.15,
                opacity: 0.42,
                lineWidth: 1.45
            ),
            SineRibbon(
                amplitude: 7.2,
                wavelength: 92,
                speed: 32,
                envelopeLength: 270,
                envelopeSpeed: 7,
                phaseOffset: 2.1,
                opacity: 0.28,
                lineWidth: 1.15
            ),
            SineRibbon(
                amplitude: 4.6,
                wavelength: 210,
                speed: 18,
                envelopeLength: 410,
                envelopeSpeed: 4,
                phaseOffset: 4.35,
                opacity: 0.20,
                lineWidth: 1
            ),
        ]
        var centerEnergy = 0.0

        for (index, ribbon) in ribbons.enumerated() {
            let path = sinePath(
                size: size,
                centerY: centerY,
                elapsed: elapsed,
                ribbon: ribbon
            )
            let shader = GraphicsContext.Shading.linearGradient(
                Gradient(stops: [
                    .init(color: Color.appPrimarySoft.opacity(ribbon.opacity * motionOpacity * 0.72), location: 0),
                    .init(color: Color.appPrimarySoft.opacity(ribbon.opacity * motionOpacity), location: 0.5),
                    .init(color: Color.appPrimarySoft.opacity(ribbon.opacity * motionOpacity * 0.68), location: 1),
                ]),
                startPoint: CGPoint(x: 0, y: centerY),
                endPoint: CGPoint(x: size.width, y: centerY)
            )
            context.stroke(
                path,
                with: shader,
                style: StrokeStyle(lineWidth: ribbon.lineWidth, lineCap: .round, lineJoin: .round)
            )

            if let highlight, highlight.ribbonIndex == index {
                drawHighlight(
                    highlight,
                    path: path,
                    ribbon: ribbon,
                    motionOpacity: motionOpacity,
                    size: size,
                    in: &context
                )
            }

            centerEnergy += Double(
                normalizedAmplitude(
                    x: centerX,
                    elapsed: elapsed,
                    ribbon: ribbon
                )
            ) / Double(ribbons.count)
        }

        return centerEnergy
    }

    private func sinePath(
        size: CGSize,
        centerY: CGFloat,
        elapsed: TimeInterval,
        ribbon: SineRibbon
    ) -> Path {
        var path = Path()
        let sampleStep: CGFloat = 2
        let centerX = size.width / 2
        var x: CGFloat = 0
        var didInsertCenter = false

        while x <= size.width + sampleStep {
            if !didInsertCenter, x > centerX {
                path.addLine(to: CGPoint(x: centerX, y: centerY))
                didInsertCenter = true
            }

            let y = waveY(
                x: x,
                centerX: centerX,
                centerY: centerY,
                elapsed: elapsed,
                ribbon: ribbon
            )

            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += sampleStep
        }
        return path
    }

    private func waveY(
        x: CGFloat,
        centerX: CGFloat,
        centerY: CGFloat,
        elapsed: TimeInterval,
        ribbon: SineRibbon
    ) -> CGFloat {
        let elapsedDistance = CGFloat(elapsed) * ribbon.speed
        let travellingX = x + elapsedDistance
        let wavePhase = ((travellingX / ribbon.wavelength) * 2 * .pi)
            + ribbon.phaseOffset
        let amplitude = ribbon.amplitude
            * normalizedAmplitude(x: x, elapsed: elapsed, ribbon: ribbon)
        let rawOffset = sin(wavePhase) * amplitude

        let centerTravellingX = centerX + elapsedDistance
        let centerPhase = ((centerTravellingX / ribbon.wavelength) * 2 * .pi)
            + ribbon.phaseOffset
        let centerAmplitude = ribbon.amplitude
            * normalizedAmplitude(x: centerX, elapsed: elapsed, ribbon: ribbon)
        let centerOffset = sin(centerPhase) * centerAmplitude
        let normalizedDistance = (x - centerX) / 38
        let nodeInfluence = exp(-(normalizedDistance * normalizedDistance))

        return centerY + rawOffset - (centerOffset * nodeInfluence)
    }

    private func normalizedAmplitude(
        x: CGFloat,
        elapsed: TimeInterval,
        ribbon: SineRibbon
    ) -> CGFloat {
        let travellingX = x + (CGFloat(elapsed) * ribbon.envelopeSpeed)
        let envelopePhase = ((travellingX / ribbon.envelopeLength) * 2 * .pi)
            + (ribbon.phaseOffset * 0.63)
        return 0.64 + (0.36 * ((sin(envelopePhase) + 1) / 2))
    }

    private func activeHighlight(
        elapsed: TimeInterval,
        width: CGFloat
    ) -> SineHighlight? {
        let patterns = [
            HighlightPattern(interval: 3.4, duration: 0.98, position: 0.94, travel: 220, width: 72, ribbonIndex: 0, accent: .blush),
            HighlightPattern(interval: 4.5, duration: 1.12, position: 0.82, travel: 190, width: 82, ribbonIndex: 1, accent: .periwinkle),
            HighlightPattern(interval: 2.9, duration: 0.90, position: 0.68, travel: 160, width: 68, ribbonIndex: 2, accent: .blush),
            HighlightPattern(interval: 4.1, duration: 1.08, position: 0.96, travel: 250, width: 80, ribbonIndex: 0, accent: .periwinkle),
            HighlightPattern(interval: 3.6, duration: 0.96, position: 0.76, travel: 190, width: 72, ribbonIndex: 1, accent: .blush),
            HighlightPattern(interval: 4.8, duration: 1.16, position: 0.90, travel: 230, width: 86, ribbonIndex: 2, accent: .periwinkle),
        ]
        let totalDuration = patterns.reduce(0) { $0 + $1.interval }
        var cursor = (elapsed + 1.45).truncatingRemainder(dividingBy: totalDuration)

        for pattern in patterns {
            defer { cursor -= pattern.interval }
            guard cursor < pattern.interval else { continue }
            guard cursor < pattern.duration else { return nil }

            let progress = cursor / pattern.duration
            let fade = highlightOpacity(at: progress)
            let startX = width * pattern.position
            let travel = CGFloat(progress) * pattern.travel
            return SineHighlight(
                centerX: min(max(pattern.width / 2, startX - travel), width - (pattern.width / 2)),
                width: pattern.width,
                opacity: fade,
                ribbonIndex: pattern.ribbonIndex,
                accent: pattern.accent
            )
        }
        return nil
    }

    private func highlightOpacity(at progress: Double) -> Double {
        if progress < 0.14 {
            return progress / 0.14
        }
        if progress < 0.68 {
            return 1
        }
        return max(0, (1 - progress) / 0.32)
    }

    private func drawHighlight(
        _ highlight: SineHighlight,
        path: Path,
        ribbon: SineRibbon,
        motionOpacity: Double,
        size: CGSize,
        in context: inout GraphicsContext
    ) {
        let clipRect = CGRect(
            x: highlight.centerX - (highlight.width / 2),
            y: 0,
            width: highlight.width,
            height: size.height
        )
        let accentColor = color(for: highlight.accent)
        let coreColor = coreColor(for: highlight.accent)
        let expandedClip = clipRect.insetBy(dx: -20, dy: 0)
        let outerGlowGradient = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: accentColor.opacity(0), location: 0),
                .init(color: accentColor.opacity(0.12 * highlight.opacity * motionOpacity), location: 0.10),
                .init(color: accentColor.opacity(0.48 * highlight.opacity * motionOpacity), location: 0.28),
                .init(color: accentColor.opacity(0.48 * highlight.opacity * motionOpacity), location: 0.66),
                .init(color: accentColor.opacity(0.10 * highlight.opacity * motionOpacity), location: 0.90),
                .init(color: accentColor.opacity(0), location: 1),
            ]),
            startPoint: CGPoint(x: expandedClip.minX, y: size.height / 2),
            endPoint: CGPoint(x: expandedClip.maxX, y: size.height / 2)
        )
        let innerGlowGradient = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: coreColor.opacity(0), location: 0),
                .init(color: coreColor.opacity(0.14 * highlight.opacity * motionOpacity), location: 0.14),
                .init(color: coreColor.opacity(0.58 * highlight.opacity * motionOpacity), location: 0.32),
                .init(color: coreColor.opacity(0.58 * highlight.opacity * motionOpacity), location: 0.62),
                .init(color: coreColor.opacity(0.12 * highlight.opacity * motionOpacity), location: 0.86),
                .init(color: coreColor.opacity(0), location: 1),
            ]),
            startPoint: CGPoint(x: expandedClip.minX, y: size.height / 2),
            endPoint: CGPoint(x: expandedClip.maxX, y: size.height / 2)
        )

        context.drawLayer { outerGlow in
            outerGlow.clip(to: Path(expandedClip))
            outerGlow.addFilter(.blur(radius: 5.4))
            outerGlow.stroke(
                path,
                with: outerGlowGradient,
                style: StrokeStyle(lineWidth: ribbon.lineWidth + 7, lineCap: .round)
            )
        }
        context.drawLayer { innerGlow in
            innerGlow.clip(to: Path(expandedClip))
            innerGlow.addFilter(.blur(radius: 2.1))
            innerGlow.stroke(
                path,
                with: innerGlowGradient,
                style: StrokeStyle(lineWidth: ribbon.lineWidth + 3.2, lineCap: .round)
            )
        }
        context.drawLayer { accent in
            accent.clip(to: Path(clipRect))
            accent.stroke(
                path,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: accentColor.opacity(0), location: 0),
                        .init(color: coreColor.opacity(0.90 * highlight.opacity * motionOpacity), location: 0.12),
                        .init(color: Color.white.opacity(highlight.opacity * motionOpacity), location: 0.23),
                        .init(color: coreColor.opacity(0.96 * highlight.opacity * motionOpacity), location: 0.34),
                        .init(color: accentColor.opacity(0.72 * highlight.opacity * motionOpacity), location: 0.60),
                        .init(color: accentColor.opacity(0.22 * highlight.opacity * motionOpacity), location: 0.82),
                        .init(color: accentColor.opacity(0), location: 1),
                    ]),
                    startPoint: CGPoint(x: clipRect.minX, y: size.height / 2),
                    endPoint: CGPoint(x: clipRect.maxX, y: size.height / 2)
                ),
                style: StrokeStyle(lineWidth: ribbon.lineWidth + 0.9, lineCap: .round)
            )
        }
    }

    private func color(for accent: HighlightAccent) -> Color {
        switch accent {
        case .blush:
            .appBlobBlush
        case .periwinkle:
            .appBlobPeriwinkle
        }
    }

    private func coreColor(for accent: HighlightAccent) -> Color {
        switch accent {
        case .blush:
            .appAccent
        case .periwinkle:
            .appPrimaryTint
        }
    }

    private func drawPlayhead(
        in context: inout GraphicsContext,
        center: CGPoint,
        energy: Double
    ) {
        let activeOpacity = phase == .running ? 1.0 : 0.68
        let haloRadius = 7.5 + (CGFloat(energy) * 2.5)
        context.stroke(
            Path(
                ellipseIn: CGRect(
                    x: center.x - haloRadius,
                    y: center.y - haloRadius,
                    width: haloRadius * 2,
                    height: haloRadius * 2
                )
            ),
            with: .color(Color.appPrimarySoft.opacity(0.18 * activeOpacity)),
            lineWidth: 1
        )

        let dotRadius: CGFloat = 3.8
        context.fill(
            Path(
                ellipseIn: CGRect(
                    x: center.x - dotRadius,
                    y: center.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
            ),
            with: .color(Color.appPrimarySoft.opacity(activeOpacity))
        )
    }

    private struct SineRibbon {
        let amplitude: CGFloat
        let wavelength: CGFloat
        let speed: CGFloat
        let envelopeLength: CGFloat
        let envelopeSpeed: CGFloat
        let phaseOffset: CGFloat
        let opacity: Double
        let lineWidth: CGFloat
    }

    private struct HighlightPattern {
        let interval: TimeInterval
        let duration: TimeInterval
        let position: CGFloat
        let travel: CGFloat
        let width: CGFloat
        let ribbonIndex: Int
        let accent: HighlightAccent
    }

    private struct SineHighlight {
        let centerX: CGFloat
        let width: CGFloat
        let opacity: Double
        let ribbonIndex: Int
        let accent: HighlightAccent
    }

    private enum HighlightAccent {
        case blush
        case periwinkle
    }
}

private struct ReactionFlightMetrics {
    let position: CGPoint
    let opacity: Double
    let scale: CGFloat
}
