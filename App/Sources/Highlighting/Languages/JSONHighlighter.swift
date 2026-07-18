import Foundation

/// Tokenizer for JSON, including JSONC-style `//` line comments.
struct JSONHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#""(?:[^"\\]|\\.)*"(?=\s*:)"#, .key),
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"\b(true|false|null)\b"#, .constant),
    HighlightRule(#"-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#, .number),
    HighlightRule(#"[{}\[\]:,]"#, .punctuation),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      let (code, comment) = CommentSplit.splitDoubleSlash(line: line)
      var tokens = Self.rules.tokenize(line: code)
      if let comment {
        tokens.append(Token(comment, .comment))
      }
      return tokens
    }
  }
}
