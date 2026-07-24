import Combine
import Foundation
import SwiftUI

@MainActor
final class MomentStore: ObservableObject {
    @Published private(set) var moments: [MomentCardModel]
    private let imageRepository: any MomentImageRepository

    init(
        moments: [MomentCardModel]? = nil,
        imageRepository: any MomentImageRepository = LocalMomentImageRepository()
    ) {
        self.moments = moments ?? MomentCardModel.preview
        self.imageRepository = imageRepository
        if moments == nil {
            Task { [weak self] in
                await self?.loadStoredImages()
            }
        }
    }

    var favoriteMoments: [MomentCardModel] {
        moments.filter(\.isFavorite)
    }

    func moment(id: String) -> MomentCardModel? {
        moments.first(where: { $0.id == id })
    }

    func relatedMoments(for id: String) -> MomentRelatedMoments {
        guard let current = moment(id: id) else {
            return MomentRelatedMoments(sameSource: [], samePair: [])
        }

        let sameSource: [MomentCardModel]
        if let sourceID = current.sourceID {
            sameSource = Array(
                moments
                    .filter { $0.id != id && $0.sourceID == sourceID }
                    .prefix(2)
            )
        } else {
            sameSource = []
        }

        let usedIDs = Set(sameSource.map(\.id)).union([id])
        let samePair: [MomentCardModel]
        if let pairID = current.pairID {
            samePair = Array(
                moments
                    .filter { !usedIDs.contains($0.id) && $0.pairID == pairID }
                    .prefix(1)
            )
        } else {
            samePair = []
        }

        return MomentRelatedMoments(
            sameSource: sameSource,
            samePair: samePair
        )
    }

    func toggleFavorite(id: String) {
        guard let index = moments.firstIndex(where: { $0.id == id }) else {
            return
        }
        moments[index].isFavorite.toggle()
    }

    func loadStoredImages() async {
        let validIDs = Set(moments.map(\.id))
        for id in validIDs {
            guard let storedImages = try? await imageRepository.images(for: id) else {
                continue
            }
            setImages(storedImages, for: id)
        }
        try? await imageRepository.removeOrphans(validMomentIDs: validIDs)
    }

    func imageData(for image: MomentImage, momentID: String) async throws -> Data {
        try await imageRepository.imageData(for: image, momentID: momentID)
    }

    @discardableResult
    func addImage(data: Data, to momentID: String) async throws -> MomentImage {
        guard
            let moment = moment(id: momentID),
            moment.images.count < LocalMomentImageRepository.maximumImageCount
        else {
            throw MomentImageRepositoryError.limitExceeded
        }
        let imageID = UUID().uuidString
        let images = try await imageRepository.addImage(
            data: data,
            id: imageID,
            createdAt: Date(),
            to: momentID
        )
        setImages(images, for: momentID)
        guard let image = images.first(where: { $0.id == imageID }) else {
            throw MomentImageRepositoryError.storageUnavailable
        }
        return image
    }

    func removeImage(id imageID: String, from momentID: String) async throws {
        guard moment(id: momentID) != nil else {
            throw MomentImageRepositoryError.imageNotFound
        }
        let images = try await imageRepository.removeImage(id: imageID, from: momentID)
        setImages(images, for: momentID)
    }

    func commitImages(
        _ changes: MomentImageChangeSet,
        for momentID: String
    ) async throws -> [MomentImage] {
        guard moment(id: momentID) != nil else {
            throw MomentImageRepositoryError.imageNotFound
        }
        let images = try await imageRepository.commit(changes, for: momentID)
        setImages(images, for: momentID)
        return images
    }

    @discardableResult
    func delete(id: String) async throws -> Bool {
        guard moments.contains(where: { $0.id == id }) else { return false }
        try await imageRepository.deleteImages(for: id)
        guard let index = moments.firstIndex(where: { $0.id == id }) else { return false }
        moments.remove(at: index)
        return true
    }

