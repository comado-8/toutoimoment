import Foundation

enum PairDisplayNameFormatter {
    private static let separatorPattern = #"[\t ]*[×･•・][\t ]*"#

    static func normalized(_ displayName: String) -> String {
        displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: separatorPattern,
                with: " ・ ",
                options: .regularExpression
            )
    }

    static func joined(_ leadingName: String, _ trailingName: String) -> String {
        let leading = leadingName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trailing = trailingName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(leading) ・ \(trailing)"
    }
}
