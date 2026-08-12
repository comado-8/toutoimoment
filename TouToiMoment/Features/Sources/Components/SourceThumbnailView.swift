import Foundation
import SwiftUI

struct SourceThumbnailView: View {
    let sourceID: String
    let imageURL: URL?
    var cornerRadius: CGFloat = 14

    init(
        sourceID: String,
        imageURL: URL? = nil,
        cornerRadius: CGFloat = 14
    ) {
        self.sourceID = sourceID
        self.imageURL = imageURL
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(palette.gradient)

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
        }
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 54, height: 54)
                    .blur(radius: 12)
                    .offset(x: -18, y: -18)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.48), lineWidth: 0.75)
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var palette: SourceThumbnailPalette {
        SourceThumbnailPalette.palette(for: sourceID)
    }
}

private struct SourceThumbnailPalette {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint

    var gradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    static func palette(for sourceID: String) -> SourceThumbnailPalette {
        palettes[stableIndex(for: sourceID) % palettes.count]
    }

    private static func stableIndex(for value: String) -> Int {
        value.utf8.reduce(2_166_136_261) { partial, byte in
            (partial ^ UInt64(byte)) &* 16_777_619
        }
        .quotientAndRemainder(dividingBy: UInt64(Int.max)).remainder
        .toInt
    }

    private static let palettes: [SourceThumbnailPalette] = [
        SourceThumbnailPalette(
            colors: [Color(hex: "#403CF8"), Color(hex: "#8382FC"), Color(hex: "#B2B8FD")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        SourceThumbnailPalette(
            colors: [Color(hex: "#92D7F3"), Color(hex: "#567AB8"), Color(hex: "#2D3C71")],
            startPoint: .top,
            endPoint: .bottomTrailing
        ),
        SourceThumbnailPalette(
            colors: [Color(hex: "#C4B5F0"), Color(hex: "#A78BFA")],
            startPoint: .leading,
            endPoint: .trailing
        ),
        SourceThumbnailPalette(
            colors: [Color(hex: "#FBD3ED"), Color(hex: "#A8C7FC"), Color(hex: "#6661C4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
    ]
}

private extension UInt64 {
    var toInt: Int { Int(self) }
}
