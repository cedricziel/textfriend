import XCTest

final class EditorSmokeTests: XCTestCase {
  @MainActor
  func testCreateDocumentTypeAndSeeStats() throws {
    let app = XCUIApplication()
    app.launch()

    let create = app.buttons["Create Document"]
    XCTAssertTrue(create.waitForExistence(timeout: 15), "Document browser should offer creation")
    create.tap()

    let editor = app.textViews.firstMatch
    XCTAssertTrue(editor.waitForExistence(timeout: 15), "Editor should open for a new document")

    editor.tap()
    editor.typeText("name: value")

    // The status bar shows the detected syntax for the new .txt document.
    XCTAssertTrue(
      app.staticTexts["Plain Text"].waitForExistence(timeout: 10),
      "Status bar should show the detected language")
    XCTAssertTrue(
      app.staticTexts["2 words"].waitForExistence(timeout: 10),
      "Status bar should show live word count")
  }
}
