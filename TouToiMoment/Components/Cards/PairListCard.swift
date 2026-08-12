import SwiftUI

struct PairListCard: View {
    let pair: PairListCardModel
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    var showsFavoriteControls = true

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            pairMarker

            VStack(alignment: .leading, spacing: 2) {
                Text(pair.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                if !pair.nickname.isEmpty {
                    Text(pair.nickname)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: AppTheme.Spacing.sm)

            if showsFavoriteControls {
                momentCountPill

                Button(action: onToggleFavorite) {
                    FavoriteHeartIcon(isFilled: pair.isFavorite)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppStrings.pairsFavoriteToggleLabel(name: pair.displayName))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appPrimarySoft)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, minHeight: 105)
        .glassCard(cornerRadius: 20, fillOpacity: 0.40)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityAddTraits(.isButton)
    }

    private var pairMarker: some View {
        VStack(spacing: 7) {
            Circle()
                .fill(pair.leadingColor)
                .frame(width: 10, height: 10)
                .overlay {
                    Circle().stroke(Color.black.opacity(0.16), lineWidth: 0.75)
                }

            if let trailingColor = pair.trailingColor {
                Circle()
                    .fill(trailingColor)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.16), lineWidth: 0.75)
                    }
            }
        }
        .frame(width: 20)
    }

    private var momentCountPill: some View {
        HStack(spacing: 4) {
            MomentSparkleIcon(color: .white, width: 9, height: 13)

            Text("\(pair.momentCount)")
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .frame(minWidth: 45, minHeight: 23)
        .background(
            Capsule(style: .continuous)
                .fill(Color.appPrimary)
        )
    }

}

#Preview {
    ZStack {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        PairListCard(
            pair: PairListPreviewData.pairs[0],
            onTap: {},
            onToggleFavorite: {}
        )
            .padding()
    }
}
