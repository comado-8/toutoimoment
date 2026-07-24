import SwiftUI
import Testing
@testable import TouToiMoment

@MainActor
struct MomentEditTests {
    @Test func mapperKeepsEditableValuesAndUnknownReaction() {
        let moment = makeMoment(
            reactionIDs: ["legacy.custom"],
            reactionLabels: ["🫶 特別"]
        )

        let draft = MomentEditDraftMapper.draft(from: moment)

        #expect(draft.selectedPairID == moment.pairID)
        #expect(draft.selectedSourceID == moment.sourceID)
        #expect(draft.selectedSource?.mediaType == moment.mediaType)
        #expect(draft.contextValues.map(\.key) == ["episode", "timestamp"])
        #expect(draft.sceneSummary == moment.sceneText)
        #expect(draft.heartScream == moment.heartText)
        #expect(draft.selectedReactions.map(\.id) == ["legacy.custom"])
        #expect(draft.selectedReactions.map(\.displayText) == ["🫶 特別"])
    }

    @Test func viewModelRequiresARealChangeAndValidMomentBody() {
        let moment = makeMoment()
        let viewModel = MomentEditViewModel(
            moment: moment,
            pairRepository: InMemoryPairRepository(),
            sourceRepository: InMemorySourceRepository()
        )

        #expect(!viewModel.hasChanges)
        #expect(!viewModel.canSave)

        viewModel.updateScene("変更後のScene")

        #expect(viewModel.hasChanges)
        #expect(viewModel.canSave)

        viewModel.updateScene("  ")
        viewModel.updateHeart("\n")
        #expect(!viewModel.canSave)
    }

    @Test func changingSourceResetsContextAndSelectingTheSameSourceKeepsIt() async {
        let moment = makeMoment()
        let viewModel = MomentEditViewModel(
            moment: moment,
            pairRepository: InMemoryPairRepository(),
            sourceRepository: InMemorySourceRepository()
        )
        await viewModel.loadOptionsIfNeeded()

        viewModel.selectSource(id: moment.sourceID)
        #expect(viewModel.value(for: "episode") == "3")
        #expect(viewModel.value(for: "timestamp") == "00:18:42")

        viewModel.selectSource(id: "yt-live-2026-07-01")
        #expect(viewModel.draft.selectedSourceID == "yt-live-2026-07-01")
        #expect(viewModel.draft.contextValues.allSatisfy { $0.value.isEmpty })
    }

    @Test func storeUpdatePreservesIdentityFavoriteDateAndOrder() {
        var current = makeMoment(isFavorite: true)
        current.images = [
            MomentImage(
                id: "private-image",
                relativeFileName: "private-image.heic",
                createdAt: Date(),
                order: 0,
                pixelWidth: 1_000,
                pixelHeight: 800
            )
        ]
        let other = makeMoment(id: "other", isFavorite: false)
        let store = MomentStore(moments: [current, other])
        var draft = MomentEditDraftMapper.draft(from: current)
        draft.updateSceneSummary("更新したScene")
        draft.updateHeartScream("更新したHeart")
        draft.updateSelectedReactions([ReactionCatalog.allReactions[1]])

        let didUpdate = store.update(id: current.id, draft: draft)
        let updated = store.moment(id: current.id)

        #expect(didUpdate)
        #expect(store.moments.map(\.id) == [current.id, other.id])
        #expect(updated?.id == current.id)
        #expect(updated?.createdAt == current.createdAt)
        #expect(updated?.isFavorite == true)
        #expect(updated?.sceneText == "更新したScene")
        #expect(updated?.heartText == "更新したHeart")
        #expect(updated?.reactionIDs == ["positive.kyun"])
        #expect(updated?.images.map(\.id) == ["private-image"])
    }

    @Test func storeUpdateFailsWithoutChangingAnythingForMissingID() {
        let moment = makeMoment()
        let store = MomentStore(moments: [moment])
        let draft = MomentEditDraftMapper.draft(from: moment)

        #expect(!store.update(id: "missing", draft: draft))
        #expect(store.moments.map(\.id) == [moment.id])
    }

    @Test func scenePolicyLimitsByCharactersAndShowsTheCounterOnlyNearTheLimit() {
        let familyEmoji = "👨‍👩‍👧‍👦"
        let input = String(repeating: "あ", count: 999) + familyEmoji + "末"
        let limited = MomentSceneTextPolicy.limited(input)

        #expect(limited.count == 1_000)
        #expect(limited.hasSuffix(familyEmoji))
        #expect(!MomentSceneTextPolicy.shouldShowCounter(for: String(repeating: "a", count: 799)))
        #expect(MomentSceneTextPolicy.shouldShowCounter(for: String(repeating: "a", count: 800)))
        #expect(MomentSceneTextPolicy.counterText(for: String(repeating: "a", count: 900)) == "900 / 1000")
    }

    @Test func draftAndStoreKeepSceneWithinTheSharedLimit() {
        let overLimit = String(repeating: "Scene", count: 250) + "extra"
        var draft = NewMomentDraft(sceneSummary: overLimit)
        #expect(draft.sceneSummary.count == MomentSceneTextPolicy.maximumLength)

        draft.updateSceneSummary(overLimit + "more")
        #expect(draft.sceneSummary.count == MomentSceneTextPolicy.maximumLength)

        draft.selectPair(id: "pair", displayName: "A ・ B", nickname: "A ・ B")
        let store = MomentStore(moments: [])
        store.add(draft: draft)
        #expect(store.moments.first?.sceneText.count == MomentSceneTextPolicy.maximumLength)
    }

    private func makeMoment(
        id: String = "edit-target",
        reactionIDs: [String] = ["emotional.naita"],
        reactionLabels: [String] = ["😭 泣いた"],
        isFavorite: Bool = true
    ) -> MomentCardModel {
        MomentCardModel(
            id: id,
            sceneText: "元のScene",
            heartText: "元のHeart",
            caption: "3話 · 00:18:42",
            pairID: "pair-aoi-rin",
            pairName: "葵 ・ 凛",
            sourceID: "source-school-trip",
            sourceName: "修学旅行で仲良くないグループに...",
            mediaType: "anime",
            contextValues: [
                .init(key: "episode", value: "3"),
                .init(key: "timestamp", value: "00:18:42"),
            ],
            reactionIDs: reactionIDs,
            reactionLabels: reactionLabels,
            leadingDotColor: Color(hex: "#46C1B1"),
            trailingDotColor: Color(hex: "#F26767"),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            isFavorite: isFavorite
        )
    }
}
