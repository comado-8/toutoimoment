import SwiftUI

struct WatchHistoryLiveLogExportCanvas: View {
    let document: WatchHistoryLiveLogExportDocument
    let page: WatchHistoryLiveLogExportPage
    let totalPageCount: Int
    let canvasWidth: CGFloat
    let minimumHeight: CGFloat

    private let historyFormatter = EpisodeWatchHistoryFormatter()
    private let eventFormatter = WatchingSessionEventFormatter()

    private var isFirstPage: Bool { page.index == 0 }
    private var horizontalPadding: CGFloat { canvasWidth > 400 ? 36 : 24 }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            if isFirstPage {
                WatchHistorySessionSummaryCard(
                    session: document.session,
                    dateTimeText: historyFormatter.dateTimeText(
                        for: document.session.startedAt
                    )
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(liveLogTitle)
                    .font(.custom("Geist-SemiBold", size: 18, relativeTo: .headline))
                    .foregroundStyle(Color.textPrimary)

                if isFirstPage {
                    Text(AppStrings.watchHistoryDetailLiveLogSubtitle)
                        .font(.custom("Geist-Medium", size: 13, relativeTo: .footnote))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(page.events.enumerated()), id: \.element.id) { index, event in
                    WatchingSessionEventRow(
                        event: event,
                        timeText: eventFormatter.elapsedTimeText(
                            seconds: event.elapsedSeconds
                        ),
                        showsLine: index < page.events.count - 1
                            || page.index < totalPageCount - 1
                    )
                }
            }

            Spacer(minLength: 0)

            Text(AppStrings.momentShareCreatedWith)
                .font(.custom("Geist-Medium", size: 9, relativeTo: .caption2))
                .foregroundStyle(Color.textSecondary.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isFirstPage ? 30 : 24)
        .padding(.bottom, 28)
        .frame(width: canvasWidth, alignment: .topLeading)
        .frame(minHeight: minimumHeight, alignment: .topLeading)
        .shareCardSurface(cornerRadius: WatchHistoryLiveLogExportRenderer.cornerRadius)
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

    private var liveLogTitle: String {
        guard totalPageCount > 1, !isFirstPage else {
            return AppStrings.watchHistoryDetailLiveLog
        }
        return "\(AppStrings.watchHistoryDetailLiveLog) \(page.index + 1)/\(totalPageCount)"
    }

    private var continuationEpisodeName: String {
        if let displayTitle = document.episodeDisplayTitle {
            return "\(document.locatorDisplayName) · \(displayTitle)"
        }
        return document.locatorDisplayName
    }
}
