import UIKit

@MainActor
enum WatchHistoryLiveLogPhotoSaveCoordinator {
    static func save(
        document: WatchHistoryLiveLogExportDocument,
        pages: [WatchHistoryLiveLogExportPage],
        using saver: any EpisodeTimelinePhotoLibrarySaving
    ) async -> EpisodeTimelinePhotoSaveOutcome {
        var savedCount = 0

        for page in pages {
            guard
                let image = WatchHistoryLiveLogExportRenderer.image(
                    for: document,
                    page: page,
                    totalPageCount: pages.count
                ),
                let data = image.pngData()
            else {
                return .renderingFailed(savedCount: savedCount)
            }

            let filename = WatchHistoryLiveLogExportFilename.pngFilename(
                base: document.filename,
                page: page.index,
                total: pages.count
            )

            do {
                try await saver.savePNGData(data, filename: filename)
                savedCount += 1
            } catch let error as MomentPhotoLibrarySaveError {
                switch error {
                case .accessDenied:
                    return .accessDenied(savedCount: savedCount)
                case .accessRestricted:
                    return .accessRestricted(savedCount: savedCount)
                case .saveFailed:
                    return .saveFailed(savedCount: savedCount)
                }
            } catch {
                return .saveFailed(savedCount: savedCount)
            }
        }

        return .success(savedCount: savedCount)
    }
}
