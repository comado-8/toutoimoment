import Foundation
import SwiftUI
import Testing
import UIKit
@testable import TouToiMoment

@MainActor
struct MomentListTests {
    @Test func globalFaceSwitchAndIndividualOverrideRemainIndependent() {
        let store = MomentStore()
        let viewModel = MomentListViewModel(store: store)
        let firstID = store.moments[0].id
        let secondID = store.moments[1].id

        viewModel.setAllFaces(.heart)
        #expect(viewModel.face(for: firstID) == .heart)
        #expect(viewModel.face(for: secondID) == .heart)

        viewModel.toggleFace(for: firstID)
        #expect(viewModel.face(for: firstID) == .scene)
        #expect(viewModel.face(for: secondID) == .heart)
        #expect(viewModel.selectedGlobalFace == .heart)
    }

    @Test func searchMatchesAllMomentMetadata() {
        let store = MomentStore()
        let viewModel = MomentListViewModel(store: store)

        viewModel.filter.query = "pounding"
        #expect(viewModel.displayedMoments.map(\.id) == ["moment-school-trip-ep6-scene-1"])

        viewModel.filter.query = "真夏"
        #expect(viewModel.displayedMoments.map(\.id) == ["moment-drama-ep8"])

        viewModel.filter.query = "ステージの最後"
        #expect(viewModel.displayedMoments.map(\.id) == ["moment-live-ep10"])
    }

    @Test func categoryFiltersCombineWithAndAndResetTogether() {
        let store = MomentStore()
        let viewModel = MomentListViewModel(store: store)

        viewModel.filter.favoritesOnly = true
        viewModel.filter.selectedPairID = "pair-kei-yu"
        viewModel.filter.selectedSourceID = "source-summer-drama"
        viewModel.filter.selectedReactionID = "excited.shougeki"

        #expect(viewModel.displayedMoments.map(\.id) == ["moment-drama-ep8"])

        viewModel.resetSelections()
        #expect(!viewModel.filter.hasActiveSelection)
        #expect(viewModel.displayedMoments.count == store.moments.count)
    }

    @Test func favoriteChangesAreSharedByTheStore() {
        let store = MomentStore()
        let id = "moment-school-trip-ep6-scene-2"
        #expect(!store.moments.first(where: { $0.id == id })!.isFavorite)

        store.toggleFavorite(id: id)

        #expect(store.moments.first(where: { $0.id == id })!.isFavorite)
        #expect(store.favoriteMoments.contains(where: { $0.id == id }))
    }

