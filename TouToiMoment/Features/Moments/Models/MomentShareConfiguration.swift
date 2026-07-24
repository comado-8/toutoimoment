import Foundation

struct MomentShareConfiguration: Equatable {
    var showsPair: Bool
    var showsReaction: Bool
    var showsHashtag: Bool

    init(
        showsPair: Bool = true,
        showsReaction: Bool = true,
        showsHashtag: Bool = true
    ) {
        self.showsPair = showsPair
        self.showsReaction = showsReaction
        self.showsHashtag = showsHashtag
    }

    static func initial(for _: MomentCardModel) -> MomentShareConfiguration {
        MomentShareConfiguration()
    }

    func heartText(for moment: MomentCardModel) -> String? {
        moment.heartText.shareTrimmedValue
    }
}

extension String {
    fileprivate var shareTrimmedValue: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
