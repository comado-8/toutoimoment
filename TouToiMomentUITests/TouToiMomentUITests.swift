//
//  TouToiMomentUITests.swift
//  TouToiMomentUITests
//
//  Created by 森田有美子 on 2026/07/09.
//

import XCTest

final class TouToiMomentUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()

        XCTAssertTrue(app.staticTexts["Pairs"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["New Pair"].waitForExistence(timeout: 2))
        XCTAssertTrue(
            app.descendants(matching: .any)["pairs.card.kirito-asuna"]
                .firstMatch
                .waitForExistence(timeout: 2)
        )
    }

    @MainActor
    func testProfileDrawerOpensAndDismissesFromTheDimmedArea() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["home.profile"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["profile.drawer"].waitForExistence(timeout: 2))

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertFalse(app.descendants(matching: .any)["profile.drawer"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testProfileDrawerRoutesToSettingsAndPremium() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["home.profile"].tap()
        app.buttons["profile.drawer.settings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["settings.screen"].waitForExistence(timeout: 2))

        app.buttons["settings.background"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["premium.screen"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPairsFavoriteFilterShowsOnlyFavoritePairs() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()
        app.buttons["Favorite"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["pairs.card.yuri-pik"]
                .firstMatch
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["pairs.card.kirito-asuna"]
                .firstMatch
                .exists
        )
    }

    @MainActor
    func testPairDetailOpensFromPairsList() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()
        app.descendants(matching: .any)["pairs.card.kirito-asuna"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["Pair"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Sword Art Online"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Moments"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["pair_detail.edit"].exists)

        let moreButton = app.buttons["pair_detail.more"]
        XCTAssertTrue(moreButton.exists)
        moreButton.tap()
        XCTAssertTrue(app.buttons["pair_detail.delete"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testEpisodeUnsupportedSourceShowsDirectMomentAndOpensDetail() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Sources"].tap()
        let sourceCard = app.descendants(matching: .any)["sources.card.special-event-2026"]
        for _ in 0..<5 {
            if sourceCard.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(sourceCard.waitForExistence(timeout: 2))
        sourceCard.tap()

        XCTAssertTrue(app.staticTexts["Moments"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Episodes"].exists)

        let momentCard = app.descendants(matching: .any)[
            "source_detail.moment.moment-special-event"
        ]
        XCTAssertTrue(momentCard.waitForExistence(timeout: 2))
        momentCard.tap()

        XCTAssertTrue(app.staticTexts["Moment"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["この景色をずっと覚えていたい"].exists)
    }

    @MainActor
    func testEpisodeDetailSwitchesTabsAndOnlyMomentCardNavigates() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Sources"].tap()
        let sourceCard = app.descendants(matching: .any)["sources.card.solo-leveling"]
        XCTAssertTrue(sourceCard.waitForExistence(timeout: 2))
        sourceCard.tap()

        let episodeCard = app.buttons["source_detail.episode.solo-leveling-ep08"]
        XCTAssertTrue(episodeCard.waitForExistence(timeout: 2))
        episodeCard.tap()

        XCTAssertTrue(app.navigationBars["Episode"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["episode_detail.hero"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.buttons["episode_detail.start_watching"].exists)
        XCTAssertTrue(app.buttons["episode_detail.edit"].exists)
        XCTAssertTrue(app.buttons["episode_detail.more"].exists)
        XCTAssertTrue(app.buttons["episode_detail.add_moment"].exists)
        XCTAssertTrue(app.buttons["Home"].exists)

        app.buttons["episode_detail.edit"].tap()
        XCTAssertTrue(
            app.buttons["new_episode.cancel"].waitForExistence(timeout: 2)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["new_episode.episode"].exists
        )
        app.buttons["new_episode.cancel"].tap()
        XCTAssertTrue(app.navigationBars["Episode"].waitForExistence(timeout: 2))

        app.buttons["episode_detail.start_watching"].tap()
        app.buttons["episode_detail.more"].tap()
        XCTAssertTrue(app.buttons["episode_detail.save_timeline"].exists)
        XCTAssertTrue(app.buttons["episode_detail.delete"].exists)
        app.buttons["episode_detail.save_timeline"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["episode_timeline_export.view"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.buttons["episode_timeline_export.save_image"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.buttons["episode_timeline_export.save_pdf"].exists)
        app.buttons["episode_timeline_export.close"].tap()
        XCTAssertTrue(app.navigationBars["Episode"].waitForExistence(timeout: 2))
        app.buttons["episode_detail.add_moment"].tap()
        XCTAssertTrue(
            app.staticTexts["New TouToi Moment"].waitForExistence(timeout: 2)
        )
        app.buttons["閉じる"].tap()
        XCTAssertTrue(app.navigationBars["Episode"].waitForExistence(timeout: 2))

        let tabs = app.descendants(matching: .any)["episode_detail.tabs"]
        XCTAssertTrue(tabs.waitForExistence(timeout: 2))
        XCTAssertTrue(
            app.staticTexts["episode_detail.timeline.title"]
                .waitForExistence(timeout: 2)
        )

        app.buttons["episode_detail.tab.watchHistory"].tap()
        XCTAssertFalse(app.staticTexts["episode_detail.timeline.title"].exists)
        app.buttons["episode_detail.more"].tap()
        XCTAssertFalse(app.buttons["episode_detail.save_timeline"].exists)
        XCTAssertTrue(app.buttons["episode_detail.delete"].exists)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let historyCard = app.descendants(matching: .any)[
            "episode_detail.history.solo-ep08-session-1"
        ]
        XCTAssertTrue(historyCard.waitForExistence(timeout: 2))
        historyCard.tap()
        XCTAssertTrue(app.navigationBars["Watch History"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["watch_history_detail.summary"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["watch_history_detail.live_log"]
                .waitForExistence(timeout: 2)
        )
        let moreButton = app.buttons["watch_history_detail.more"]
        XCTAssertTrue(moreButton.exists)
        moreButton.tap()
        XCTAssertTrue(
            app.buttons["watch_history_detail.save_live_log"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.buttons["watch_history_detail.delete"].exists)
        app.buttons["watch_history_detail.save_live_log"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["live_log_export.view"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.buttons["live_log_export.save_image"]
                .waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.buttons["live_log_export.save_pdf"].exists)
        app.buttons["live_log_export.close"].tap()
        XCTAssertTrue(
            app.navigationBars["Watch History"].waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.buttons["Home"].exists)

        app.navigationBars["Watch History"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Episode"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["episode_detail.tab.moments"].exists)
        XCTAssertTrue(app.buttons["Home"].exists)

        app.buttons["episode_detail.tab.moments"].tap()
        XCTAssertTrue(
            app.staticTexts["episode_detail.timeline.title"]
                .waitForExistence(timeout: 2)
        )
        let momentCard = app.descendants(matching: .any)[
            "episode_detail.moment.moment-solo-leveling-ep08-eye-contact"
        ]
        XCTAssertTrue(momentCard.waitForExistence(timeout: 2))
        momentCard.tap()
        XCTAssertTrue(app.staticTexts["Moment"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testEpisodeDetailWithoutMomentsHidesTimelineHeading() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Sources"].tap()
        let sourceCard = app.descendants(matching: .any)["sources.card.solo-leveling"]
        XCTAssertTrue(sourceCard.waitForExistence(timeout: 2))
        sourceCard.tap()

        let episodeCard = app.buttons["source_detail.episode.solo-leveling-ep07"]
        XCTAssertTrue(episodeCard.waitForExistence(timeout: 2))
        episodeCard.tap()

        XCTAssertTrue(app.navigationBars["Episode"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["episode_detail.moments.empty"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(app.staticTexts["episode_detail.timeline.title"].exists)
    }

    @MainActor
    func testStreamingSourceShowsRequiredPlatformChoicesAndOtherField() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Sources"].tap()
        app.buttons["sources.new_source"].tap()

        let streamingMedium = app.buttons["new_source.medium.streaming"]
        for _ in 0..<4 {
            if streamingMedium.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(streamingMedium.waitForExistence(timeout: 2))
        streamingMedium.tap()

        XCTAssertTrue(
            app.buttons["new_source.streaming_platform.youtube"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.buttons["new_source.streaming_platform.instagram"].exists)
        XCTAssertTrue(app.buttons["new_source.streaming_platform.twitch"].exists)

        app.buttons["new_source.streaming_platform.other"].tap()
        XCTAssertTrue(
            app.textFields["new_source.streaming_platform.other_name"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(app.buttons["new_source.save"].isEnabled)
    }

    @MainActor
    func testMomentsSearchHidesBottomTabBarWhileKeyboardIsVisible() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Moments"].tap()
        let searchField = app.textFields["moments.search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Home"].exists)

        searchField.tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Home"].exists)

        searchField.typeText("\n")
        XCTAssertTrue(app.buttons["Home"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testMomentsFloatingButtonAndLastCardDoNotOverlap() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Moments"].tap()

        let addButton = app.buttons["moments.add"]
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        XCTAssertTrue(homeTab.waitForExistence(timeout: 2))
        XCTAssertLessThan(addButton.frame.maxY, homeTab.frame.minY)

        let lastCard = app.descendants(matching: .any)["moments.card.moment-live-ep10"]
        let scrollView = app.scrollViews["moments.scroll"]
        XCTAssertTrue(scrollView.waitForExistence(timeout: 2))
        let dragStart = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.85))
        let dragEnd = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.25))
        dragStart.press(forDuration: 0.1, thenDragTo: dragEnd)
        XCTAssertTrue(lastCard.waitForExistence(timeout: 2))
        XCTAssertLessThan(lastCard.frame.maxY, addButton.frame.minY)
    }

    @MainActor
    func testNewMomentStartsWithRequiredHeartScreamAndKeepsItInDetails() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Moments"].tap()
        app.buttons["moments.add"].tap()

        let heartEditor = app.textViews["new_moment.heart_scream.input"]
        let heartNext = app.buttons["new_moment.heart_scream.next"]
        XCTAssertTrue(heartEditor.waitForExistence(timeout: 2))
        XCTAssertFalse(heartNext.isEnabled)

        heartEditor.tap()
        heartEditor.typeText("尊い……！")
        XCTAssertTrue(heartNext.isEnabled)
        heartNext.tap()

        let sceneNext = app.buttons["new_moment.scene.next"]
        XCTAssertTrue(sceneNext.waitForExistence(timeout: 2))
        XCTAssertTrue(sceneNext.isEnabled)
        sceneNext.tap()

        XCTAssertTrue(app.descendants(matching: .any)["new_moment.details"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["尊い……！"].exists)
        XCTAssertFalse(app.buttons["new_moment.details.save"].isEnabled)
    }

    @MainActor
    func testMomentsHeaderClipsCardsAndBothCardFacesKeepFavoriteInteractive() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Moments"].tap()

        let filters = app.scrollViews["moments.filters"]
        let momentsScroll = app.scrollViews["moments.scroll"]
        XCTAssertTrue(filters.waitForExistence(timeout: 2))
        XCTAssertTrue(momentsScroll.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(momentsScroll.frame.minY, filters.frame.maxY)

        let firstCard = app.descendants(matching: .any)["moments.card.moment-school-trip-ep3-scene-1"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))

        app.buttons["moments.face.heart"].tap()
        XCTAssertTrue(firstCard.staticTexts["目から汗止まらん"].waitForExistence(timeout: 2))

        var favorite = firstCard.buttons["moments.card.favorite"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 2))
        let heartFavoriteValue = favorite.value as? String
        favorite.tap()
        favorite = firstCard.buttons["moments.card.favorite"]
        XCTAssertTrue(waitForValueChange(of: favorite, from: heartFavoriteValue))

        firstCard.swipeLeft()
        XCTAssertTrue(firstCard.staticTexts["待ってるよ。\nあの場所で。"].waitForExistence(timeout: 2))

        favorite = firstCard.buttons["moments.card.favorite"]
        let sceneFavoriteValue = favorite.value as? String
        favorite.tap()
        favorite = firstCard.buttons["moments.card.favorite"]
        XCTAssertTrue(waitForValueChange(of: favorite, from: sceneFavoriteValue))

        firstCard.swipeLeft()
        XCTAssertTrue(firstCard.staticTexts["目から汗止まらん"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testMomentDetailAndShareOpenFromMomentCard() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Moments"].tap()

        let firstCard = app.descendants(matching: .any)["moments.card.moment-school-trip-ep3-scene-1"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        firstCard.tap()

        let hero = app.otherElements["moment.detail.hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: 2))
        XCTAssertLessThanOrEqual(hero.frame.height, 260)
        let pairChip = app.staticTexts["moment.detail.hero.pair"]
        XCTAssertTrue(pairChip.waitForExistence(timeout: 2))
        XCTAssertEqual(hero.frame.maxY - pairChip.frame.maxY, 28, accuracy: 2)
        XCTAssertTrue(app.buttons["moment.image.add.0"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["moment.image.add.1"].exists)
        XCTAssertTrue(app.buttons["moment.image.add.2"].exists)
        let memoriesTitle = app.staticTexts["Fan Memories"]
        let memoriesDescription = app.staticTexts[
            "聖地巡りやグッズなど、Momentにまつわる推し活の写真を残してみよう。"
        ]
        let heartTitle = app.staticTexts["HeartScream"]
        let reactionTitle = app.staticTexts["Reaction"]
        XCTAssertTrue(memoriesTitle.exists)
        XCTAssertTrue(memoriesDescription.exists)
        XCTAssertTrue(heartTitle.exists)
        XCTAssertTrue(reactionTitle.exists)
        XCTAssertGreaterThan(reactionTitle.frame.minY, heartTitle.frame.maxY)
        XCTAssertGreaterThan(memoriesTitle.frame.minY, reactionTitle.frame.maxY)

        let moreButton = app.buttons["moment.detail.more"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 2))
        moreButton.tap()
        let shareButton = app.buttons["moment.detail.share"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 2))
        shareButton.tap()

        XCTAssertTrue(app.buttons["moment.share.action"].waitForExistence(timeout: 2))
        let customization = app.descendants(matching: .any)["moment.share.customize"]
        XCTAssertTrue(customization.waitForExistence(timeout: 2))
        XCTAssertTrue(customization.isHittable)
        let reactionToggle = app.switches["moment.share.toggle.reaction"]
        XCTAssertTrue(reactionToggle.waitForExistence(timeout: 2))
        reactionToggle.tap()
        let closeButton = app.buttons["moment.share.close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        closeButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["moment.detail.hero"].waitForExistence(timeout: 2))
        XCTAssertTrue(
            app.staticTexts["moment.detail.hero.date"].waitForExistence(timeout: 2)
        )

        let details = app.descendants(matching: .any)["moment.detail.details"]
        XCTAssertFalse(details.exists)

        app.buttons["Home"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["home.screen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.descendants(matching: .any)["moment.detail.hero"].exists)
    }

    @MainActor
    func testMomentEditOpensFromDetailAndHidesBottomTabBar() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Moments"].tap()
        let firstCard = app.descendants(matching: .any)["moments.card.moment-school-trip-ep3-scene-1"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        firstCard.tap()

        let editButton = app.buttons["moment.detail.edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        editButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["moment.edit.form"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Home"].exists)
        XCTAssertFalse(app.buttons["moment.image.add.0"].exists)

        let sceneEditor = app.textViews["moment.edit.scene"]
        XCTAssertTrue(sceneEditor.waitForExistence(timeout: 2))
        sceneEditor.tap()
        sceneEditor.typeText(" その瞬間、二人の間に流れていた空気がゆっくり変わって、言葉にできない気持ちがあふれ出した。")

        let saveButton = app.buttons["moment.edit.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        let hero = app.otherElements["moment.detail.hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: 2))
        let expansionButton = app.buttons["moment.detail.scene-expansion"]
        XCTAssertTrue(expansionButton.waitForExistence(timeout: 2))
        let pairChip = app.staticTexts["moment.detail.hero.pair"]
        XCTAssertEqual(hero.frame.maxY - pairChip.frame.maxY, 28, accuracy: 2)

        expansionButton.tap()
        XCTAssertEqual(expansionButton.label, "閉じる")
        XCTAssertEqual(hero.frame.maxY - pairChip.frame.maxY, 28, accuracy: 2)
        XCTAssertTrue(app.buttons["Home"].exists)
    }

    private func waitForValueChange(
        of element: XCUIElement,
        from originalValue: String?,
        timeout: TimeInterval = 2
    ) -> Bool {
        let predicate = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElement else { return false }
            return element.value as? String != originalValue
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
