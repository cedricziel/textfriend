import Foundation

/// Tokenizer for CSV/TSV. The first non-empty line is treated as the header
/// row and colored as keys; quoted fields, delimiters, and numbers are
/// highlighted below.
struct CSVHighlighter: SyntaxHighlighter {
  private static let headerRules = LineRules([
    HighlightRule(#"[,;\t]"#, .punctuation),
    HighlightRule(#""(?:[^"]|"")*"|[^,;\t]+"#, .key),
  ])

  private static let rowRules = LineRules([
    HighlightRule(#""(?:[^"]|"")*""#, .string),
    HighlightRule(#"[,;\t]"#, .punctuation),
    HighlightRule(#"(?<![\w.])-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?(?![\w.])"#, .number),
  ])

  func tokenize(_ text: String) -> [Token] {
    var seenHeader = false
    return tokenizeLines(text) { line in
      if !seenHeader, !line.trimmingCharacters(in: .whitespaces).isEmpty {
        seenHeader = true
        return Self.headerRules.tokenize(line: line)
      }
      return Self.rowRules.tokenize(line: line)
    }
  }
}
