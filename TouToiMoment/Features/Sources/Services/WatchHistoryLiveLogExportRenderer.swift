import SwiftUI
import UIKit

@MainActor
enum WatchHistoryLiveLogExportRenderer {
    static let imageWidth = EpisodeTimelineExportRenderer.imageWidth
    static let minimumImageHeight = EpisodeTimelineExportRenderer.minimumImageHeight
    static let imageScale = EpisodeTimelineExportRenderer.imageScale
    static let maximumPixelHeight = EpisodeTimelineExportRenderer.maximumPixelHeight
    static let cornerRadius = EpisodeTimelineExportRenderer.cornerRadius
    static let pdfPageSize = EpisodeTimelineExportRenderer.pdfPageSize
    static let pdfRasterScale = EpisodeTimelineExportRenderer.pdfRasterScale

    static var maximumImageHeight: CGFloat {
        maximumPixelHeight / imageScale
    }

    static func imagePages(
        for document: WatchHistoryLiveLogExportDocument
    ) -> [WatchHistoryLiveLogExportPage] {
        paginate(
            document: document,
            canvasWidth: imageWidth,
            maximumHeight: maximumImageHeight
        )
    }

    static func pdfPages(
        for document: WatchHistoryLiveLogExportDocument
    ) -> [WatchHistoryLiveLogExportPage] {
        paginate(
            document: document,
            canvasWidth: pdfPageSize.width,
            maximumHeight: pdfPageSize.height
        )
    }

    static func image(
        for document: WatchHistoryLiveLogExportDocument,
        page: WatchHistoryLiveLogExportPage,
        totalPageCount: Int,
        scale: CGFloat = 3
    ) -> UIImage? {
        let naturalHeight = measuredHeight(
            document: document,
            page: page,
            totalPageCount: totalPageCount,
            canvasWidth: imageWidth
        )
        let height = min(
            maximumImageHeight,
            max(minimumImageHeight, ceil(naturalHeight))
        )
        let renderer = ImageRenderer(
            content: WatchHistoryLiveLogExportCanvas(
                document: document,
                page: page,
                totalPageCount: totalPageCount,
                canvasWidth: imageWidth,
                minimumHeight: height
            )
            .frame(width: imageWidth, height: height, alignment: .top)
        )
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage
    }

    static func previewImage(
        for document: WatchHistoryLiveLogExportDocument,
        pages: [WatchHistoryLiveLogExportPage]
    ) -> UIImage? {
        guard let first = pages.first else { return nil }
        return image(
            for: document,
            page: first,
            totalPageCount: pages.count,
            scale: 1
        )
    }

    static func pdfData(
        for document: WatchHistoryLiveLogExportDocument,
        pages: [WatchHistoryLiveLogExportPage]? = nil
    ) -> Data? {
        let pages = pages ?? pdfPages(for: document)
        guard !pages.isEmpty else { return nil }

        let bounds = CGRect(origin: .zero, size: pdfPageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        var renderingFailed = false
        let data = renderer.pdfData { context in
            for page in pages {
                guard let pageImage = pdfPageImage(
                    for: document,
                    page: page,
                    totalPageCount: pages.count
                ) else {
                    renderingFailed = true
                    return
                }

                context.beginPage()
                pageImage.draw(in: bounds)
            }
        }
        return renderingFailed ? nil : data
    }

    static func measuredHeight(
        document: WatchHistoryLiveLogExportDocument,
        page: WatchHistoryLiveLogExportPage,
        totalPageCount: Int,
        canvasWidth: CGFloat
    ) -> CGFloat {
        let controller = UIHostingController(
            rootView: WatchHistoryLiveLogExportCanvas(
                document: document,
                page: page,
                totalPageCount: totalPageCount,
                canvasWidth: canvasWidth,
                minimumHeight: 0
            )
            .fixedSize(horizontal: false, vertical: true)
        )
        controller.view.backgroundColor = .clear
        return controller.sizeThatFits(
            in: CGSize(width: canvasWidth, height: 100_000)
        ).height
    }

    private static func pdfPageImage(
        for document: WatchHistoryLiveLogExportDocument,
        page: WatchHistoryLiveLogExportPage,
        totalPageCount: Int
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: WatchHistoryLiveLogExportCanvas(
                document: document,
                page: page,
                totalPageCount: totalPageCount,
                canvasWidth: pdfPageSize.width,
                minimumHeight: pdfPageSize.height
            )
            .frame(
                width: pdfPageSize.width,
                height: pdfPageSize.height,
                alignment: .top
            )
        )
        renderer.scale = pdfRasterScale
        renderer.isOpaque = false
        return renderer.uiImage
    }

