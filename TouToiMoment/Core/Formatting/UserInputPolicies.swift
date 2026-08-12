import Foundation

/// User-authored strings are untrusted data. This sanitizer protects rendering,
/// persistence, search and export paths; it is not a substitute for separating
/// user data from instructions if an AI feature is added in the future.
nonisolated enum UserInputTextSanitizer {
    private static let bidiControlScalars: Set<UInt32> = [
        0x061C, 0x200E, 0x200F,
        0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
        0x2066, 0x2067, 0x2068, 0x2069,
    ]

    static func limited(
        _ value: String,
        maximumCharacters: Int,
        maximumUTF8Bytes: Int,
        allowsNewlines: Bool
    ) -> String {
        let sanitized = sanitized(value, allowsNewlines: allowsNewlines)
        var result = ""
        result.reserveCapacity(min(sanitized.utf8.count, maximumUTF8Bytes))
        var byteCount = 0
        var characterCount = 0

        for character in sanitized {
            let text = String(character)
            let bytes = text.utf8.count
            guard
                characterCount < maximumCharacters,
                byteCount + bytes <= maximumUTF8Bytes
            else { break }
            result.append(character)
            characterCount += 1
            byteCount += bytes
        }
        return result
    }

    static func normalizedSingleLine(
        _ value: String,
        maximumCharacters: Int,
        maximumUTF8Bytes: Int
    ) -> String {
        limited(
            value,
            maximumCharacters: maximumCharacters,
            maximumUTF8Bytes: maximumUTF8Bytes,
            allowsNewlines: false
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func sanitized(_ value: String, allowsNewlines: Bool) -> String {
        var scalars = String.UnicodeScalarView()
        scalars.reserveCapacity(value.unicodeScalars.count)

        for scalar in value.unicodeScalars {
            if bidiControlScalars.contains(scalar.value) { continue }
            // Preserve emoji composition without allowing general format controls.
            if scalar.value == 0x200D
                || (0xFE00...0xFE0F).contains(scalar.value)
                || (0xE0100...0xE01EF).contains(scalar.value) {
                scalars.append(scalar)
                continue
            }
            if scalar.value == 0x0A, allowsNewlines {
                scalars.append(scalar)
                continue
            }
            if scalar.value == 0x0D {
                scalars.append(UnicodeScalar(allowsNewlines ? 0x0A : 0x20)!)
                continue
            }
            if scalar.value == 0x09 {
                scalars.append(UnicodeScalar(0x20)!)
                continue
            }
            if scalar.properties.generalCategory == .format { continue }
            if CharacterSet.controlCharacters.contains(scalar) { continue }
            if scalar.value == 0x0A {
                scalars.append(UnicodeScalar(0x20)!)
                continue
            }
            scalars.append(scalar)
        }
        return String(scalars).precomposedStringWithCanonicalMapping
    }
}

nonisolated enum HeartScreamTextPolicy {
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

    static func normalized(_ value: String) -> String {
        limited(value).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func shouldShowCounter(for value: String) -> Bool {
        value.count >= counterVisibilityThreshold
    }

    static func isValid(_ value: String) -> Bool {
        value.count <= maximumLength && value.utf8.count <= maximumUTF8Bytes
    }
}

nonisolated enum SourceNamePolicy {
    static let maximumLength = 120
    static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 1_024,
            allowsNewlines: false
        )
    }
    static func normalized(_ value: String) -> String {
        UserInputTextSanitizer.normalizedSingleLine(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 1_024
        )
    }
}

nonisolated enum EpisodeDisplayTitlePolicy {
    static let maximumLength = 120
    static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 1_024,
            allowsNewlines: false
        )
    }
    static func normalized(_ value: String?) -> String? {
        let normalized = UserInputTextSanitizer.normalizedSingleLine(
            value ?? "",
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 1_024
        )
        return normalized.isEmpty ? nil : normalized
    }
}

nonisolated enum StreamingPlatformNamePolicy {
    static let maximumLength = 50
    static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 512,
            allowsNewlines: false
        )
    }
}

nonisolated enum PairTextPolicy {
    static let memberMaximumLength = 50
    static let displayNameMaximumLength = 100

    static func limitedMember(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: memberMaximumLength,
            maximumUTF8Bytes: 512,
            allowsNewlines: false
        )
    }

    static func limitedDisplayName(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: displayNameMaximumLength,
            maximumUTF8Bytes: 1_024,
            allowsNewlines: false
        )
    }
}

nonisolated enum ProfileNicknamePolicy {
    static let maximumLength = 100

    /// Instrument Serif's ASCII letters and half-width punctuation, plus spaces.
    /// Digits and non-Latin scripts are intentionally excluded from profile names.
    static func limited(_ value: String) -> String {
        let allowedScalars = String(value.unicodeScalars.filter(isAllowed))
        return UserInputTextSanitizer.limited(
            allowedScalars,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: maximumLength,
            allowsNewlines: false
        )
    }

    static func normalized(_ value: String) -> String {
        limited(value).trimmingCharacters(in: .whitespaces)
    }

    private static func isAllowed(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x20,             // half-width space
             0x21...0x2F,     // ! through /
             0x3A...0x40,     // : through @
             0x41...0x5A,     // A through Z
             0x5B...0x60,     // [ through `
             0x61...0x7A,     // a through z
             0x7B...0x7E:     // { through ~
            true
        default:
            false
        }
    }
}

nonisolated enum RelatedURLInputPolicy {
    static let maximumLength = 2_048
    static let maximumUTF8Bytes = 8 * 1_024

    static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: maximumUTF8Bytes,
            allowsNewlines: false
        )
    }

    static func isWithinLimits(_ value: String) -> Bool {
        value.count <= maximumLength && value.utf8.count <= maximumUTF8Bytes
    }
}

nonisolated enum MomentSearchQueryPolicy {
    static let maximumLength = 100
    static func limited(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumLength,
            maximumUTF8Bytes: 1_024,
            allowsNewlines: false
        )
    }
}

nonisolated enum AutoHashtagPolicy {
    static let maximumInputLength = 200
    static let maximumTagLength = 50
    static let maximumTagCount = 10

    static func limitedInput(_ value: String) -> String {
        UserInputTextSanitizer.limited(
            value,
            maximumCharacters: maximumInputLength,
            maximumUTF8Bytes: 2 * 1_024,
            allowsNewlines: false
        )
    }

    static func normalizedTags(_ value: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        let separators = CharacterSet.whitespacesAndNewlines.union(
            CharacterSet(charactersIn: ",")
        )
        let tokens = limitedInput(value)
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
        for token in tokens {
            var body = token
            while body.first == Character("#") { body.removeFirst() }
            guard
                !body.isEmpty,
                body.count <= maximumTagLength,
                body.allSatisfy({
                    $0.isLetter || $0.isNumber || $0 == Character("_")
                })
            else { continue }
            let tag = "#\(body)"
            guard seen.insert(tag.lowercased()).inserted else { continue }
            result.append(tag)
            if result.count == maximumTagCount { break }
        }
        return result
    }
}
