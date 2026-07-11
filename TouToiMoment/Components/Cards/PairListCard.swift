import SwiftUI

struct LegacyPairListRowModel: Identifiable {
    let id = UUID()
    let name: String
    let favoriteCount: Int
    let leadingDot: Color
    let trailingDot: Color
}

struct PairListCard: View {
    let pair: LegacyPairListRowModel

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(spacing: 5) {
                Circle()
                    .fill(pair.leadingDot)
                    .frame(width: 10, height: 10)

                Circle()
                    .fill(pair.trailingDot)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 20)

            Text(pair.name)
                .font(AppTypography.bodyStrong())
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: AppTheme.Spacing.sm)

            HStack(spacing: 5) {
                MomentSparkleIcon(color: .white, width: 9, height: 13)
                Text("\(pair.favoriteCount)")
                    .font(AppTypography.meta())
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimarySoft, Color.appPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appPrimarySoft)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, 16)
        .glassCard()
    }
}

extension LegacyPairListRowModel {
    static let preview: [LegacyPairListRowModel] = [
        LegacyPairListRowModel(
            name: "きりあす",
            favoriteCount: 12,
            leadingDot: Color(hex: "#243979"),
            trailingDot: Color(hex: "#D3522E")
        ),
        LegacyPairListRowModel(
            name: "ロイヨル",
            favoriteCount: 12,
            leadingDot: Color(hex: "#243979"),
            trailingDot: Color(hex: "#D3522E")
        )
    ]
}

#Preview {
    ZStack {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        PairListCard(pair: .preview[0])
            .padding()
    }
}
