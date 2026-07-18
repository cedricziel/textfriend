import Foundation

/// Tokenizer for log files: timestamps, severity levels, and IPs pop out.
struct LogHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(
      #"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:[.,]\d+)?(?:Z|[+-]\d{2}:?\d{2})?"#, .number),
    HighlightRule(#"^[A-Z][a-z]{2} +\d{1,2} \d{2}:\d{2}:\d{2}"#, .number),
    HighlightRule(#"\b(?:ERROR|ERR|FATAL|CRITICAL|CRIT|PANIC)\b"#, .keyword),
    HighlightRule(#"\b(?:WARNING|WARN)\b"#, .emphasis),
    HighlightRule(#"\b(?:INFO|NOTICE)\b"#, .key),
    HighlightRule(#"\b(?:DEBUG|TRACE|VERBOSE)\b"#, .comment),
    HighlightRule(#"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?::\d+)?\b"#, .constant),
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { Self.rules.tokenize(line: $0) }
  }
}
