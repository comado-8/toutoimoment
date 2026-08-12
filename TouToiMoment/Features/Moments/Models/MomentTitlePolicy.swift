import Foundation

enum MomentTitlePolicy {
    nonisolated static let maximumLength = 20
    nonisolated static let counterThreshold = 15

    nonisolated static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 256,
            allowsNewlines: false
        )
    }

    nonisolated static func normalized(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        return limited(trimmed)
    }

    nonisolated static func shouldShowCounter(for value: String) -> Bool {
        value.count >= counterThreshold
    }

    nonisolated static func isValid(_ value: String) -> Bool {
        limited(value) == value
    }
}
