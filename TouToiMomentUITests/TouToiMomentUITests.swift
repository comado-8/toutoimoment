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
        XCTAssertTrue(app.staticTexts["Kirito ・ Asuna"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPairsFavoriteFilterShowsOnlyFavoritePairs() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()
        app.buttons["Favorite"].tap()

        XCTAssertTrue(app.staticTexts["Yuri ・ Pik"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Kirito ・ Asuna"].exists)
    }

    @MainActor
    func testPairDetailOpensFromPairsList() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()
        app.staticTexts["Kirito ・ Asuna"].tap()

        XCTAssertTrue(app.staticTexts["Pair"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Sword Art Online"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Recent Moments"].waitForExistence(timeout: 2))
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

        let details = app.descendants(matching: .any)["moment.detail.details"]
        let detailScroll = app.scrollViews["moment.detail.scroll"]
        XCTAssertTrue(detailScroll.waitForExistence(timeout: 2))
        for _ in 0..<4 {
            detailScroll.swipeUp()
        }
        XCTAssertTrue(details.exists)
        XCTAssertGreaterThan(details.frame.minY, 0)
        XCTAssertLessThan(details.frame.maxY, app.buttons["Home"].frame.minY)

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
        XCTAssertTrue(app.buttons["moment.image.add.0"].waitForExistence(timeout: 2))

        let sceneEditor = app.textViews["moment.edit.scene"]
        XCTAssertTrue(sceneEditor.waitForExistence(timeout: 2))
        sceneEditor.tap()
        sceneEditor.typeText(" その瞬間、二人の間に流れていた空気がゆっくり変わって、言葉にできない気持ちがあふれ出した。")

        let saveButton = app.buttons["moment.edit.save"]
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
