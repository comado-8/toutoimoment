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

    static func displayName(member1: String, member2: String?, nickname: String) -> String {
        let nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nickname.isEmpty { return nickname }
        let member1 = member1.trimmingCharacters(in: .whitespacesAndNewlines)
        let member2 = member2?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if member2.isEmpty { return member1 }
        if member1.isEmpty { return member2 }
        return joined(member1, member2)
    }

    static func members(fromLegacyDisplayName displayName: String) -> (String, String?) {
        let components = normalized(displayName)
            .components(separatedBy: " ・ ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard components.count == 2 else { return (normalized(displayName), nil) }
        return (components[0], components[1])
    }
}
