import SwiftUI
import UIKit

@MainActor
enum EpisodeTimelineExportRenderer {
    static let imageWidth: CGFloat = 342
    static let minimumImageHeight: CGFloat = 612
    static let imageScale: CGFloat = 3
    static let maximumPixelHeight: CGFloat = 16_384
    static let cornerRadius: CGFloat = 28
    static let pdfPageSize = CGSize(width: 595.2, height: 841.8)
    static let pdfRasterScale: CGFloat = 2

    static var maximumImageHeight: CGFloat {
        maximumPixelHeight / imageScale
    }

    static func imagePages(
        for document: EpisodeTimelineExportDocument
    ) -> [EpisodeTimelineExportPage] {
        paginate(
            document: document,
            canvasWidth: imageWidth,
            maximumHeight: maximumImageHeight
        )
    }

    static func pdfPages(
        for document: EpisodeTimelineExportDocument
    ) -> [EpisodeTimelineExportPage] {
        paginate(
            document: document,
            canvasWidth: pdfPageSize.width,
            maximumHeight: pdfPageSize.height
        )
    }

    static func image(
        for document: EpisodeTimelineExportDocument,
        page: EpisodeTimelineExportPage,
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
            content: EpisodeTimelineExportCanvas(
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
        for document: EpisodeTimelineExportDocument,
        pages: [EpisodeTimelineExportPage]
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
        for document: EpisodeTimelineExportDocument,
        pages: [EpisodeTimelineExportPage]? = nil
    ) -> Data? {
        let pages = pages ?? pdfPages(for: document)
        guard !pages.isEmpty else { return nil }

        let bounds = CGRect(origin: .zero, size: pdfPageSize)
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)
        var renderingFailed = false
        let data = pdfRenderer.pdfData { pdfContext in
            for page in pages {
                guard let pageImage = pdfPageImage(
                    for: document,
                    page: page,
                    totalPageCount: pages.count
                ) else {
                    renderingFailed = true
                    return
                }

                pdfContext.beginPage()
                pageImage.draw(in: bounds)
            }
        }
        return renderingFailed ? nil : data
    }

    static func pdfPageImage(
        for document: EpisodeTimelineExportDocument,
        page: EpisodeTimelineExportPage,
        totalPageCount: Int
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: EpisodeTimelineExportCanvas(
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

    static func measuredHeight(
        document: EpisodeTimelineExportDocument,
        page: EpisodeTimelineExportPage,
        totalPageCount: Int,
        canvasWidth: CGFloat
    ) -> CGFloat {
        let controller = UIHostingController(
            rootView: EpisodeTimelineExportCanvas(
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

    private static func paginate(
        document: EpisodeTimelineExportDocument,
        canvasWidth: CGFloat,
        maximumHeight: CGFloat
    ) -> [EpisodeTimelineExportPage] {
        guard !document.moments.isEmpty else { return [] }

        var result: [EpisodeTimelineExportPage] = []
        var current: [EpisodeTimelineMoment] = []

        func page(_ moments: [EpisodeTimelineMoment], index: Int) -> EpisodeTimelineExportPage {
            EpisodeTimelineExportPage(index: index, moments: moments)
        }

        func fits(_ moments: [EpisodeTimelineMoment], index: Int) -> Bool {
            measuredHeight(
                document: document,
                page: page(moments, index: index),
                totalPageCount: 999,
                canvasWidth: canvasWidth
            ) <= maximumHeight
        }

        for moment in document.moments {
            let candidate = current + [moment]
            if fits(candidate, index: result.count) {
                current = candidate
                continue
            }

            if !current.isEmpty {
                result.append(page(current, index: result.count))
                current = []
            }

            if fits([moment], index: result.count) {
                current = [moment]
            } else {
                let fragments = splitOversized(
                    moment,
                    document: document,
                    startIndex: result.count,
                    canvasWidth: canvasWidth,
                    maximumHeight: maximumHeight
                )
                for fragment in fragments {
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
        _ moment: EpisodeTimelineMoment,
        document: EpisodeTimelineExportDocument,
        startIndex: Int,
        canvasWidth: CGFloat,
        maximumHeight: CGFloat
    ) -> [EpisodeTimelineMoment] {
        var remaining = Array(moment.heartText)
        var fragments: [EpisodeTimelineMoment] = []

        while !remaining.isEmpty {
            let pageIndex = startIndex + fragments.count
            let isFirst = fragments.isEmpty
            let whole = fragment(
                moment,
                text: String(remaining),
                index: fragments.count,
                keepsTimestamp: isFirst,
                keepsMetadata: true
            )
            if measuredHeight(
                document: document,
                page: EpisodeTimelineExportPage(index: pageIndex, moments: [whole]),
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
                    moment,
                    text: String(remaining.prefix(midpoint)),
                    index: fragments.count,
                    keepsTimestamp: isFirst,
                    keepsMetadata: false
                )
                let height = measuredHeight(
                    document: document,
                    page: EpisodeTimelineExportPage(
                        index: pageIndex,
                        moments: [candidate]
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
                    moment,
                    text: String(remaining.prefix(best)),
                    index: fragments.count,
                    keepsTimestamp: isFirst,
                    keepsMetadata: false
                )
            )
            remaining.removeFirst(best)
        }

        guard fragments.count > 1, let last = fragments.last else {
            return fragments
        }
        fragments[fragments.count - 1] = EpisodeTimelineMoment(
            id: last.id,
            heartText: last.heartText,
            timestamp: last.timestamp,
            pairName: moment.pairName,
            reactionLabels: moment.reactionLabels,
            isFavorite: moment.isFavorite
        )
        return fragments
    }

    private static func fragment(
        _ moment: EpisodeTimelineMoment,
        text: String,
        index: Int,
        keepsTimestamp: Bool,
        keepsMetadata: Bool
    ) -> EpisodeTimelineMoment {
        EpisodeTimelineMoment(
            id: "\(moment.id)-part-\(index)",
            heartText: text,
            timestamp: keepsTimestamp ? moment.timestamp : nil,
            pairName: keepsMetadata ? moment.pairName : nil,
            reactionLabels: keepsMetadata ? moment.reactionLabels : [],
            isFavorite: keepsMetadata && moment.isFavorite
        )
    }
}
