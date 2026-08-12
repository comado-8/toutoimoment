import SwiftUI
import Testing
@testable import TouToiMoment

@MainActor
struct MomentMetadataDisplayTests {
    @Test func titledMomentKeepsSourceEpisodeAndContextSeparate() {
        let store = MomentStore(moments: [])
        let draft = NewMomentDraft(
            selectedSource: .init(
                id: "source-new",
                displayName: "新しいSource",
                helperText: "",
                mediaType: "anime"
            ),
            selectedEpisode: .init(
                id: "episode-12",
                sourceID: "source-new",
                locatorValues: [
                    .init(key: "episode_kind", value: "regular"),
                    .init(key: "episode", value: "12"),
                ],
                displayName: "第12話"
            ),
            contextValues: [.init(key: "timestamp", value: "00:18:42")],
            momentTitle: "2人の出会い",
            heartScream: "尊い",
            contextMediaType: "anime"
        )

        let moment = store.add(draft: draft)

        #expect(moment.title == "2人の出会い")
        #expect(moment.caption == "新しいSource")
        #expect(moment.cardSourceLabel == "新しいSource")
        #expect(moment.episodeDisplayLabel == "第12話")
        #expect(moment.cardLocationLabel == "第12話")
        #expect(MomentContextDisplayFormatter.timestamp(for: moment) == "00:18:42")
    }

    @Test func titledMomentWithoutEpisodeDoesNotDuplicateTimestampAsSource() {
        let store = MomentStore(moments: [])
        let draft = NewMomentDraft(
            selectedSource: .init(
                id: "source-new",
                displayName: "新しいSource",
                helperText: "",
                mediaType: "anime"
            ),
            contextValues: [.init(key: "timestamp", value: "00:18:42")],
            momentTitle: "2人の出会い",
            heartScream: "尊い",
            contextMediaType: "anime"
        )

        let moment = store.add(draft: draft)

        #expect(moment.cardSourceLabel == "新しいSource")
        #expect(moment.episodeDisplayLabel == nil)
        #expect(moment.cardLocationLabel == "00:18:42")
        #expect(moment.cardSourceLabel != moment.cardLocationLabel)
    }

    @Test func clearingSourceDoesNotResurrectLegacyCaption() {
        var moment = MomentCardModel.preview[0]
        moment.sourceID = nil
        moment.sourceName = "—"
        moment.episodeID = nil
        moment.episodeLocatorValues = []

        #expect(moment.caption.nilIfPlaceholder != nil)
        #expect(moment.cardSourceLabel == "—")
        #expect(moment.cardLocationLabel == "00:18:42")
    }
}
