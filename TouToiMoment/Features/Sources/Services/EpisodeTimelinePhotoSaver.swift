import Photos
import UIKit

@MainActor
protocol EpisodeTimelinePhotoLibrarySaving {
    func savePNGData(_ data: Data, filename: String) async throws
}

@MainActor
struct SystemEpisodeTimelinePhotoLibrarySaver: EpisodeTimelinePhotoLibrarySaving {
    func savePNGData(_ data: Data, filename: String) async throws {
        let authorization = await authorizationStatus()

        switch authorization {
        case .authorized, .limited:
            break
        case .restricted:
            throw MomentPhotoLibrarySaveError.accessRestricted
        case .denied, .notDetermined:
            throw MomentPhotoLibrarySaveError.accessDenied
        @unknown default:
            throw MomentPhotoLibrarySaveError.accessDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = filename
                request.addResource(with: .photo, data: data, options: options)
            }
        } catch {
            throw MomentPhotoLibrarySaveError.saveFailed
        }
    }

    private func authorizationStatus() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard current == .notDetermined else { return current }
        return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}

enum EpisodeTimelinePhotoSaveOutcome: Equatable {
    case success(savedCount: Int)
    case accessDenied(savedCount: Int)
    case accessRestricted(savedCount: Int)
    case renderingFailed(savedCount: Int)
    case saveFailed(savedCount: Int)
}

@MainActor
enum EpisodeTimelinePhotoSaveCoordinator {
    static func save(
        document: EpisodeTimelineExportDocument,
        pages: [EpisodeTimelineExportPage],
        using saver: any EpisodeTimelinePhotoLibrarySaving
    ) async -> EpisodeTimelinePhotoSaveOutcome {
        var savedCount = 0

        for page in pages {
            guard
                let image = EpisodeTimelineExportRenderer.image(
                    for: document,
                    page: page,
                    totalPageCount: pages.count
                ),
                let data = image.pngData()
            else {
                return .renderingFailed(savedCount: savedCount)
            }

            let filename = EpisodeTimelineExportFilename.pngFilename(
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
