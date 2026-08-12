import SwiftUI
import UniformTypeIdentifiers

struct WatchHistoryLiveLogExportView: View {
    let document: WatchHistoryLiveLogExportDocument

    private let photoLibrarySaver: any EpisodeTimelinePhotoLibrarySaving

    @Environment(\.dismiss) private var dismiss
    @State private var imagePages: [WatchHistoryLiveLogExportPage] = []
    @State private var pdfPages: [WatchHistoryLiveLogExportPage] = []
    @State private var previewImage: UIImage?
    @State private var isPreparing = true
    @State private var isSavingImages = false
    @State private var isGeneratingPDF = false
    @State private var pdfFile: EpisodeTimelinePDFFile?
    @State private var isExportingPDF = false
    @State private var alert: WatchHistoryLiveLogExportAlert?
    @State private var confirmation: String?

    @MainActor
    init(
        document: WatchHistoryLiveLogExportDocument,
        photoLibrarySaver: (any EpisodeTimelinePhotoLibrarySaving)? = nil
    ) {
        self.document = document
        self.photoLibrarySaver =
            photoLibrarySaver ?? SystemEpisodeTimelinePhotoLibrarySaver()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(theme: .home, motionEnabled: false)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        preview

                        if imagePages.count > 1 {
                            Label(
                                AppStrings.watchHistoryLiveLogExportSplitNotice(
                                    imagePages.count
                                ),
                                systemImage: "rectangle.stack"
                            )
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(AppStrings.watchHistoryLiveLogExportTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(AppStrings.episodeTimelineExportClose)
                    .accessibilityIdentifier("live_log_export.close")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionBar
            }
        }
        .task {
            preparePreview()
        }
        .fileExporter(
            isPresented: $isExportingPDF,
            document: pdfFile,
            contentType: .pdf,
            defaultFilename: document.filename
        ) { result in
            pdfFile = nil
            switch result {
            case .success:
                confirmation = AppStrings.watchHistoryLiveLogExportPDFSaved
            case let .failure(error):
                if (error as? CocoaError)?.code != .userCancelled {
                    alert = .pdfSave
                }
            }
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(AppStrings.momentShareErrorDismiss))
            )
        }
        .accessibilityIdentifier("live_log_export.view")
    }

    @ViewBuilder
    private var preview: some View {
        if isPreparing {
            ProgressView(AppStrings.watchHistoryLiveLogExportPreparing)
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity, minHeight: 420)
                .accessibilityIdentifier("live_log_export.preparing")
        } else if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 342, maxHeight: 460)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(
                    color: Color(hex: "#7C6FCD").opacity(0.16),
                    radius: 18,
                    y: 8
                )
                .frame(maxWidth: .infinity)
                .accessibilityLabel(AppStrings.watchHistoryLiveLogExportPreview)
                .accessibilityIdentifier("live_log_export.preview")
        } else {
            ContentUnavailableView(
                AppStrings.watchHistoryLiveLogExportErrorTitle,
                systemImage: "exclamationmark.triangle",
                description: Text(AppStrings.watchHistoryLiveLogExportErrorMessage)
            )
        }
    }

    private var actionBar: some View {
        VStack(spacing: 8) {
            if let confirmation {
                Label(confirmation, systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityIdentifier("live_log_export.saved")
            }

            HStack(spacing: 8) {
                Text(AppStrings.episodeTimelineExportImageFormat)
                Text(AppStrings.episodeTimelineExportImageCount(imagePages.count))
                Text("·").accessibilityHidden(true)
                Text(AppStrings.episodeTimelineExportPDFFormat)
                Text(AppStrings.episodeTimelineExportPDFCount(pdfPages.count))
            }
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .accessibilityElement(children: .combine)

            HStack(spacing: 12) {
                Button(action: saveImages) {
                    actionLabel(
                        isWorking: isSavingImages,
                        title: AppStrings.episodeTimelineExportSaveImage,
                        systemImage: "square.and.arrow.down"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(actionsDisabled)
                .accessibilityIdentifier("live_log_export.save_image")

                Button(action: savePDF) {
                    actionLabel(
                        isWorking: isGeneratingPDF,
                        title: AppStrings.episodeTimelineExportSavePDF,
                        systemImage: "doc.badge.arrow.up"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(actionsDisabled)
                .accessibilityIdentifier("live_log_export.save_pdf")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func actionLabel(
        isWorking: Bool,
        title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 7) {
            if isWorking {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionsDisabled: Bool {
        isPreparing || isSavingImages || isGeneratingPDF || previewImage == nil
    }

    @MainActor
    private func preparePreview() {
        guard isPreparing else { return }
        imagePages = WatchHistoryLiveLogExportRenderer.imagePages(for: document)
        pdfPages = WatchHistoryLiveLogExportRenderer.pdfPages(for: document)
        previewImage = WatchHistoryLiveLogExportRenderer.previewImage(
            for: document,
            pages: imagePages
        )
        isPreparing = false
        if previewImage == nil {
            alert = .rendering
        }
    }

    @MainActor
    private func saveImages() {
        guard !actionsDisabled else { return }
        isSavingImages = true
        confirmation = nil

        Task { @MainActor in
            let outcome = await WatchHistoryLiveLogPhotoSaveCoordinator.save(
                document: document,
                pages: imagePages,
                using: photoLibrarySaver
            )
            isSavingImages = false

            switch outcome {
            case let .success(savedCount):
                confirmation = AppStrings.watchHistoryLiveLogExportImagesSaved(savedCount)
            case .accessDenied, .accessRestricted:
                alert = .photoAccess
            case let .renderingFailed(savedCount), let .saveFailed(savedCount):
                alert = savedCount > 0 ? .partialSave(savedCount) : .photoSave
            }
        }
    }

    @MainActor
    private func savePDF() {
        guard !actionsDisabled else { return }
        isGeneratingPDF = true
        confirmation = nil

        guard let data = WatchHistoryLiveLogExportRenderer.pdfData(
            for: document,
            pages: pdfPages
        ) else {
            isGeneratingPDF = false
            alert = .rendering
            return
        }

        pdfFile = EpisodeTimelinePDFFile(data: data)
        isGeneratingPDF = false
        isExportingPDF = true
    }
}

private enum WatchHistoryLiveLogExportAlert: Identifiable {
    case rendering
    case photoAccess
    case photoSave
    case partialSave(Int)
    case pdfSave

    var id: String {
        switch self {
        case .rendering: "rendering"
        case .photoAccess: "photoAccess"
        case .photoSave: "photoSave"
        case let .partialSave(count): "partialSave-\(count)"
        case .pdfSave: "pdfSave"
        }
    }

    var title: String {
        switch self {
        case .rendering:
            AppStrings.watchHistoryLiveLogExportErrorTitle
        case .photoAccess:
            AppStrings.momentSharePhotoAccessErrorTitle
        case .photoSave, .partialSave:
            AppStrings.momentSharePhotoSaveErrorTitle
        case .pdfSave:
            AppStrings.watchHistoryLiveLogExportPDFSaveErrorTitle
        }
    }

    var message: String {
        switch self {
        case .rendering:
            AppStrings.watchHistoryLiveLogExportErrorMessage
        case .photoAccess:
            AppStrings.momentSharePhotoAccessErrorMessage
        case .photoSave:
            AppStrings.momentSharePhotoSaveErrorMessage
        case let .partialSave(count):
            AppStrings.watchHistoryLiveLogExportPartialSave(count)
        case .pdfSave:
            AppStrings.watchHistoryLiveLogExportPDFSaveErrorMessage
        }
    }
}
