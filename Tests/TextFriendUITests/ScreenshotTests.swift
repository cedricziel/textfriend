import XCTest

/// Drives the app for fastlane snapshot. Run via `bundle exec fastlane screenshots`.
final class ScreenshotTests: XCTestCase {
  @MainActor
  func testCaptureScreenshots() throws {
    let app = XCUIApplication()
    setupSnapshot(app)
    app.launch()

    let create = app.buttons["Create Document"]
    XCTAssertTrue(create.waitForExistence(timeout: 15))
    create.tap()

    let editor = app.textViews.firstMatch
    XCTAssertTrue(editor.waitForExistence(timeout: 15))
    editor.tap()
    editor.typeText(
      """
      # docker-compose.yml
      services:
        web:
          image: nginx:latest
          ports:
            - 8080:80
          debug: true
          replicas: 3
        web:
          image: httpd
      """)

    // Force YAML highlighting — a new untitled document defaults to .txt.
    let syntaxMenu = app.buttons["Syntax"]
    if syntaxMenu.waitForExistence(timeout: 5) {
      syntaxMenu.tap()
      let yaml = app.buttons["YAML"]
      if yaml.waitForExistence(timeout: 5) {
        yaml.tap()
      }
    }

    XCTAssertTrue(app.staticTexts["YAML"].waitForExistence(timeout: 10))
    snapshot("01-Editor")

    // The duplicate "web:" key triggers the problem badge in the status bar.
    let issueBadge = app.buttons.matching(
      NSPredicate(format: "label CONTAINS[c] 'issue'")
    ).firstMatch
    if issueBadge.waitForExistence(timeout: 5) {
      issueBadge.tap()
      snapshot("02-Problems")
      app.tap()
    }

    let settings = app.buttons["Settings"]
    if settings.waitForExistence(timeout: 5) {
      settings.tap()
      XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
      snapshot("03-Settings")
    }
  }
}
