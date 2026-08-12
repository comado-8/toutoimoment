import Foundation
import Testing
@testable import TouToiMoment

struct SourceLocatorSchemaTests {
    @Test func allMediaUseTheApprovedThreeLayerHierarchy() throws {
        let expected: [String: (episode: [String], moment: [String])] = [
            "anime": (["episode_kind", "episode"], ["timestamp"]),
            "tv_drama": (["episode_kind", "episode"], ["timestamp"]),
            "movie": ([], ["timestamp"]),
            "manga": (["manga_kind", "volume", "chapter"], ["page"]),
            "novel": (["novel_kind", "volume", "chapter"], ["page"]),
            "doujin_book": ([], ["page"]),
            "youtube_video": ([], ["timestamp"]),
            "streaming": ([], ["timestamp"]),
            "radio_podcast": (["radio_kind", "episode", "date"], ["timestamp"]),
            "music_video": ([], ["timestamp"]),
            "live_concert": ([], ["concert_part", "song"]),
            "stage_musical": ([], ["act", "scene"]),
            "event_fanmeeting": ([], []),
            "magazine": ([], ["page"]),
            "book_interview": ([], ["page"]),
            "sns_post": ([], ["slide"]),
            "blog_article": ([], []),
            "game": ([], ["chapter"]),
            "voice_drama": (["track_kind", "track"], ["timestamp"]),
            "other": ([], []),
        ]

        #expect(SourceLocatorSchema.all.count == 20)
        #expect(Set(SourceLocatorSchema.all.map(\.mediaType)) == Set(expected.keys))

        for schema in SourceLocatorSchema.all {
            let mapping = try #require(expected[schema.mediaType])
            #expect(schema.episodeFields.map(\.key) == mapping.episode)
            #expect(schema.momentLocationFields.map(\.key) == mapping.moment)
            #expect(
                Set(schema.episodeFields.map(\.key))
                    .isDisjoint(with: schema.momentLocationFields.map(\.key))
            )
            #expect(
                (schema.episodeFields + schema.momentLocationFields)
                    .allSatisfy { $0.inputKind != .timestamp || $0.key == "timestamp" }
            )
            #expect(!schema.sourceNameExample.isEmpty)
        }
    }

    @Test func numericPolicyNormalizesFullWidthAndRejectsInvalidValues() throws {
        let manga = try #require(SourceLocatorSchema.schema(for: "manga"))
        let volume = try #require(manga.episodeFields.first { $0.key == "volume" })
        let chapter = try #require(manga.episodeFields.first { $0.key == "chapter" })

        #expect(LocatorValuePolicy.normalized("１２", for: volume) == "12")
        #expect(LocatorValuePolicy.normalized("１２．５", for: chapter) == "12.5")
        #expect(LocatorValuePolicy.isValid("1", for: volume))
        #expect(!LocatorValuePolicy.isValid("0", for: volume))
        #expect(!LocatorValuePolicy.isValid("-1", for: volume))
        #expect(LocatorValuePolicy.isValid("0", for: chapter))
        #expect(LocatorValuePolicy.isValid("12.5", for: chapter))
        #expect(!LocatorValuePolicy.isValid("1.2.3", for: chapter))
        #expect(!LocatorValuePolicy.isValid("-0.5", for: chapter))
        #expect(LocatorValuePolicy.isValid("99999", for: volume))
        #expect(!LocatorValuePolicy.isValid("100000", for: volume))
        #expect(LocatorValuePolicy.isValid("99999.99", for: chapter))
        #expect(!LocatorValuePolicy.isValid("1.234", for: chapter))
        #expect(!LocatorValuePolicy.isValid("100000.00", for: chapter))
    }

    @Test func duplicateLocatorValuesUseTheLatestValue() throws {
        let anime = try #require(SourceLocatorSchema.schema(for: "anime"))
        let map = LocatorValuePolicy.valueMap(
            from: [
                .init(key: "episode", value: "1"),
                .init(key: "episode", value: "2"),
            ],
            fields: anime.episodeFields
        )

        #expect(map["episode"] == "2")
    }

    @Test func episodeRequirementsAndGeneratedNamesAreMediaAware() throws {
        let anime = try #require(SourceLocatorSchema.schema(for: "anime"))
        let manga = try #require(SourceLocatorSchema.schema(for: "manga"))
        let radio = try #require(SourceLocatorSchema.schema(for: "radio_podcast"))
        let voice = try #require(SourceLocatorSchema.schema(for: "voice_drama"))

        #expect(anime.episodeDisplayName(for: [
            .init(key: "episode_kind", value: "ova"),
            .init(key: "episode", value: "1"),
        ]) == "OVA 1")
        #expect(manga.episodeDisplayName(for: [
            .init(key: "manga_kind", value: "regular"),
            .init(key: "volume", value: "3"),
            .init(key: "chapter", value: "42"),
        ]) == "3巻・第42話")
        #expect(radio.episodeDisplayName(for: [
            .init(key: "radio_kind", value: "regular"),
            .init(key: "episode", value: "24"),
        ]) == "#24")
        #expect(voice.episodeDisplayName(for: [
            .init(key: "track_kind", value: "bonus"),
            .init(key: "track", value: "2"),
        ]) == "Bonus Track 2")

        #expect(!manga.isValidEpisodeValues(manga.initialEpisodeValues()))
        #expect(manga.isValidEpisodeValues([
            .init(key: "manga_kind", value: "regular"),
            .init(key: "volume", value: "2"),
            .init(key: "chapter", value: ""),
        ]))
        #expect(radio.isValidEpisodeValues([
            .init(key: "radio_kind", value: "regular"),
            .init(key: "episode", value: ""),
            .init(key: "date", value: "2026-07-25"),
        ]))
        #expect(!SourceLocatorSchema.fallback.supportsEpisodes)
    }
}
