import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
final class MomentStore: ObservableObject {
    @Published private(set) var moments: [MomentCardModel]
    @Published private(set) var persistenceError: Error?
    private static let logger = Logger(subsystem: "TouToiMoment", category: "MomentStore")
    private let imageRepository: any MomentImageRepository
    private let persistence: (any MomentStorePersistence)?

    init(
        moments: [MomentCardModel]? = nil,
        imageRepository: any MomentImageRepository = LocalMomentImageRepository(),
        persistence: (any MomentStorePersistence)? = nil
    ) {
        self.persistence = persistence
        let storedMoments = persistence?.load()
        if let moments {
            self.moments = moments
        } else if persistence != nil {
            self.moments = storedMoments ?? []
        } else {
            self.moments = MomentCardModel.preview
        }
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
        persist()
    }

    func updateSourceReference(
        id sourceID: String,
        displayName: String,
        mediaType: String
    ) {
        for index in moments.indices where moments[index].sourceID == sourceID {
            moments[index].sourceName = displayName
            moments[index].mediaType = mediaType
        }
        persist()
    }

    func updatePairReference(
        id pairID: String,
        displayName: String,
        member1Name: String,
        member2Name: String?,
        leadingColorHex: String,
        trailingColorHex: String?
    ) {
        for index in moments.indices where moments[index].pairID == pairID {
            moments[index].pairName = displayName
            moments[index].pairMemberNames = [member1Name, member2Name]
                .compactMap { $0 }
            moments[index].leadingDotColor = Color(hex: leadingColorHex)
            moments[index].trailingDotColor = Color(
                hex: trailingColorHex ?? leadingColorHex
            )
        }
        persist()
    }

    func clearPairReferences(id pairID: String) {
        for index in moments.indices where moments[index].pairID == pairID {
            moments[index].pairID = nil
            moments[index].pairName = "—"
            moments[index].pairMemberNames = []
        }
        persist()
    }

    func clearSourceReferences(id sourceID: String) {
        for index in moments.indices where moments[index].sourceID == sourceID {
            moments[index].sourceID = nil
            moments[index].sourceName = "—"
            moments[index].mediaType = nil
            moments[index].episodeID = nil
            moments[index].episodeLocatorValues = []
        }
        persist()
    }

    func detachEpisodeReferences(sourceID: String, episodeID: String) {
        for index in moments.indices where
            moments[index].sourceID == sourceID && moments[index].episodeID == episodeID {
            moments[index].episodeID = nil
            moments[index].episodeLocatorValues = []
        }
        persist()
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

    func reloadFromPersistence() async throws {
        guard let stored = persistence?.load() else {
            throw ManualBackupError.restoreFailed(reason: "moment-reload")
        }
        moments = stored
        await loadStoredImages()
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
        persist()
        return true
    }

    func deleteAll() async throws {
        let existingIDs = moments.map(\.id)
        for id in existingIDs {
            try await imageRepository.deleteImages(for: id)
        }
        moments.removeAll()
        persist()
        try await imageRepository.removeOrphans(validMomentIDs: Set<String>())
    }

    @discardableResult
    func add(draft: NewMomentDraft, id: String = UUID().uuidString) -> MomentCardModel {
        let sourceName = draft.selectedSourceDisplayName ?? "—"
        let pairName = PairDisplayNameFormatter.normalized(
            draft.selectedPairDisplayName ?? "—"
        )

        let moment = MomentCardModel(
            id: id,
            title: MomentTitlePolicy.normalized(draft.momentTitle),
            sceneText: MomentSceneTextPolicy.limited(draft.sceneSummary),
            heartText: HeartScreamTextPolicy.normalized(draft.heartScream),
            caption: sourceName,
            pairID: draft.selectedPairID,
            pairName: pairName,
            pairMemberNames: [
                draft.selectedPair?.member1Name,
                draft.selectedPair?.member2Name,
            ].compactMap { $0 },
            sourceID: draft.selectedSourceID,
            sourceName: sourceName,
            mediaType: draft.selectedSource?.mediaType,
            episodeID: draft.selectedEpisodeID,
            episodeLocatorValues: draft.selectedEpisode?.locatorValues ?? [],
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
            momentDate: draft.momentDate,
            createdAt: Date(),
            isFavorite: false
        )
        moments.insert(moment, at: 0)
        persist()
        return moment
    }

    @discardableResult
    func update(id: String, draft: NewMomentDraft) -> Bool {
        guard let index = moments.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let original = moments[index]
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
            title: MomentTitlePolicy.normalized(draft.momentTitle),
            sceneText: MomentSceneTextPolicy.limited(draft.sceneSummary),
            heartText: HeartScreamTextPolicy.normalized(draft.heartScream),
            caption: sourceName,
            pairID: draft.selectedPairID,
            pairName: pairName,
            pairMemberNames: [
                draft.selectedPair?.member1Name,
                draft.selectedPair?.member2Name,
            ].compactMap { $0 },
            sourceID: draft.selectedSourceID,
            sourceName: sourceName,
            mediaType: draft.selectedSource?.mediaType,
            episodeID: draft.selectedEpisodeID,
            episodeLocatorValues: draft.selectedEpisode?.locatorValues ?? [],
            contextValues: MomentContextDisplayFormatter.contextValues(from: draft),
            reactionIDs: draft.selectedReactions.map(\.id),
            reactionLabels: draft.selectedReactions.map { reaction in
                ReactionCatalog.reaction(withID: reaction.id)?.displayText
                    ?? reaction.displayText
            },
            images: original.images,
            leadingDotColor: leadingColor,
            trailingDotColor: trailingColor,
            momentDate: draft.momentDate,
            createdAt: original.createdAt,
            isFavorite: original.isFavorite
        )
        persist()
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
        persist()
    }

    private func persist() {
        do {
            try persistence?.save(moments)
            persistenceError = nil
        } catch {
            persistenceError = error
            Self.logger.error("Failed to persist moments: \(error.localizedDescription, privacy: .public)")
        }
    }
}

struct MomentRelatedMoments {
    let sameSource: [MomentCardModel]
    let samePair: [MomentCardModel]

    var isEmpty: Bool {
        sameSource.isEmpty && samePair.isEmpty
    }
}
