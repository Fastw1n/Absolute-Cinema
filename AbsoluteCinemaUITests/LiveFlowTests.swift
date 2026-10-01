import XCTest

/// Опциональная проверка реального API. В обычном запуске тестов пропускается.
final class LiveFlowTests: XCTestCase {
    @MainActor
    func testSearchCreateReadUpdateDeleteComment() throws {
        guard ProcessInfo.processInfo.environment["FILMGRAPH_LIVE_SMOKE"] == "1" else {
            throw XCTSkip("Для живого API запустите с TEST_RUNNER_FILMGRAPH_LIVE_SMOKE=1")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("2001")
        let title = "2001 год: Космическая одиссея"
        let film = app.staticTexts[title].firstMatch
        XCTAssertTrue(film.waitForExistence(timeout: 30))
        film.tap()

        let rating = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Моя оценка")).firstMatch
        scrollTo(rating, in: app)
        XCTAssertTrue(rating.waitForExistence(timeout: 30))
        let existing = app.buttons["Убрать оценку и комментарий"]
        if existing.exists {
            scrollTo(existing, in: app)
            existing.tap()
            scrollTo(rating, in: app)
        }
        rating.tap()
        app.buttons["8 из 10"].tap()
        let editor = app.textViews.firstMatch
        scrollTo(editor, in: app)
        editor.tap()
        editor.typeText("A personal comment.\nSaved on device.")
        let save = app.buttons["Сохранить оценку"]
        scrollTo(save, in: app)
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(app.staticTexts["Оценка и комментарий сохранены"].waitForExistence(timeout: 5))
        attachScreenshot(app, name: "Movie details and saved comment")
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Мои оценки"].tap()
        XCTAssertTrue(app.staticTexts["Моя оценка: 8 / 10"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A personal comment.\nSaved on device."].exists)
        attachScreenshot(app, name: "Saved ratings list")

        app.staticTexts[title].firstMatch.tap()
        scrollTo(rating, in: app)
        rating.tap()
        app.buttons["9 из 10"].tap()
        scrollTo(save, in: app)
        save.tap()
        XCTAssertTrue(app.staticTexts["Оценка и комментарий сохранены"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Моя оценка: 9 / 10"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        app.tabBars.buttons["Мои оценки"].tap()
        XCTAssertTrue(app.staticTexts["Моя оценка: 9 / 10"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["A personal comment.\nSaved on device."].exists)
        app.staticTexts[title].firstMatch.tap()
        let remove = app.buttons["Убрать оценку и комментарий"]
        scrollTo(remove, in: app)
        remove.tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Пока нет оценок"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
