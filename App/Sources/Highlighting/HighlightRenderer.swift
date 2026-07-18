import SwiftUI

/// Applies token colors to an `AttributedString` without changing its
/// characters, so editing state (selection, undo) survives re-highlighting.
enum HighlightRenderer {
  /// Overwrites color attributes on `text` according to `tokens`.
  /// The tokens must concatenate to exactly the characters of `text`;
  /// if they don't, the text is reset to unstyled as a safe fallback.
  static func apply(tokens: [Token], to text: inout AttributedString, theme: EditorTheme) {
    text.foregroundColor = nil
    text.underlineStyle = nil

    var index = text.startIndex
    for token in tokens {
      guard
        let end = text.characters.index(
          index, offsetBy: token.text.count, limitedBy: text.endIndex)
      else {
        text.foregroundColor = nil
        return
      }
      if let color = theme.color(for: token.type) {
        text[index..<end].foregroundColor = color
      }
      if token.type == .link {
        text[index..<end].underlineStyle = .single
      }
      index = end
    }
  }

  /// Builds a styled `AttributedString` from scratch (initial document load).
  static func highlighted(_ string: String, language: Language, theme: EditorTheme)
    -> AttributedString
  {
    var text = AttributedString(string)
    let tokens = language.highlighter.tokenize(string)
    apply(tokens: tokens, to: &text, theme: theme)
    return text
  }
}
