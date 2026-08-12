import Foundation

enum SourceMomentProjection {
    static func directMoments(
        sourceID: String,
        supportsEpisodes: Bool,
        moments: [MomentCardModel]
    ) -> [MomentCardModel] {
        moments.filter { moment in
            guard moment.sourceID == sourceID else { return false }
            return !supportsEpisodes || moment.episodeID == nil
        }
    }

    static func episodeMoments(
        sourceID: String,
        episodeID: String,
        moments: [MomentCardModel]
    ) -> [MomentCardModel] {
        moments
            .enumerated()
            .filter { _, moment in
                moment.sourceID == sourceID && moment.episodeID == episodeID
            }
            .sorted { lhs, rhs in
                let lhsSeconds = timestampSeconds(for: lhs.element)
                let rhsSeconds = timestampSeconds(for: rhs.element)

                switch (lhsSeconds, rhsSeconds) {
                case let (.some(lhsValue), .some(rhsValue)):
                    if lhsValue != rhsValue { return lhsValue < rhsValue }
                    return lhs.offset < rhs.offset
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }

    private static func timestampSeconds(for moment: MomentCardModel) -> Int? {
        guard
            let timestamp = moment.contextValues.first(where: { $0.key == "timestamp" })?.value,
            !timestamp.isEmpty
        else {
            return nil
        }

        let components = timestamp.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 || components.count == 3 else { return nil }

        return components.reversed().enumerated().reduce(0) { total, item in
            let multiplier = [1, 60, 3_600][item.offset]
            return total + item.element * multiplier
        }
    }
}
