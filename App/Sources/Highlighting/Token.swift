import Foundation

/// Semantic classification of a piece of source text.
enum TokenType: String, CaseIterable, Codable, Sendable {
  case plain
  case comment
  case key
  case string
  case number
  case constant
  case keyword
  case punctuation
  case meta
  case heading
  case emphasis
  case link
}

/// A contiguous run of text with a single semantic classification.
///
/// Invariant: concatenating the `text` of all tokens produced by a
/// `SyntaxHighlighter` yields the original input, unchanged.
struct Token: Equatable, Sendable {
  let text: String
  let type: TokenType

  init(_ text: String, _ type: TokenType) {
    self.text = text
    self.type = type
  }
}

/// Produces a lossless token stream for a piece of source text.
protocol SyntaxHighlighter {
  func tokenize(_ text: String) -> [Token]
}

extension SyntaxHighlighter {
  /// Splits `text` into lines, tokenizes each with `lineTokenizer`, and
  /// re-inserts newline tokens so the stream stays lossless.
  func tokenizeLines(_ text: String, using lineTokenizer: (String) -> [Token]) -> [Token] {
    guard !text.isEmpty else { return [] }
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    var tokens: [Token] = []
    for (index, line) in lines.enumerated() {
      tokens.append(contentsOf: lineTokenizer(String(line)))
      if index < lines.count - 1 {
        tokens.append(Token("\n", .plain))
      }
    }
    return tokens
  }
}

/// A tokenizer for formats without any highlighting rules.
struct PlainHighlighter: SyntaxHighlighter {
  func tokenize(_ text: String) -> [Token] {
    text.isEmpty ? [] : [Token(text, .plain)]
  }
}
