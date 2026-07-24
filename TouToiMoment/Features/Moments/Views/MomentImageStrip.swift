import ImageIO
import PhotosUI
import SwiftUI
import UIKit

struct MomentImageDisplayItem: Identifiable {
    enum Source {
        case stored(MomentImage)
        case pending(Data)
    }

    let id: String
    let source: Source
}

struct MomentImageStrip: View {
    let items: [MomentImageDisplayItem]
    let isProcessing: Bool
    let loadStoredData: (MomentImage) async throws -> Data
    let onAdd: () -> Void
    let onOpen: (String) -> Void
    let onDelete: (String) -> Void

    private let maximumCount = 3
    private let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let size = min(100, max(72, (proxy.size.width - spacing * 2) / 3))

            HStack(spacing: spacing) {
                ForEach(items.prefix(maximumCount)) { item in
                    Button {
                        onOpen(item.id)
                    } label: {
                        MomentImageThumbnail(
                            item: item,
                            loadStoredData: loadStoredData
                        )
                        .frame(width: size, height: size)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(item.id)
                        } label: {
                            Label(AppStrings.momentImageDelete, systemImage: "trash")
                        }
                    }
                    .accessibilityLabel(AppStrings.momentImageOpen)
                    .accessibilityHint(AppStrings.momentImageDeleteHint)
                    .accessibilityIdentifier("moment.image.thumbnail.\(item.id)")
                }

                ForEach(0..<max(0, maximumCount - items.count), id: \.self) { index in
                    Button(action: onAdd) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.secondarySystemBackground).opacity(0.62))
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    Color.appPrimarySoft.opacity(0.62),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                                )

                            if isProcessing && index == 0 {
                                ProgressView()
                                    .tint(Color.appPrimary)
                            } else {
                                Image(systemName: "photo")
                                    .font(.title3.weight(.regular))
                                    .foregroundStyle(Color.appPrimarySoft.opacity(0.68))
                            }
                        }
                        .frame(width: size, height: size)
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    .accessibilityLabel(AppStrings.momentImageAdd)
                    .accessibilityIdentifier("moment.image.add.\(index)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: 100)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppStrings.momentImageSection)
    }
}

struct MomentImageThumbnail: View {
    let item: MomentImageDisplayItem
    let loadStoredData: (MomentImage) async throws -> Data

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .tint(Color.appPrimary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: item.id) {
            image = await resolvedImage()
        }
    }

    private func resolvedImage() async -> UIImage? {
        let data: Data
        switch item.source {
        case .pending(let pendingData):
            data = pendingData
        case .stored(let image):
            guard let storedData = try? await loadStoredData(image) else { return nil }
            data = storedData
        }
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 300,
                    kCGImageSourceShouldCacheImmediately: true
                ] as CFDictionary
            )
        else {
            return nil
        }
        return UIImage(cgImage: thumbnail)
    }
}
