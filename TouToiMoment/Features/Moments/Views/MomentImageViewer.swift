import SwiftUI
import UIKit

struct MomentImageViewer: View {
    let items: [MomentImageDisplayItem]
    let initialImageID: String
    let loadStoredData: (MomentImage) async throws -> Data
    let onDismiss: () -> Void

    @State private var selectedImageID: String?
    @State private var isSelectedImageZoomed = false

    init(
        items: [MomentImageDisplayItem],
        initialImageID: String,
        loadStoredData: @escaping (MomentImage) async throws -> Data,
        onDismiss: @escaping () -> Void
    ) {
        self.items = items
        self.initialImageID = initialImageID
        self.loadStoredData = loadStoredData
        self.onDismiss = onDismiss
        _selectedImageID = State(initialValue: initialImageID)
    }

    var body: some View {
        GeometryReader { proxy in
            let pageWidth = min(350, max(260, proxy.size.width - 40))
            let pageHeight = min(320, max(240, proxy.size.height * 0.42))

            ZStack {
                Color(hex: "#060608")
                    .ignoresSafeArea()

                AppBackgroundView(theme: .home)
                    .opacity(0.12)
                    .ignoresSafeArea()

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(items) { item in
                            MomentZoomableImagePage(
                                item: item,
                                isSelected: selectedImageID == item.id,
                                loadStoredData: loadStoredData,
                                onZoomStateChange: { isZoomed in
                                    guard selectedImageID == item.id else { return }
                                    isSelectedImageZoomed = isZoomed
                                }
                            )
                            .frame(width: pageWidth, height: pageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.90), radius: 32, y: 16)
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, (proxy.size.width - pageWidth) / 2)
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $selectedImageID, anchor: .center)
                .scrollDisabled(isSelectedImageZoomed)
                .frame(height: pageHeight)

                VStack {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .tint(Color.white.opacity(0.12))
                        .foregroundStyle(.white)
                        .accessibilityLabel(AppStrings.momentImageViewerClose)
                        .accessibilityIdentifier("moment.image.viewer.close")

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Spacer()

                    if items.count > 1 {
                        HStack(spacing: 7) {
                            ForEach(items) { item in
                                Capsule()
                                    .fill(
                                        item.id == selectedImageID
                                            ? Color.appPrimaryTint
                                            : Color.white.opacity(0.24)
                                    )
                                    .frame(
                                        width: item.id == selectedImageID ? 18 : 6,
                                        height: 6
                                    )
                            }
                        }
                        .animation(.easeOut(duration: 0.18), value: selectedImageID)
                        .accessibilityLabel(
                            AppStrings.momentImagePage(
                                current: selectedIndex + 1,
                                total: items.count
                            )
                        )
                        .accessibilityIdentifier("moment.image.viewer.page")
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
        .accessibilityIdentifier("moment.image.viewer")
    }

    private var selectedIndex: Int {
        items.firstIndex(where: { $0.id == selectedImageID }) ?? 0
    }
}

private struct MomentZoomableImagePage: View {
    let item: MomentImageDisplayItem
    let isSelected: Bool
    let loadStoredData: (MomentImage) async throws -> Data
    let onZoomStateChange: (Bool) -> Void

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var settledOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.32)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .clipped()
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .contentShape(Rectangle())
            .gesture(magnifyGesture(containerSize: proxy.size))
            .highPriorityGesture(
                panGesture(containerSize: proxy.size),
                including: scale > 1.001 ? .all : .none
            )
        }
        .task(id: item.id) {
            image = await resolvedImage()
        }
        .onChange(of: isSelected) { _, selected in
            if !selected {
                resetZoom()
            }
        }
    }

    private func magnifyGesture(containerSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(4, max(1, settledScale * value.magnification))
                offset = clampedOffset(
                    offset,
                    scale: scale,
                    containerSize: containerSize
                )
                onZoomStateChange(scale > 1.001)
            }
            .onEnded { _ in
                settledScale = scale
                if scale <= 1.001 {
                    resetZoom()
                } else {
                    offset = clampedOffset(
                        offset,
                        scale: scale,
                        containerSize: containerSize
                    )
                    settledOffset = offset
                }
            }
    }

    private func panGesture(containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clampedOffset(
                    CGSize(
                        width: settledOffset.width + value.translation.width,
                        height: settledOffset.height + value.translation.height
                    ),
                    scale: scale,
                    containerSize: containerSize
                )
            }
            .onEnded { _ in
                offset = clampedOffset(
                    offset,
                    scale: scale,
                    containerSize: containerSize
                )
                settledOffset = offset
            }
    }

    private func clampedOffset(
        _ proposedOffset: CGSize,
        scale: CGFloat,
        containerSize: CGSize
    ) -> CGSize {
        let maximumX = max(0, containerSize.width * (scale - 1) / 2)
        let maximumY = max(0, containerSize.height * (scale - 1) / 2)
        return CGSize(
            width: min(max(proposedOffset.width, -maximumX), maximumX),
            height: min(max(proposedOffset.height, -maximumY), maximumY)
        )
    }

    private func resetZoom() {
        withAnimation(.easeOut(duration: 0.18)) {
            scale = 1
            settledScale = 1
            offset = .zero
            settledOffset = .zero
        }
        onZoomStateChange(false)
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
        return await Task.detached(priority: .userInitiated) {
            UIImage(data: data)
        }.value
    }
}
