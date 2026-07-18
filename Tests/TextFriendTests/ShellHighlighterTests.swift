import Testing

@testable import TextFriend

@MainActor
struct ShellHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    ShellHighlighter().tokenize(source)
  }

  @Test func shebangIsMeta() {
    let result = tokens("#!/bin/bash\necho hi")
    #expect(type(of: "#!/bin/bash", in: result) == .meta)
  }

  @Test func highlightsKeywords() {
    let result = tokens("if true; then echo yes; fi")
    #expect(type(of: "if", in: result) == .keyword)
    #expect(type(of: "then", in: result) == .keyword)
    #expect(type(of: "fi", in: result) == .keyword)
  }

  @Test func highlightsVariables() {
    let result = tokens("cp $SRC ${DEST}/out $1")
    #expect(type(of: "$SRC", in: result) == .meta)
    #expect(type(of: "${DEST}", in: result) == .meta)
    #expect(type(of: "$1", in: result) == .meta)
  }

  @Test func highlightsStrings() {
    let result = tokens(#"echo "hello world" 'raw'"#)
    #expect(type(of: #""hello world""#, in: result) == .string)
    #expect(type(of: "'raw'", in: result) == .string)
  }

  @Test func keywordInsideStringIsNotKeyword() {
    let result = tokens(#"msg="if only""#)
    #expect(type(of: #""if only""#, in: result) == .string)
  }

  @Test func highlightsComments() {
    let result = tokens("ls -la # list everything")
    #expect(typeContaining("list everything", in: result) == .comment)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      #!/usr/bin/env bash
      set -euo pipefail

      for f in *.yaml; do
        echo "checking $f"
      done
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
