import SwiftUI

struct LegacyMomentListRowModel: Identifiable {
    let id = UUID()
    let sourceTitle: String
    let episodeLabel: String
    let timestampLabel: String
    let quote: String
    let thumbnailColors: [Color]
}

struct MomentListRow: View {
    let moment: LegacyMomentListRowModel

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: moment.thumbnailColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(moment.sourceTitle)
                    Text(moment.episodeLabel)
                    Text(moment.timestampLabel)
                }
                .font(AppTypography.meta())
                .foregroundStyle(Color.textSecondary)

                Text(moment.quote)
                    .font(quoteFont)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: AppTheme.Spacing.sm)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appPrimarySoft)
        }
        .padding(12)
        .glassCard()
    }

    private var quoteFont: Font {
        moment.quote.containsJapaneseScript
            ? AppTypography.momentQuoteJapanese()
            : AppTypography.sceneDisplay()
    }
}

extension LegacyMomentListRowModel {
    static let preview: [LegacyMomentListRowModel] = [
        LegacyMomentListRowModel(
            sourceTitle: "作品名",
            episodeLabel: "EP.03",
            timestampLabel: "18:42",
            quote: "目が合った瞬間。胸がぎゅってなった。",
            thumbnailColors: [Color.surfaceLight, Color.appPrimaryTint]
        ),
        LegacyMomentListRowModel(
            sourceTitle: "作品名",
            episodeLabel: "EP.05",
            timestampLabel: "07:21",
            quote: "あの笑顔、反則すぎる...",
            thumbnailColors: [Color.surfaceWhite, Color.appPrimaryTint]
        )
    ]
}

private extension String {
    var containsJapaneseScript: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3040...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xFF66...0xFF9F:
                return true
            default:
                return false
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackgroundView(theme: .home)
            .ignoresSafeArea()

        MomentListRow(moment: .preview[0])
            .padding()
    }
}
