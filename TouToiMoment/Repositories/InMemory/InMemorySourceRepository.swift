import Foundation

@MainActor
final class InMemorySourceRepository: SourceRepository {
    private var sources: [SourceSummary]

    init() {
        self.sources = Self.defaultSources
    }

    init(sources: [SourceSummary]) {
        self.sources = sources
    }

    func fetchSources() async throws -> [SourceSummary] {
        sources
    }

    func createSource(
        displayName: String,
        helperText: String,
        mediaType: String,
        totalCount: Int?,
        isFavorite: Bool
    ) async throws -> SourceSummary {
        let source = SourceSummary(
            id: UUID().uuidString,
            displayName: displayName,
            helperText: helperText,
            mediaType: mediaType,
            totalCount: totalCount,
            isFavorite: isFavorite
        )
        sources.insert(source, at: 0)
        return source
    }

    private static let defaultSources: [SourceSummary] = [
            SourceSummary(
                id: "aot-s3e17",
                displayName: "Attack on Titan",
                helperText: "アニメ",
                mediaType: "anime",
                totalCount: 24,
                isFavorite: true
            ),
            SourceSummary(
                id: "spy-family-ep5",
                displayName: "SPY×FAMILY",
                helperText: "アニメ",
                mediaType: "anime",
                totalCount: 12,
                isFavorite: false
            ),
            SourceSummary(
                id: "frieren-ep14",
                displayName: "Frieren",
                helperText: "アニメ",
                mediaType: "anime",
                totalCount: 28,
                isFavorite: true
            ),
            SourceSummary(
                id: "yt-live-2026-07-01",
                displayName: "YouTube Live",
                helperText: "YouTubeライブ・配信",
                mediaType: "youtube_live",
                totalCount: nil,
                isFavorite: false
            ),
            SourceSummary(
                id: "haikyu-s2e24",
                displayName: "Haikyu!!",
                helperText: "アニメ",
                mediaType: "anime",
                totalCount: 25,
                isFavorite: false
            ),
            SourceSummary(
                id: "blue-lock-ep19",
                displayName: "Blue Lock",
                helperText: "アニメ",
                mediaType: "anime",
                totalCount: 24,
                isFavorite: false
            ),
            SourceSummary(
                id: "special-event-2026",
                displayName: "Special Event",
                helperText: "イベント・ファンミ",
                mediaType: "event_fanmeeting",
                totalCount: 2,
                isFavorite: true
            )
        ]
}
