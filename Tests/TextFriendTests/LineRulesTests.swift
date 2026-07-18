import Testing

@testable import TextFriend

@MainActor
struct LineRulesTests {
  @Test func earlierRulesClaimRangesFirst() {
    let rules = LineRules([
      HighlightRule(#""[^"]*""#, .string),
      HighlightRule(#"\d+"#, .number),
    ])
    let tokens = rules.tokenize(line: #""42" 42"#)
    #expect(type(of: #""42""#, in: tokens) == .string)
    #expect(type(of: "42", in: tokens) == .number)
  }

  @Test func laterRuleCannotPartiallyOverlapClaimedRange() {
    let rules = LineRules([
      HighlightRule(#"abc"#, .keyword),
      HighlightRule(#"bcd"#, .number),
    ])
    let tokens = rules.tokenize(line: "abcd")
    #expect(tokens == [Token("abc", .keyword), Token("d", .plain)])
  }

  @Test func gapsBecomePlainTokens() {
    let rules = LineRules([HighlightRule(#"\d+"#, .number)])
    let tokens = rules.tokenize(line: "a 1 b 2 c")
    #expect(rejoined(tokens) == "a 1 b 2 c")
    #expect(tokens.filter { $0.type == .number }.count == 2)
    #expect(tokens.filter { $0.type == .plain }.count == 3)
  }

  @Test func emptyLineYieldsNoTokens() {
    let rules = LineRules([HighlightRule(#"\d+"#, .number)])
    #expect(rules.tokenize(line: "").isEmpty)
  }

  @Test func capturedGroupIsClaimedNotWholeMatch() {
    let rules = LineRules([HighlightRule(#"^(\w+)\s*:"#, .key, group: 1)])
    let tokens = rules.tokenize(line: "name: value")
    #expect(tokens.first == Token("name", .key))
    #expect(rejoined(tokens) == "name: value")
  }
}

@MainActor
struct CommentSplitTests {
  @Test func splitsAtBoundaryHash() {
    let (code, comment) = CommentSplit.split(line: "key: value # note")
    #expect(code == "key: value ")
    #expect(comment == "# note")
  }

  @Test func ignoresHashInsideDoubleQuotes() {
    let (code, comment) = CommentSplit.split(line: #"key: "a #tag" # real"#)
    #expect(code == #"key: "a #tag" "#)
    #expect(comment == "# real")
  }

  @Test func ignoresHashInsideSingleQuotes() {
    let (code, comment) = CommentSplit.split(line: "key: 'a #tag'")
    #expect(code == "key: 'a #tag'")
    #expect(comment == nil)
  }

  @Test func requiresBoundaryByDefault() {
    let (code, comment) = CommentSplit.split(line: "value#notacomment")
    #expect(code == "value#notacomment")
    #expect(comment == nil)
  }

  @Test func boundaryNotRequiredWhenDisabled() {
    let (_, comment) = CommentSplit.split(line: "value#comment", requireBoundary: false)
    #expect(comment == "#comment")
  }

  @Test func hashAtLineStartIsComment() {
    let (code, comment) = CommentSplit.split(line: "# whole line")
    #expect(code.isEmpty)
    #expect(comment == "# whole line")
  }

  @Test func doubleSlashOutsideStrings() {
    let (code, comment) = CommentSplit.splitDoubleSlash(line: #""url": "https://x.com" // c"#)
    #expect(code == #""url": "https://x.com" "#)
    #expect(comment == "// c")
  }

  @Test func escapedQuoteDoesNotEndString() {
    let (_, comment) = CommentSplit.split(line: #"key: "a\"b" # c"#)
    #expect(comment == "# c")
  }
}
