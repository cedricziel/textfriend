import Foundation

struct YAMLHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"^(---|\.\.\.)\s*$"#, .meta),
    HighlightRule(#"^%(YAML|TAG).*$"#, .meta),
    HighlightRule(
      #"^\s*(?:-\s+)*("(?:[^"\\]|\\.)*"|'(?:[^']|'')*'|[^\s#\{\[][^:#]*?)\s*(?=:(?:\s|$))"#,
      .key, group: 1),
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"'(?:[^']|'')*'"#, .string),
    HighlightRule(#"[&*][\w-]+"#, .meta),
    HighlightRule(#"!!?[\w/-]+"#, .meta),
    HighlightRule(#"[|>][+-]?\s*$"#, .punctuation),
    HighlightRule(#"\b(?i:true|false|null|yes|no|on|off)\b"#, .constant),
    HighlightRule(#"(?<=\s|^)~(?=\s|$)"#, .constant),
    HighlightRule(
      #"(?<![\w.])[+-]?(?:0x[0-9a-fA-F]+|0o[0-7]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b"#, .number),
    HighlightRule(#"^\s*(-)(?=\s|$)"#, .punctuation, group: 1),
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
