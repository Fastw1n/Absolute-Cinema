import XCTest

final class AbsoluteCinemaUITests: XCTestCase {
    @MainActor
    func testAppLaunchesAndOpensRatings() {
        let app = XCUIApplication()
        app.launch()
        let searchButton = app.buttons["Поиск фильмов"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 10))
        searchButton.tap()
        XCTAssertTrue(app.staticTexts["2001 год: Космическая одиссея"].waitForExistence(timeout: 5))
        let ratingsTab = app.tabBars.buttons["Мои оценки"]
        XCTAssertTrue(ratingsTab.exists)
        ratingsTab.tap()
        XCTAssertTrue(app.navigationBars["Мои оценки"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Поиск"].tap()
        XCTAssertTrue(searchButton.exists)
    }
}
