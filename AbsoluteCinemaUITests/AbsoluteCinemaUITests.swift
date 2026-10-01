import XCTest

final class AbsoluteCinemaUITests: XCTestCase {
    @MainActor
    func testSearchAndRatingsTabsAreAvailable() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 10))
        let ratingsTab = app.tabBars.buttons["Мои оценки"]
        XCTAssertTrue(ratingsTab.exists)
        ratingsTab.tap()
        XCTAssertTrue(app.buttons["Сбросить сортировку"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Поиск"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.exists)
    }
}
