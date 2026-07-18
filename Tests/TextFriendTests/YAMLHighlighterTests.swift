import Testing

@testable import TextFriend

@MainActor
struct YAMLHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    YAMLHighlighter().tokenize(source)
  }

  @Test func highlightsTopLevelKey() {
    let result = tokens("name: value")
    #expect(type(of: "name", in: result) == .key)
  }

  @Test func highlightsNestedKey() {
    let result = tokens("  image: nginx")
    #expect(type(of: "image", in: result) == .key)
  }

  @Test func highlightsSequenceItemKey() {
    let result = tokens("- name: build")
    #expect(type(of: "name", in: result) == .key)
    #expect(type(of: "-", in: result) == .punctuation)
  }

  @Test func highlightsComment() {
    let result = tokens("key: value # trailing comment")
    #expect(typeContaining("trailing comment", in: result) == .comment)
  }

  @Test func hashInsideQuotedStringIsNotComment() {
    let result = tokens(##"channel: "#general""##)
    #expect(type(of: ##""#general""##, in: result) == .string)
    #expect(result.allSatisfy { $0.type != .comment })
  }

  @Test func highlightsStringsAndConstantsAndNumbers() {
    let result = tokens(
      """
      title: "hello"
      enabled: true
      replicas: 3
      ratio: 0.5
      empty: null
      """)
    #expect(type(of: #""hello""#, in: result) == .string)
    #expect(type(of: "true", in: result) == .constant)
    #expect(type(of: "3", in: result) == .number)
    #expect(type(of: "0.5", in: result) == .number)
    #expect(type(of: "null", in: result) == .constant)
  }

  @Test func highlightsDocumentMarkersAndDirectives() {
    let result = tokens("---\n%YAML 1.2\n...")
    #expect(type(of: "---", in: result) == .meta)
    #expect(type(of: "%YAML 1.2", in: result) == .meta)
    #expect(type(of: "...", in: result) == .meta)
  }

  @Test func highlightsAnchorsAliasesAndTags() {
    let result = tokens("base: &defaults\nother: *defaults\ntyped: !!str x")
    #expect(type(of: "&defaults", in: result) == .meta)
    #expect(type(of: "*defaults", in: result) == .meta)
    #expect(type(of: "!!str", in: result) == .meta)
  }

  @Test func highlightsBlockScalarIndicator() {
    let result = tokens("script: |")
    #expect(type(of: "|", in: result) == .punctuation)
  }

  @Test func urlValueDoesNotBecomeKey() {
    let result = tokens("url: https://example.com/path")
    #expect(type(of: "url", in: result) == .key)
    #expect(result.filter { $0.type == .key }.count == 1)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      # docker-compose.yml
      version: "3.9"
      services:
        web:
          image: nginx:latest
          ports:
            - "8080:80"
          environment:
            DEBUG: "false"
        db: &db
          image: postgres
      volumes: []
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
