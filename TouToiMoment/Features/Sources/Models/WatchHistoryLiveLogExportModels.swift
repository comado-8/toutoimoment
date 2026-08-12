import Foundation

struct WatchHistoryLiveLogExportDocument: Identifiable {
    let id = UUID()
    let sourceName: String
    let locatorDisplayName: String
    let episodeDisplayTitle: String?
    let session: WatchingSessionSummary
    let filename: String

    init(content: WatchHistoryDetailContent) {
        sourceName = content.source.displayName
        locatorDisplayName = content.locatorDisplayName
        episodeDisplayTitle = content.episode.displayTitle?.trimmedOrNil
        session = content.session
        filename = WatchHistoryLiveLogExportFilename.make(
            sourceName: content.source.displayName,
            episodeName: content.episode.displayTitle?.trimmedOrNil ?? content.locatorDisplayName,
            sessionDate: content.session.startedAt
        )
    }

    init(
        sourceName: String,
        locatorDisplayName: String,
        episodeDisplayTitle: String?,
        session: WatchingSessionSummary
    ) {
        self.sourceName = sourceName
        self.locatorDisplayName = locatorDisplayName
        self.episodeDisplayTitle = episodeDisplayTitle
        self.session = session
        filename = WatchHistoryLiveLogExportFilename.make(
            sourceName: sourceName,
            episodeName: episodeDisplayTitle ?? locatorDisplayName,
            sessionDate: session.startedAt
        )
    }
}

struct WatchHistoryLiveLogExportPage: Identifiable {
    let index: Int
    let events: [WatchingSessionEvent]

    var id: Int { index }
}

enum WatchHistoryLiveLogExportFilename {
    static func make(
        sourceName: String,
        episodeName: String,
        sessionDate: Date,
        createdAt: Date = .now
    ) -> String {
        let sessionFormatter = DateFormatter()
        sessionFormatter.calendar = Calendar(identifier: .gregorian)
        sessionFormatter.locale = Locale(identifier: "en_US_POSIX")
        sessionFormatter.timeZone = .current
        sessionFormatter.dateFormat = "yyyyMMdd-HHmm"

        let createdFormatter = DateFormatter()
        createdFormatter.calendar = sessionFormatter.calendar
        createdFormatter.locale = sessionFormatter.locale
        createdFormatter.timeZone = sessionFormatter.timeZone
        createdFormatter.dateFormat = "yyyyMMdd-HHmm"

        return [
            sanitized(sourceName),
            sanitized(episodeName),
            "LiveLog",
            sessionFormatter.string(from: sessionDate),
            createdFormatter.string(from: createdAt),
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "_")
    }

    static func pngFilename(base: String, page: Int, total: Int) -> String {
        guard total > 1 else { return "\(base).png" }
        return "\(base)_\(String(format: "%02d", page + 1)).png"
    }

    private static func sanitized(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let replacedSpaces = value.replacingOccurrences(of: " ", with: "-")
        let scalars = replacedSpaces.unicodeScalars.map {
            allowed.contains($0) ? String($0) : "-"
        }
        return scalars.joined()
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
