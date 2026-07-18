import Foundation

/// Tokenizer for Markdown with stateful fenced-code-block handling.
struct MarkdownHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"^#{1,6}\s.*$"#, .heading),
    HighlightRule(#"^\s{0,3}([-*_])(\s*\1){2,}\s*$"#, .punctuation),
    HighlightRule(#"^\s*>.*$"#, .emphasis),
    HighlightRule(#"`[^`]+`"#, .string),
    HighlightRule(#"!?\[[^\]]*\]\([^)]*\)"#, .link),
    HighlightRule(#"<https?://[^>\s]+>"#, .link),
    HighlightRule(#"\*\*[^*\n]+\*\*|__[^_\n]+__"#, .emphasis),
    HighlightRule(#"\*[^*\s][^*\n]*\*|(?<![\w_])_[^_\n]+_(?![\w_])"#, .emphasis),
    HighlightRule(#"^\s*(?:[-*+]|\d+[.)])\s"#, .punctuation),
  ])

  private static let fencePattern = try! NSRegularExpression(pattern: #"^\s*(```+|~~~+)"#)

  func tokenize(_ text: String) -> [Token] {
    var inFence = false
    return tokenizeLines(text) { line in
      let ns = line as NSString
      let fenceMatch = Self.fencePattern.firstMatch(
        in: line, range: NSRange(location: 0, length: ns.length))
      if fenceMatch != nil {
        inFence.toggle()
        return [Token(line, .meta)]
      }
      if inFence {
        return line.isEmpty ? [] : [Token(line, .string)]
      }
      return Self.rules.tokenize(line: line)
    }
  }
}
