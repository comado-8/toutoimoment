import SwiftUI

struct PrimaryCTAButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                MomentSparkleIcon(color: .white, width: 13, height: 21)

                Text(title)
                    .font(AppTypography.cta())
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appPrimary.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.appPrimary.opacity(0.24), radius: 14, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}
