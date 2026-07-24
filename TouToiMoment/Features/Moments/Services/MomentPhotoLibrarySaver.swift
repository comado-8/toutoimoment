import Photos
import UIKit

enum MomentPhotoLibrarySaveError: Error, Equatable {
    case accessDenied
    case accessRestricted
    case saveFailed
}

enum MomentPhotoSaveOutcome: Equatable {
    case success
    case accessDenied
    case accessRestricted
    case saveFailed
}

@MainActor
protocol MomentPhotoLibrarySaving {
    func save(_ image: UIImage) async throws
}

@MainActor
enum MomentPhotoSaveCoordinator {
    static func save(
        _ image: UIImage,
        using saver: any MomentPhotoLibrarySaving
    ) async -> MomentPhotoSaveOutcome {
        do {
            try await saver.save(image)
            return .success
        } catch let error as MomentPhotoLibrarySaveError {
            switch error {
            case .accessDenied:
                return .accessDenied
            case .accessRestricted:
                return .accessRestricted
            case .saveFailed:
                return .saveFailed
            }
        } catch {
            return .saveFailed
        }
    }
}

@MainActor
struct SystemMomentPhotoLibrarySaver: MomentPhotoLibrarySaving {
    func save(_ image: UIImage) async throws {
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
                PHAssetChangeRequest.creationRequestForAsset(from: image)
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
