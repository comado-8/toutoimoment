import SwiftUI

struct NewMomentFlowHeader: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(AppStrings.newMomentStep1ScreenTitle)
                .font(.custom("InstrumentSerif-Regular", size: 26))
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 12)

            Button(action: onDismiss) {
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
}

struct NewMomentProgressDots: View {
    let activeCount: Int
    let accessibilityLabel: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < activeCount ? Color.appPrimary : Color(hex: "#D7D4EA"))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct NewMomentCompletedSummary: View {
    let title: String
    let summary: String
    var width: CGFloat = 342
    var onTap: (() -> Void)? = nil

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                content(showAccessory: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppStrings.newMomentEditCompletedStepHint)
        } else {
            content(showAccessory: false)
        }
    }

    private func content(showAccessory: Bool) -> some View {
        HStack(spacing: 8) {
            textContent

            if showAccessory {
                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "#8E91B0", opacity: 0.70))
            }
        }
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.appPrimary)

            Text(summary)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color(hex: "#2D2D4E", opacity: 0.55))
                .lineLimit(1)
        }
    }
}

struct NewMomentFlowSeparator: View {
    var width: CGFloat = 342

    var body: some View {
        Rectangle()
            .fill(Color(hex: "#C4BCE4", opacity: 0.35))
            .frame(width: width, height: 1)
    }
}

struct NewMomentInactiveSummaryRow: View {
    let title: String
    var width: CGFloat = 342

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Color(hex: "#9B9EC4"))
            .frame(width: width, alignment: .leading)
            .frame(height: 22, alignment: .topLeading)
    }
}

struct NewMomentGlassFieldBackground: View {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 14) {
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.80))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color(hex: "#D6D1F2", opacity: 0.28), lineWidth: 1)
            }
            .shadow(color: Color(hex: "#6652CC", opacity: 0.06), radius: 4, x: 0, y: 1)
    }
}

struct NewMomentDiscardConfirmationOverlay: View {
    let onKeepEditing: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture(perform: onKeepEditing)

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text(AppStrings.newMomentDiscardTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)

                    Text(AppStrings.newMomentDiscardMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: "#5F6178"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: 10) {
                    Button(action: onKeepEditing) {
                        Text(AppStrings.newMomentDiscardKeepEditing)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.appPrimary)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onDiscard) {
                        Text(AppStrings.newMomentDiscardConfirm)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: "#6E7482"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 18)
            .frame(width: 320)
            .background(discardCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color(hex: "#6652CC", opacity: 0.14), radius: 24, x: 0, y: 14)
        }
        .accessibilityElement(children: .contain)
    }

    private var discardCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.88),
                            Color(hex: "#F8F6FF", opacity: 0.80),
                            Color(hex: "#EEF4FF", opacity: 0.74),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.74), lineWidth: 1)
        }
    }
}
