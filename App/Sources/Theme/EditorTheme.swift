import SwiftUI

/// A named set of colors for token types. `plain` intentionally has no color
/// so it falls back to the system's primary label color.
struct EditorTheme: Identifiable, Equatable {
  let id: String
  let name: String
  let colors: [TokenType: Color]

  func color(for type: TokenType) -> Color? {
    colors[type]
  }

  static let friend = EditorTheme(
    id: "friend",
    name: "Friend",
    colors: [
      .comment: Color(red: 0.55, green: 0.58, blue: 0.62),
      .key: Color(red: 0.24, green: 0.48, blue: 0.85),
      .string: Color(red: 0.17, green: 0.60, blue: 0.36),
      .number: Color(red: 0.85, green: 0.49, blue: 0.15),
      .constant: Color(red: 0.60, green: 0.35, blue: 0.80),
      .keyword: Color(red: 0.80, green: 0.25, blue: 0.50),
      .punctuation: Color(red: 0.55, green: 0.58, blue: 0.62),
      .meta: Color(red: 0.10, green: 0.60, blue: 0.60),
      .heading: Color(red: 0.80, green: 0.30, blue: 0.20),
      .emphasis: Color(red: 0.72, green: 0.45, blue: 0.10),
      .link: Color(red: 0.20, green: 0.45, blue: 0.80),
    ])

  static let paper = EditorTheme(
    id: "paper",
    name: "Paper",
    colors: [
      .comment: Color(red: 0.58, green: 0.55, blue: 0.50),
      .key: Color(red: 0.15, green: 0.35, blue: 0.60),
      .string: Color(red: 0.25, green: 0.50, blue: 0.25),
      .number: Color(red: 0.65, green: 0.35, blue: 0.10),
      .constant: Color(red: 0.45, green: 0.25, blue: 0.60),
      .keyword: Color(red: 0.60, green: 0.15, blue: 0.30),
      .punctuation: Color(red: 0.50, green: 0.48, blue: 0.45),
      .meta: Color(red: 0.10, green: 0.45, blue: 0.45),
      .heading: Color(red: 0.55, green: 0.20, blue: 0.10),
      .emphasis: Color(red: 0.55, green: 0.35, blue: 0.05),
      .link: Color(red: 0.15, green: 0.35, blue: 0.65),
    ])

  static let midnight = EditorTheme(
    id: "midnight",
    name: "Midnight",
    colors: [
      .comment: Color(red: 0.45, green: 0.50, blue: 0.55),
      .key: Color(red: 0.45, green: 0.68, blue: 1.0),
      .string: Color(red: 0.40, green: 0.80, blue: 0.55),
      .number: Color(red: 1.0, green: 0.65, blue: 0.35),
      .constant: Color(red: 0.80, green: 0.55, blue: 1.0),
      .keyword: Color(red: 1.0, green: 0.45, blue: 0.65),
      .punctuation: Color(red: 0.55, green: 0.60, blue: 0.65),
      .meta: Color(red: 0.35, green: 0.80, blue: 0.80),
      .heading: Color(red: 1.0, green: 0.55, blue: 0.40),
      .emphasis: Color(red: 0.95, green: 0.70, blue: 0.30),
      .link: Color(red: 0.45, green: 0.65, blue: 1.0),
    ])

  static let all: [EditorTheme] = [.friend, .paper, .midnight]

  static func theme(id: String) -> EditorTheme {
    all.first { $0.id == id } ?? .friend
  }
}
