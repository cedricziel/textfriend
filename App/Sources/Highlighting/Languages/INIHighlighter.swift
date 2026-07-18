import Foundation

struct INIHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"^\s*\[[^\]]*\]"#, .meta),
    HighlightRule(#"^\s*([^=:\s\[][^=:]*?)\s*(?=[=:])"#, .key, group: 1),
    HighlightRule(#"^[^=:]*([=:])"#, .punctuation, group: 1),
    HighlightRule(#""[^"]*"|'[^']*'"#, .string),
    HighlightRule(#"\b(?i:true|false|yes|no|on|off)\b"#, .constant),
    HighlightRule(#"(?<![\w.])-?\d+(?:\.\d+)?\b"#, .number),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
      if trimmed.first == ";" || trimmed.first == "#" {
        return [Token(line, .comment)]
      }
      return Self.rules.tokenize(line: line)
    }
  }
}
