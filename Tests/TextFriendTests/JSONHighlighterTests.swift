import Testing

@testable import TextFriend

@MainActor
struct JSONHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    JSONHighlighter().tokenize(source)
  }

  @Test func distinguishesKeysFromStringValues() {
    let result = tokens(#"{"name": "value"}"#)
    #expect(type(of: #""name""#, in: result) == .key)
    #expect(type(of: #""value""#, in: result) == .string)
  }

  @Test func highlightsConstantsAndNumbers() {
    let result = tokens(#"{"a": true, "b": null, "c": -1.5e3}"#)
    #expect(type(of: "true", in: result) == .constant)
    #expect(type(of: "null", in: result) == .constant)
    #expect(type(of: "-1.5e3", in: result) == .number)
  }

  @Test func highlightsPunctuation() {
    let result = tokens("[1, 2]")
    #expect(type(of: "[", in: result) == .punctuation)
    #expect(type(of: ",", in: result) == .punctuation)
    #expect(type(of: "]", in: result) == .punctuation)
  }

  @Test func supportsJSONCLineComments() {
    let result = tokens("{\n  // a comment\n}")
    #expect(typeContaining("a comment", in: result) == .comment)
  }

  @Test func slashesInsideStringsAreNotComments() {
    let result = tokens(#"{"url": "https://example.com"}"#)
    #expect(result.allSatisfy { $0.type != .comment })
    #expect(type(of: #""https://example.com""#, in: result) == .string)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      {
        "name": "textfriend",
        "version": "1.0.0",
        "private": true,
        "scripts": { "build": "make" },
        "values": [1, 2.5, -3, null]
      }
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
