import Foundation

/// Tokenizer for dotenv (.env) files.
struct EnvHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"^\s*(export)\s"#, .keyword, group: 1),
    HighlightRule(#"^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*(?==)"#, .key, group: 1),
    HighlightRule(#"^[^=]*?(=)"#, .punctuation, group: 1),
    HighlightRule(#""(?:[^"\\]|\\.)*"|'[^']*'"#, .string),
    HighlightRule(#"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*"#, .meta),
    HighlightRule(#"\b(?i:true|false)\b"#, .constant),
    HighlightRule(#"(?<![\w.])-?\d+(?:\.\d+)?\b"#, .number),
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
