import Foundation

struct MomentFilterState: Equatable {
    private var storedQuery = ""
    var query: String {
        get { storedQuery }
        set { storedQuery = MomentSearchQueryPolicy.limited(newValue) }
    }
    var favoritesOnly = false
    var selectedPairID: String?
    var selectedSourceID: String?
    var selectedReactionID: String?

    var hasActiveSelection: Bool {
        favoritesOnly
            || selectedPairID != nil
            || selectedSourceID != nil
            || selectedReactionID != nil
    }

    mutating func resetSelections() {
        favoritesOnly = false
        selectedPairID = nil
        selectedSourceID = nil
        selectedReactionID = nil
    }
}

struct MomentFilterOption: Identifiable, Equatable {
    let id: String
    let label: String
}
