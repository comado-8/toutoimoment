import Combine
import Foundation

@MainActor
final class MomentListViewModel: ObservableObject {
    @Published var filter = MomentFilterState()
    @Published private(set) var selectedGlobalFace: MomentFace = .scene
    @Published private var facesByMomentID: [String: MomentFace] = [:]

    let store: MomentStore

    init(store: MomentStore) {
        self.store = store
    }

    var displayedMoments: [MomentCardModel] {
        store.moments.filter(matchesFilters)
    }

    var pairOptions: [MomentFilterOption] {
        uniqueOptions(from: store.moments.compactMap { moment in
            guard let id = moment.pairID, !moment.pairName.isEmpty else { return nil }
            return MomentFilterOption(id: id, label: moment.pairName)
        })
    }

    var sourceOptions: [MomentFilterOption] {
        uniqueOptions(from: store.moments.compactMap { moment in
            guard let id = moment.sourceID, !moment.sourceName.isEmpty else { return nil }
            return MomentFilterOption(id: id, label: moment.sourceName)
        })
    }

    var reactionOptions: [MomentFilterOption] {
        let usedReactionIDs = Set(store.moments.flatMap(\.reactionIDs))
        return ReactionCatalog.allReactions.compactMap { reaction in
            guard usedReactionIDs.contains(reaction.id) else { return nil }
            return MomentFilterOption(id: reaction.id, label: reaction.displayText)
        }
    }

    func face(for momentID: String) -> MomentFace {
        facesByMomentID[momentID] ?? selectedGlobalFace
    }

    func setFace(_ face: MomentFace, for momentID: String) {
        facesByMomentID[momentID] = face
    }

    func toggleFace(for momentID: String) {
        var face = face(for: momentID)
        face.toggle()
        setFace(face, for: momentID)
    }

    func setAllFaces(_ face: MomentFace) {
        selectedGlobalFace = face
        facesByMomentID = Dictionary(
            uniqueKeysWithValues: store.moments.map { ($0.id, face) }
        )
    }

    func resetSelections() {
        filter.resetSelections()
    }

    private func matchesFilters(_ moment: MomentCardModel) -> Bool {
        let query = filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty, !moment.searchableText.localizedStandardContains(query) {
            return false
        }
        if filter.favoritesOnly, !moment.isFavorite {
            return false
        }
        if let pairID = filter.selectedPairID, moment.pairID != pairID {
            return false
        }
        if let sourceID = filter.selectedSourceID, moment.sourceID != sourceID {
            return false
        }
        if let reactionID = filter.selectedReactionID,
           !moment.reactionIDs.contains(reactionID) {
            return false
        }
        return true
    }

    private func uniqueOptions(from options: [MomentFilterOption]) -> [MomentFilterOption] {
        var seen = Set<String>()
        return options.filter { seen.insert($0.id).inserted }
    }
}
