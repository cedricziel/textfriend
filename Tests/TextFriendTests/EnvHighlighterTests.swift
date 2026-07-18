import Testing

@testable import TextFriend

@MainActor
struct EnvHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    EnvHighlighter().tokenize(source)
  }

  @Test func highlightsKeyAndSeparator() {
    let result = tokens("DATABASE_URL=postgres://localhost/app")
    #expect(type(of: "DATABASE_URL", in: result) == .key)
    #expect(type(of: "=", in: result) == .punctuation)
  }

  @Test func highlightsExportKeyword() {
    let result = tokens("export API_KEY=abc123")
    #expect(type(of: "export", in: result) == .keyword)
    #expect(type(of: "API_KEY", in: result) == .key)
  }

  @Test func highlightsQuotedValues() {
    let result = tokens(#"GREETING="hello world""#)
    #expect(type(of: #""hello world""#, in: result) == .string)
  }

  @Test func highlightsVariableInterpolation() {
    let result = tokens("PATH_EXT=${HOME}/bin:$PATH")
    #expect(type(of: "${HOME}", in: result) == .meta)
    #expect(type(of: "$PATH", in: result) == .meta)
  }

  @Test func highlightsComments() {
    let result = tokens("# secrets below\nTOKEN=x # inline")
    #expect(type(of: "# secrets below", in: result) == .comment)
    #expect(type(of: "# inline", in: result) == .comment)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      # .env.example
      NODE_ENV=development
      PORT=3000
      export SECRET="s3cr3t"
      COMPOSED=${BASE}/api
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
