import Foundation

/// Live document statistics for the status bar.
struct TextStats: Equatable {
  let characters: Int
  let words: Int
  let lines: Int

  static let empty = TextStats(characters: 0, words: 0, lines: 1)

  static func compute(from text: String) -> TextStats {
    guard !text.isEmpty else { return .empty }
    let words = text.split(whereSeparator: \.isWhitespace).count
    let lines = text.count(where: { $0 == "\n" }) + 1
    return TextStats(characters: text.count, words: words, lines: lines)
  }
}
