import Testing

@testable import TextFriend

@MainActor
struct TOMLHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    TOMLHighlighter().tokenize(source)
  }

  @Test func highlightsTables() {
    let result = tokens("[server]\n[[products]]")
    #expect(type(of: "[server]", in: result) == .meta)
    #expect(type(of: "[[products]]", in: result) == .meta)
  }

  @Test func highlightsKeysIncludingDotted() {
    let result = tokens("port = 8080\nphysical.color = \"orange\"")
    #expect(type(of: "port", in: result) == .key)
    #expect(type(of: "physical.color", in: result) == .key)
  }

  @Test func highlightsStrings() {
    let result = tokens(#"name = "TextFriend""#)
    #expect(type(of: #""TextFriend""#, in: result) == .string)
  }

  @Test func highlightsDatesAndTimes() {
    let result = tokens("date = 1979-05-27T07:32:00Z")
    #expect(type(of: "1979-05-27T07:32:00Z", in: result) == .number)
  }

  @Test func highlightsNumbersWithUnderscoresAndBools() {
    let result = tokens("big = 1_000_000\nhex = 0xDEADBEEF\nflag = true")
    #expect(type(of: "1_000_000", in: result) == .number)
    #expect(type(of: "0xDEADBEEF", in: result) == .number)
    #expect(type(of: "true", in: result) == .constant)
  }

  @Test func highlightsComments() {
    let result = tokens("# top comment\nkey = 1 # inline")
    #expect(type(of: "# top comment", in: result) == .comment)
    #expect(type(of: "# inline", in: result) == .comment)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      # Cargo.toml
      [package]
      name = "textfriend"
      version = "0.1.0"
      edition = "2021"

      [dependencies]
      serde = { version = "1.0", features = ["derive"] }
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
