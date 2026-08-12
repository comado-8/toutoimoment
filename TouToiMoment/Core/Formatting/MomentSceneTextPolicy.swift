import Foundation

nonisolated enum MomentSceneTextPolicy {
    static let maximumLength = 1_000
    static let maximumUTF8Bytes = 16 * 1_024
    static let counterVisibilityThreshold = 800
    static let warningThreshold = 900

    static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: maximumUTF8Bytes,
            allowsNewlines: true
        )
    }

    static func shouldShowCounter(for value: String) -> Bool {
        value.count >= counterVisibilityThreshold
    }

    static func counterText(for value: String) -> String {
        "\(min(value.count, maximumLength)) / \(maximumLength)"
    }

    static func isValid(_ value: String) -> Bool {
        value.count <= maximumLength && value.utf8.count <= maximumUTF8Bytes
    }
}
