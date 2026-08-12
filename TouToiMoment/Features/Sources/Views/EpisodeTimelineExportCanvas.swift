import SwiftUI

struct EpisodeTimelineExportCanvas: View {
    let document: EpisodeTimelineExportDocument
    let page: EpisodeTimelineExportPage
    let totalPageCount: Int
    let canvasWidth: CGFloat
    let minimumHeight: CGFloat

    private var isFirstPage: Bool { page.index == 0 }
    private var horizontalPadding: CGFloat { canvasWidth > 400 ? 36 : 24 }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            Text(
                totalPageCount > 1 && !isFirstPage
                    ? "\(AppStrings.episodeDetailTimeline) \(page.index + 1)/\(totalPageCount)"
                    : AppStrings.episodeDetailTimeline
            )
            .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
            .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(page.moments.enumerated()), id: \.element.id) { index, moment in
                    EpisodeMomentTimelineRow(
                        moment: moment,
                        showsLine: index < page.moments.count - 1
                            || page.index < totalPageCount - 1
                    )
                }
            }

            Spacer(minLength: 0)

            Text(AppStrings.momentShareCreatedWith)
                .font(.custom("Geist-Medium", size: 9, relativeTo: .caption2))
                .foregroundStyle(Color.textSecondary.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("episode_timeline_export.credit")
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isFirstPage ? 34 : 26)
        .padding(.bottom, 30)
        .frame(width: canvasWidth, alignment: .topLeading)
        .frame(minHeight: minimumHeight, alignment: .topLeading)
        .shareCardSurface(cornerRadius: EpisodeTimelineExportRenderer.cornerRadius)
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private var header: some View {
        if isFirstPage {
            VStack(alignment: .leading, spacing: 5) {
                Text(document.locatorDisplayName.uppercased())
                    .font(.custom("Geist-Bold", size: 14, relativeTo: .caption))
                    .foregroundStyle(Color.appPrimary)

                if let displayTitle = document.episodeDisplayTitle {
                    Text(displayTitle)
                        .font(.custom("Geist-Bold", size: 22, relativeTo: .title2))
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(document.sourceName)
                    .font(.custom("Geist-Medium", size: 16, relativeTo: .body))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(document.sourceName)
                    .font(.custom("Geist-SemiBold", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(Color.textPrimary)

                Text(continuationEpisodeName)
                    .font(.custom("Geist-Medium", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var continuationEpisodeName: String {
        if let displayTitle = document.episodeDisplayTitle {
            return "\(document.locatorDisplayName) · \(displayTitle)"
        }
        return document.locatorDisplayName
    }
}
