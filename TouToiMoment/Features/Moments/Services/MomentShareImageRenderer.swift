import SwiftUI
import UIKit

enum MomentShareImageRenderer {
    static let cardSize = CGSize(width: 342, height: 612)
    static let cornerRadius: CGFloat = 28
    static let scale: CGFloat = 3

    @MainActor
    static func image(
        for moment: MomentCardModel,
        configuration: MomentShareConfiguration
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: MomentShareExportCanvas(
                moment: moment,
                configuration: configuration
            )
            .frame(width: cardSize.width, height: cardSize.height)
        )
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage
    }
}
