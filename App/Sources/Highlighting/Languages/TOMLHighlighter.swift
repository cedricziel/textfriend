import Foundation

struct TOMLHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"^\s*\[\[?[^\]]*\]\]?"#, .meta),
    HighlightRule(
      #"^\s*((?:[A-Za-z0-9_-]+|"[^"]*"|'[^']*')(?:\.(?:[A-Za-z0-9_-]+|"[^"]*"|'[^']*'))*)\s*(?==)"#,
      .key, group: 1),
    HighlightRule(#""""[\s\S]*?"""|"(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"'''[\s\S]*?'''|'[^']*'"#, .string),
    HighlightRule(
      #"\d{4}-\d{2}-\d{2}(?:[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:[Zz]|[+-]\d{2}:\d{2})?)?|\d{2}:\d{2}:\d{2}(?:\.\d+)?"#,
      .number),
    HighlightRule(#"\b(true|false)\b"#, .constant),
    HighlightRule(
      #"(?<![\w.])[+-]?(?:0x[0-9a-fA-F_]+|0o[0-7_]+|0b[01_]+|inf|nan|\d[\d_]*(?:\.[\d_]+)?(?:[eE][+-]?[\d_]+)?)\b"#,
      .number),
    HighlightRule(#"[={}\[\],]"#, .punctuation),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      let (code, comment) = CommentSplit.split(line: line, requireBoundary: false)
      var tokens = Self.rules.tokenize(line: code)
      if let comment {
        tokens.append(Token(comment, .comment))
      }
      return tokens
    }
  }
}
