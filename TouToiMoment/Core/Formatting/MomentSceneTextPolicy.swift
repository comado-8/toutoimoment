import Foundation

nonisolated enum MomentSceneTextPolicy {
    static let maximumLength = 1_000
    static let counterVisibilityThreshold = 800
    static let warningThreshold = 900

    static func limited(_ value: String) -> String {
        guard value.count > maximumLength else { return value }
        return String(value.prefix(maximumLength))
    }

    static func shouldShowCounter(for value: String) -> Bool {
        value.count >= counterVisibilityThreshold
    }

    static func counterText(for value: String) -> String {
        "\(min(value.count, maximumLength)) / \(maximumLength)"
    }
}
