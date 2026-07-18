import Foundation

/// Tokenizer for unified diffs and patches. Whole lines get one color:
/// additions map to the string color (green-ish), removals to the keyword
/// color (red-ish), hunk headers stand out as headings.
struct DiffHighlighter: SyntaxHighlighter {
  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      guard !line.isEmpty else { return [] }
      let type: TokenType
      if line.hasPrefix("+++") || line.hasPrefix("---") {
        type = .meta
      } else if line.hasPrefix("@@") {
        type = .heading
      } else if line.hasPrefix("+") {
        type = .string
      } else if line.hasPrefix("-") {
        type = .keyword
      } else if line.hasPrefix("diff ") || line.hasPrefix("index ")
        || line.hasPrefix("new file") || line.hasPrefix("deleted file")
        || line.hasPrefix("rename ") || line.hasPrefix("similarity ")
        || line.hasPrefix("Binary files")
      {
        type = .meta
      } else {
        type = .plain
      }
      return [Token(line, type)]
    }
  }
}