    @Test func savedDraftIsInsertedAtTheBeginning() {
        let store = MomentStore(moments: [])
        let reaction = ReactionCatalog.reaction(withID: "emotional.kandou")!
        let draft = NewMomentDraft(
            selectedPair: .init(
                id: "pair-new",
                displayName: "Member 1 × Member 2",
                nickname: "Pair"
            ),
            selectedSource: .init(
                id: "source-new",
                displayName: "新しいSource",
                helperText: "",
                mediaType: "anime",
                totalCount: 12,
                isFavorite: false
            ),
            contextValues: [
                .init(key: "episode", value: "12"),
                .init(key: "timestamp", value: "00:18:42")
            ],
            sceneSummary: "忘れられない場面",
            heartScream: "尊い",
            selectedReactions: [reaction],
            contextMediaType: "anime"
        )

        store.add(draft: draft)

        #expect(store.moments.count == 1)
        #expect(store.moments[0].sceneText == "忘れられない場面")
        #expect(store.moments[0].heartText == "尊い")
        #expect(store.moments[0].episodeLabel == "EP12")
        #expect(store.moments[0].pairID == "pair-new")
        #expect(store.moments[0].pairName == "Member 1 ・ Member 2")
        #expect(store.moments[0].reactionIDs == ["emotional.kandou"])
        #expect(store.moments[0].reactionLabels == ["🥹 感動"])
        #expect(store.moments[0].mediaType == "anime")
        #expect(store.moments[0].contextValues == [
            .init(key: "episode", value: "12"),
            .init(key: "timestamp", value: "00:18:42")
        ])
        #expect(store.moments[0].createdAt <= Date())

        let viewModel = MomentListViewModel(store: store)
        viewModel.filter.query = "🥹 感動"
        #expect(viewModel.displayedMoments.map(\.id) == [store.moments[0].id])
    }

    @Test func pairDisplayNamesUseTheFullWidthMiddleDot() async throws {
        #expect(PairDisplayNameFormatter.normalized("A×B") == "A ・ B")
        #expect(PairDisplayNameFormatter.normalized("A ･ B") == "A ・ B")
        #expect(PairDisplayNameFormatter.normalized("A • B") == "A ・ B")
        #expect(PairDisplayNameFormatter.normalized("A・B") == "A ・ B")
        #expect(PairDisplayNameFormatter.normalized("きりあす") == "きりあす")
        #expect(PairDisplayNameFormatter.joined(" Member 1 ", " Member 2 ") == "Member 1 ・ Member 2")

        let sources = try await InMemorySourceRepository().fetchSources()
        #expect(sources.contains(where: { $0.displayName == "SPY×FAMILY" }))
    }

    @Test func reactionOptionsUseCatalogOrderAndEmojiLabels() {
        let viewModel = MomentListViewModel(store: MomentStore())

        #expect(viewModel.reactionOptions == [
            MomentFilterOption(id: "positive.kyun", label: "🥰 キュン"),
            MomentFilterOption(id: "emotional.naita", label: "😭 泣いた"),
            MomentFilterOption(id: "excited.shougeki", label: "🤯 衝撃"),
            MomentFilterOption(id: "excited.saikou", label: "💥 最高"),
        ])
    }

    @Test func bottomTabBarIsHiddenWheneverTheKeyboardIsVisible() {
        #expect(AppChromeVisibility.shouldShowBottomTabBar(
            navigationHidesBottomTabBar: false,
            isKeyboardVisible: false
        ))
        #expect(!AppChromeVisibility.shouldShowBottomTabBar(
            navigationHidesBottomTabBar: false,
            isKeyboardVisible: true
        ))
        #expect(!AppChromeVisibility.shouldShowBottomTabBar(
            navigationHidesBottomTabBar: true,
            isKeyboardVisible: false
        ))
    }

    @Test func glowPaletteAssignmentIsStableAndWithinFigmaPalette() {
        let ids = MomentCardModel.preview.map(\.id)

        for id in ids {
            let first = MomentGlowPalette.index(for: id)
            let second = MomentGlowPalette.index(for: id)
            #expect(first == second)
            #expect((0..<MomentGlowPalette.count).contains(first))
        }
    }

    @Test func cardFlipMotionKeepsRepeatedSwipesMovingInTheSameDirection() {
        let heartAngle = MomentCardFlipMotion.targetAngle(from: 0, direction: .left)
        let sceneAngle = MomentCardFlipMotion.targetAngle(from: heartAngle, direction: .left)

        #expect(heartAngle == -180)
        #expect(sceneAngle == -360)
        #expect(MomentCardFlipMotion.face(for: heartAngle) == .heart)
        #expect(MomentCardFlipMotion.face(for: sceneAngle) == .scene)

        let returnedHeartAngle = MomentCardFlipMotion.targetAngle(
            from: sceneAngle,
            direction: .right
        )
        #expect(returnedHeartAngle == -180)
        #expect(MomentCardFlipMotion.face(for: returnedHeartAngle) == .heart)
    }

    @Test func cardFlipMotionUsesDistancePredictionAndHorizontalDominance() {
        #expect(MomentCardFlipMotion.isHorizontal(horizontal: -50, vertical: 20))
        #expect(!MomentCardFlipMotion.isHorizontal(horizontal: -40, vertical: 40))
        #expect(MomentCardFlipMotion.dragAngle(horizontal: -87.5, vertical: 0) == -90)
        #expect(MomentCardFlipMotion.dragAngle(horizontal: 400, vertical: 0) == 180)

        #expect(MomentCardFlipMotion.shouldCommit(
            horizontal: -44,
            predictedHorizontal: -44
        ))
        #expect(MomentCardFlipMotion.shouldCommit(
            horizontal: -20,
            predictedHorizontal: -100
        ))
        #expect(!MomentCardFlipMotion.shouldCommit(
            horizontal: -20,
            predictedHorizontal: -80
        ))
    }

    @Test func cardFlipDepthIsOnlyAppliedNearTheEdge() {
        #expect(abs(MomentCardFlipMotion.shadeOpacity(for: 0)) < 0.000_001)
        #expect(abs(MomentCardFlipMotion.scale(for: 0) - 1) < 0.000_001)
        #expect(abs(MomentCardFlipMotion.shadeOpacity(for: 90) - 0.08) < 0.000_001)
        #expect(abs(MomentCardFlipMotion.scale(for: 90) - 0.985) < 0.000_001)
        #expect(MomentCardFlipMotion.rebasedAngle(720) == 0)
        #expect(MomentCardFlipMotion.rebasedAngle(-900) == -180)
    }

    @Test func contextFormatterKeepsAllEnteredFieldsAndUsesMediaAwareCardLabel() {
        let moment = MomentCardModel.preview[0]
        let items = MomentContextDisplayFormatter.items(for: moment)

        #expect(items.map(\.key) == ["episode", "timestamp"])
        #expect(items.map(\.value) == ["3話", "00:18:42"])
        #expect(MomentContextDisplayFormatter.cardLabel(for: moment) == "EP3")
        #expect(MomentContextDisplayFormatter.timestamp(for: moment) == "00:18:42")
        #expect(MomentShareEpisodeTypography.usesJapaneseFont(for: "6話"))
        #expect(!MomentShareEpisodeTypography.usesJapaneseFont(for: "EP.06"))
    }

    @Test func relatedMomentsPreferSourceThenFillFromPairWithoutDuplicates() {
        let current = makeMoment(id: "current", sourceID: "source-a", pairID: "pair-a")
        let source1 = makeMoment(id: "source-1", sourceID: "source-a", pairID: "pair-b")
        let source2 = makeMoment(id: "source-2", sourceID: "source-a", pairID: "pair-a")
        let source3 = makeMoment(id: "source-3", sourceID: "source-a", pairID: "pair-a")
        let pairOnly = makeMoment(id: "pair-only", sourceID: "source-b", pairID: "pair-a")
        let store = MomentStore(moments: [current, source1, source2, source3, pairOnly])

        let related = store.relatedMoments(for: current.id)

        #expect(related.sameSource.map(\.id) == ["source-1", "source-2"])
        #expect(related.samePair.map(\.id) == ["source-3"])
        #expect(Set((related.sameSource + related.samePair).map(\.id)).count == 3)
    }

    @Test func shareConfigurationUsesHeartScreamWithoutSceneFallback() {
        let complete = MomentCardModel.preview[0]
        #expect(
            MomentShareConfiguration.initial(for: complete).heartText(for: complete)
                == "目から汗止まらん"
        )

        let sceneOnly = makeMoment(
            id: "scene-only-share",
            sourceID: nil,
            pairID: nil,
            sceneText: "記録用Scene",
            heartText: ""
        )
        #expect(MomentShareConfiguration.initial(for: sceneOnly).heartText(for: sceneOnly) == nil)
        #expect(!MomentShareTextFormatter.text(for: sceneOnly).contains("記録用Scene"))
    }

    @Test func shareTextUsesHeartScreamAndVisibilityConfiguration() {
        var complete = MomentCardModel.preview[0]
        complete.images = [
            MomentImage(
                id: "private-reference",
                relativeFileName: "must-not-be-shared.heic",
                createdAt: Date(),
                order: 0,
                pixelWidth: 2_048,
                pixelHeight: 1_365
            )
        ]
        #expect(MomentShareConfiguration.initial(for: complete).showsReaction)
        #expect(!MomentShareTextFormatter.text(for: complete).contains("must-not-be-shared"))
        #expect(MomentShareTextFormatter.text(for: complete) == [
            "目から汗止まらん",
            "修学旅行で仲良くないグループに... 3話 · 00:18:42",
            "葵 ・ 凛",
            "😭 泣いた",
            "#TouToiMoment"
        ].joined(separator: "\n"))

        let withoutOptionalInformation = MomentShareConfiguration(
            showsPair: false,
            showsReaction: false,
            showsHashtag: false
        )
        #expect(
            MomentShareTextFormatter.text(
                for: complete,
                configuration: withoutOptionalInformation
            ) == [
                "目から汗止まらん",
                "修学旅行で仲良くないグループに... 3話 · 00:18:42"
            ].joined(separator: "\n")
        )

        let withoutReaction = MomentShareConfiguration(showsReaction: false)
        #expect(
            MomentShareTextFormatter.text(
                for: complete,
                configuration: withoutReaction
            ) == [
                "目から汗止まらん",
                "修学旅行で仲良くないグループに... 3話 · 00:18:42",
                "葵 ・ 凛",
                "#TouToiMoment"
            ].joined(separator: "\n")
        )

        let minimal = makeMoment(
            id: "heart-only",
            sourceID: nil,
            pairID: nil,
            sceneText: "",
            heartText: "尊い"
        )
        #expect(MomentShareTextFormatter.text(for: minimal) == "尊い\n#TouToiMoment")
    }

    @Test func shareCardRendersAtTheExportSize() {
        let image = MomentShareImageRenderer.image(
            for: MomentCardModel.preview[0],
            configuration: .initial(for: MomentCardModel.preview[0])
        )

        #expect(image != nil)
        #expect(image?.size.width == 342)
        #expect(image?.size.height == 612)
        #expect(image?.scale == 3)

        let transparentAlphaFormats: [CGImageAlphaInfo] = [
            .first, .last, .premultipliedFirst, .premultipliedLast
        ]
        #expect(
            image?.cgImage.map { transparentAlphaFormats.contains($0.alphaInfo) } == true
        )
    }

    @Test func shareCardRendersWithLongHeartTextWithoutFailing() {
        let longHeart = Array(
            repeating: "目が合った瞬間、胸がぎゅっとなって息をするのも忘れそうになった。",
            count: 4
        )
        .joined()
        let moment = makeMoment(
            id: "long-heart-share",
            sourceID: "source-a",
            pairID: "pair-a",
            sceneText: "君、昨日の子だよね？",
            heartText: longHeart,
            reactionIDs: ["positive.kyun", "emotional.naita"],
            reactionLabels: ["🥰 キュン", "😭 泣いた"]
        )

        let image = MomentShareImageRenderer.image(
            for: moment,
            configuration: .initial(for: moment)
        )

        #expect(image != nil)

        let hiddenReactionImage = MomentShareImageRenderer.image(
            for: moment,
            configuration: MomentShareConfiguration(showsReaction: false)
        )
        #expect(hiddenReactionImage != nil)
    }

    @Test func photoSaveCoordinatorMapsSuccessPermissionAndFailureUsingFakeSaver() async {
        let image = UIImage()
        let successSaver = FakeMomentPhotoLibrarySaver(result: .success(()))
        #expect(
            await MomentPhotoSaveCoordinator.save(image, using: successSaver) == .success
        )
        #expect(successSaver.saveCallCount == 1)

        let deniedSaver = FakeMomentPhotoLibrarySaver(result: .failure(.accessDenied))
        #expect(
            await MomentPhotoSaveCoordinator.save(image, using: deniedSaver) == .accessDenied
        )

        let failedSaver = FakeMomentPhotoLibrarySaver(result: .failure(.saveFailed))
        #expect(
            await MomentPhotoSaveCoordinator.save(image, using: failedSaver) == .saveFailed
        )
    }

    private func makeMoment(
        id: String,
        sourceID: String?,
        pairID: String?,
        sceneText: String = "Scene \(UUID().uuidString)",
        heartText: String = "Heart",
        reactionIDs: [String] = [],
        reactionLabels: [String] = []
    ) -> MomentCardModel {
        MomentCardModel(
            id: id,
            sceneText: sceneText,
            heartText: heartText,
            caption: "",
            pairID: pairID,
            pairName: pairID == nil ? "—" : "A ・ B",
            sourceID: sourceID,
            sourceName: sourceID == nil ? "—" : "Source",
            mediaType: sourceID == nil ? nil : "anime",
            contextValues: [],
            reactionIDs: reactionIDs,
            reactionLabels: reactionLabels,
            leadingDotColor: .blue,
            trailingDotColor: .pink,
            createdAt: Date(timeIntervalSince1970: 0),
            isFavorite: false
        )
    }
}

@MainActor
private final class FakeMomentPhotoLibrarySaver: MomentPhotoLibrarySaving {
    let result: Result<Void, MomentPhotoLibrarySaveError>
    private(set) var saveCallCount = 0

    init(result: Result<Void, MomentPhotoLibrarySaveError>) {
        self.result = result
    }

    func save(_ image: UIImage) async throws {
        saveCallCount += 1
        try result.get()
    }
}
