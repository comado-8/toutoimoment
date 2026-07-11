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
        XCTAssertTrue(app.staticTexts["Kirito ･ Asuna"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPairsFavoriteFilterShowsOnlyFavoritePairs() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()
        app.buttons["Favorite"].tap()

        XCTAssertTrue(app.staticTexts["Yuri ･ Pik"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Kirito ･ Asuna"].exists)
    }

    @MainActor
    func testPairDetailOpensFromPairsList() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Pairs"].tap()
        app.staticTexts["Kirito ･ Asuna"].tap()

        XCTAssertTrue(app.staticTexts["Pair"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Sword Art Online"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Recent Moments"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
