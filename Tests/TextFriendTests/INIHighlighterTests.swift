import Testing

@testable import TextFriend

@MainActor
struct INIHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    INIHighlighter().tokenize(source)
  }

  @Test func highlightsSections() {
    let result = tokens("[database]")
    #expect(type(of: "[database]", in: result) == .meta)
  }

  @Test func highlightsKeysAndSeparator() {
    let result = tokens("host = localhost")
    #expect(type(of: "host", in: result) == .key)
    #expect(type(of: "=", in: result) == .punctuation)
  }

  @Test func colonSeparatorAlsoWorks() {
    let result = tokens("host: localhost")
    #expect(type(of: "host", in: result) == .key)
  }

  @Test func semicolonAndHashLineCommentsAreWholeLine() {
    let result = tokens("; a comment\n# another")
    #expect(type(of: "; a comment", in: result) == .comment)
    #expect(type(of: "# another", in: result) == .comment)
  }

  @Test func onlyFirstSeparatorIsPunctuation() {
    let result = tokens("url = https://host:8080/path")
    let punctuation = result.filter { $0.type == .punctuation }
    #expect(punctuation == [Token("=", .punctuation)])
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      ; php.ini fragment
      [PHP]
      engine = On
      memory_limit = 128M
      display_errors = Off
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
