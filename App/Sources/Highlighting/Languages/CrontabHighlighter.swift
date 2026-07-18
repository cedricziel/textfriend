import Foundation

struct CrontabHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"^\s*@(reboot|yearly|annually|monthly|weekly|daily|midnight|hourly)\b"#, .meta),
    HighlightRule(#"^\s*((?:[\d*,/-]+\s+){4}[\d*,/-]+)(?=\s)"#, .number, group: 1),
    HighlightRule(#"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?==)"#, .key, group: 1),
    HighlightRule(#"^[^=]*?(=)"#, .punctuation, group: 1),
    HighlightRule(#"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*"#, .meta),
    HighlightRule(#""(?:[^"\\]|\\.)*"|'[^']*'"#, .string),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      let (code, comment) = CommentSplit.split(line: line)
      var tokens = Self.rules.tokenize(line: code)
      if let comment {
        tokens.append(Token(comment, .comment))
      }
      return tokens
    }
  }
}
