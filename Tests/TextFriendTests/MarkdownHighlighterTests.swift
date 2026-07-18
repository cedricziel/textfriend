import Testing

@testable import TextFriend

@MainActor
struct MarkdownHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    MarkdownHighlighter().tokenize(source)
  }

  @Test func highlightsHeadings() {
    let result = tokens("# Title\n## Sub")
    #expect(type(of: "# Title", in: result) == .heading)
    #expect(type(of: "## Sub", in: result) == .heading)
  }

  @Test func fencedCodeBlocksAreStateful() {
    let result = tokens("```swift\nlet x = 1\n```\nafter")
    #expect(type(of: "```swift", in: result) == .meta)
    #expect(type(of: "let x = 1", in: result) == .string)
    #expect(type(of: "```", in: result) == .meta)
    #expect(type(of: "after", in: result) == .plain)
  }

  @Test func headingInsideFenceIsNotHeading() {
    let result = tokens("```\n# not a heading\n```")
    #expect(type(of: "# not a heading", in: result) == .string)
  }

  @Test func highlightsInlineCode() {
    let result = tokens("Use `swift build` here")
    #expect(type(of: "`swift build`", in: result) == .string)
  }

  @Test func highlightsBoldAndItalic() {
    let result = tokens("**bold** and *italic*")
    #expect(type(of: "**bold**", in: result) == .emphasis)
    #expect(type(of: "*italic*", in: result) == .emphasis)
  }

  @Test func highlightsLinks() {
    let result = tokens("[site](https://example.com) and <https://a.dev>")
    #expect(type(of: "[site](https://example.com)", in: result) == .link)
    #expect(type(of: "<https://a.dev>", in: result) == .link)
  }

  @Test func highlightsListMarkersAndBlockquotes() {
    let result = tokens("- item\n> quoted")
    #expect(type(of: "- ", in: result) == .punctuation)
    #expect(type(of: "> quoted", in: result) == .emphasis)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      # TextFriend

      A *tiny* editor for **config files**.

      ```yaml
      key: value
      ```

      1. First
      2. Second — see [docs](https://example.com).
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