    func add(draft: NewMomentDraft) {
        let contextSummary = NewMomentContextSummaryFormatter.summary(for: draft)
        let sourceName = draft.selectedSourceDisplayName ?? "—"
        let pairName = PairDisplayNameFormatter.normalized(
            draft.selectedPairDisplayName ?? "—"
        )

        moments.insert(
            MomentCardModel(
                id: UUID().uuidString,
                sceneText: MomentSceneTextPolicy.limited(draft.sceneSummary),
                heartText: draft.heartScream,
                caption: contextSummary.isEmpty ? sourceName : contextSummary,
                pairID: draft.selectedPairID,
                pairName: pairName,
                sourceID: draft.selectedSourceID,
                sourceName: sourceName,
                mediaType: draft.selectedSource?.mediaType,
                contextValues: MomentContextDisplayFormatter.contextValues(from: draft),
                reactionIDs: draft.selectedReactions.map(\.id),
                reactionLabels: draft.selectedReactions.map { reaction in
                    ReactionCatalog.reaction(withID: reaction.id)?.displayText
                        ?? reaction.displayText
                },
                images: [],
                leadingDotColor: Color(hex: draft.selectedPair?.leadingColorHex ?? "#46C1B1"),
                trailingDotColor: Color(
                    hex: draft.selectedPair?.trailingColorHex
                        ?? draft.selectedPair?.leadingColorHex
                        ?? "#F26767"
                ),
                createdAt: Date(),
                isFavorite: false
            ),
            at: 0
        )
    }

    @discardableResult
    func update(id: String, draft: NewMomentDraft) -> Bool {
        guard let index = moments.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let original = moments[index]
        let contextSummary = NewMomentContextSummaryFormatter.summary(for: draft)
        let sourceName = draft.selectedSourceDisplayName ?? "—"
        let pairName = PairDisplayNameFormatter.normalized(
            draft.selectedPairDisplayName ?? "—"
        )
        let pairChanged = original.pairID != draft.selectedPairID
        let leadingColor = pairChanged
            ? draft.selectedPair?.leadingColorHex.map { Color(hex: $0) } ?? original.leadingDotColor
            : original.leadingDotColor
        let trailingColor = pairChanged
            ? (draft.selectedPair?.trailingColorHex ?? draft.selectedPair?.leadingColorHex)
                .map { Color(hex: $0) } ?? original.trailingDotColor
            : original.trailingDotColor

        moments[index] = MomentCardModel(
            id: original.id,
            sceneText: MomentSceneTextPolicy.limited(draft.sceneSummary),
            heartText: draft.heartScream,
            caption: contextSummary.isEmpty ? sourceName : contextSummary,
            pairID: draft.selectedPairID,
            pairName: pairName,
            sourceID: draft.selectedSourceID,
            sourceName: sourceName,
            mediaType: draft.selectedSource?.mediaType,
            contextValues: MomentContextDisplayFormatter.contextValues(from: draft),
            reactionIDs: draft.selectedReactions.map(\.id),
            reactionLabels: draft.selectedReactions.map { reaction in
                ReactionCatalog.reaction(withID: reaction.id)?.displayText
                    ?? reaction.displayText
            },
            images: original.images,
            leadingDotColor: leadingColor,
            trailingDotColor: trailingColor,
            createdAt: original.createdAt,
            isFavorite: original.isFavorite
        )
        return true
    }

    @discardableResult
    func update(
        id: String,
        draft: NewMomentDraft,
        imageChanges: MomentImageChangeSet
    ) async throws -> Bool {
        guard moment(id: id) != nil else { return false }
        let images = try await imageRepository.commit(imageChanges, for: id)
        guard update(id: id, draft: draft) else { return false }
        setImages(images, for: id)
        return true
    }

    private func setImages(_ images: [MomentImage], for momentID: String) {
        guard let index = moments.firstIndex(where: { $0.id == momentID }) else { return }
        moments[index].images = images.sorted { $0.order < $1.order }
    }
}

struct MomentRelatedMoments {
    let sameSource: [MomentCardModel]
    let samePair: [MomentCardModel]

    var isEmpty: Bool {
        sameSource.isEmpty && samePair.isEmpty
    }
}
