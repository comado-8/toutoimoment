import Foundation

struct EpisodeTimelineExportDocument: Identifiable {
    let id = UUID()
    let sourceName: String
    let locatorDisplayName: String
    let episodeDisplayTitle: String?
    let moments: [EpisodeTimelineMoment]
    let filename: String

    init(
        content: EpisodeDetailContent,
        moments: [MomentCardModel]
    ) {
        sourceName = content.source.displayName
        locatorDisplayName = content.locatorDisplayName
        episodeDisplayTitle = content.episode.displayTitle?.trimmedOrNil
        self.moments = moments.map { EpisodeTimelineMoment(moment: $0) }
        filename = EpisodeTimelineExportFilename.make(
            sourceName: content.source.displayName,
            episodeName: content.episode.displayTitle?.trimmedOrNil ?? content.locatorDisplayName
        )
    }

    init(
        sourceName: String,
        locatorDisplayName: String,
        episodeDisplayTitle: String?,
        moments: [EpisodeTimelineMoment]
    ) {
        self.sourceName = sourceName
        self.locatorDisplayName = locatorDisplayName
        self.episodeDisplayTitle = episodeDisplayTitle
        self.moments = moments
        filename = EpisodeTimelineExportFilename.make(
            sourceName: sourceName,
            episodeName: episodeDisplayTitle ?? locatorDisplayName
        )
    }
}

struct EpisodeTimelineExportPage: Identifiable {
    let index: Int
    let moments: [EpisodeTimelineMoment]

    var id: Int { index }
}

enum EpisodeTimelineExportFilename {
    static func make(
        sourceName: String,
        episodeName: String,
        date: Date = .now
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmm"

        let components = [
            sanitized(sourceName),
            sanitized(episodeName),
            "Timeline",
            formatter.string(from: date),
        ]
        return components.filter { !$0.isEmpty }.joined(separator: "_")
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