    private static func paginate(
        document: WatchHistoryLiveLogExportDocument,
        canvasWidth: CGFloat,
        maximumHeight: CGFloat
    ) -> [WatchHistoryLiveLogExportPage] {
        guard !document.session.events.isEmpty else { return [] }

        var result: [WatchHistoryLiveLogExportPage] = []
        var current: [WatchingSessionEvent] = []

        func page(
            _ events: [WatchingSessionEvent],
            index: Int
        ) -> WatchHistoryLiveLogExportPage {
            WatchHistoryLiveLogExportPage(index: index, events: events)
        }

        func fits(_ events: [WatchingSessionEvent], index: Int) -> Bool {
            measuredHeight(
                document: document,
                page: page(events, index: index),
                totalPageCount: 999,
                canvasWidth: canvasWidth
            ) <= maximumHeight
        }

        for event in document.session.events {
            let candidate = current + [event]
            if fits(candidate, index: result.count) {
                current = candidate
                continue
            }

            if !current.isEmpty {
                result.append(page(current, index: result.count))
                current = []
            }

            if fits([event], index: result.count) {
                current = [event]
            } else {
                for fragment in splitOversized(
                    event,
                    document: document,
                    startIndex: result.count,
                    canvasWidth: canvasWidth,
                    maximumHeight: maximumHeight
                ) {
                    result.append(page([fragment], index: result.count))
                }
            }
        }

        if !current.isEmpty {
            result.append(page(current, index: result.count))
        }
        return result
    }

    private static func splitOversized(
        _ event: WatchingSessionEvent,
        document: WatchHistoryLiveLogExportDocument,
        startIndex: Int,
        canvasWidth: CGFloat,
        maximumHeight: CGFloat
    ) -> [WatchingSessionEvent] {
        var remaining = Array(eventText(event))
        var fragments: [WatchingSessionEvent] = []

        while !remaining.isEmpty {
            let pageIndex = startIndex + fragments.count
            let whole = fragment(
                event,
                text: String(remaining),
                index: fragments.count
            )
            if measuredHeight(
                document: document,
                page: WatchHistoryLiveLogExportPage(
                    index: pageIndex,
                    events: [whole]
                ),
                totalPageCount: 999,
                canvasWidth: canvasWidth
            ) <= maximumHeight {
                fragments.append(whole)
                break
            }

            var low = 1
            var high = max(1, remaining.count - 1)
            var best = 1
            while low <= high {
                let midpoint = (low + high) / 2
                let candidate = fragment(
                    event,
                    text: String(remaining.prefix(midpoint)),
                    index: fragments.count
                )
                let height = measuredHeight(
                    document: document,
                    page: WatchHistoryLiveLogExportPage(
                        index: pageIndex,
                        events: [candidate]
                    ),
                    totalPageCount: 999,
                    canvasWidth: canvasWidth
                )
                if height <= maximumHeight {
                    best = midpoint
                    low = midpoint + 1
                } else {
                    high = midpoint - 1
                }
            }

            fragments.append(
                fragment(
                    event,
                    text: String(remaining.prefix(best)),
                    index: fragments.count
                )
            )
            remaining.removeFirst(best)
        }
        return fragments
    }

    private static func eventText(_ event: WatchingSessionEvent) -> String {
        switch event.kind {
        case let .reaction(reaction):
            reaction.count > 1
                ? "\(reaction.displayText) ×\(reaction.count)"
                : reaction.displayText
        case let .voiceNote(text):
            text
        case let .liveHeartScream(_, comment, _):
            comment
        }
    }

    private static func fragment(
        _ event: WatchingSessionEvent,
        text: String,
        index: Int
    ) -> WatchingSessionEvent {
        let kind: WatchingSessionEvent.Kind
        switch event.kind {
        case let .reaction(reaction):
            kind = .reaction(
                WatchingSessionReaction(
                    reactionID: reaction.reactionID,
                    displayText: text
                )
            )
        case .voiceNote:
            kind = .voiceNote(text)
        case let .liveHeartScream(momentID, _, pairID):
            kind = .liveHeartScream(
                momentID: momentID,
                comment: text,
                pairID: pairID
            )
        }
        return WatchingSessionEvent(
            id: "\(event.id)-part-\(index)",
            elapsedSeconds: event.elapsedSeconds,
            kind: kind
        )
    }
}
