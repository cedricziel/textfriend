import Foundation

/// A single regex-based highlighting rule. Rules are applied in order; earlier
/// rules claim their matched ranges and later rules cannot overlap them.
struct HighlightRule {
  let regex: NSRegularExpression
  let type: TokenType
  let group: Int

  init(_ pattern: String, _ type: TokenType, group: Int = 0) {
    // Patterns are compile-time constants; a bad pattern is a programmer error.
    self.regex = try! NSRegularExpression(pattern: pattern)
    self.type = type
    self.group = group
  }
}

/// Applies an ordered list of rules to a single line, producing a lossless
/// token stream. A rule only claims a range if no earlier rule touched any
/// character in it.
struct LineRules {
  let rules: [HighlightRule]

  init(_ rules: [HighlightRule]) {
    self.rules = rules
  }

  func tokenize(line: String) -> [Token] {
    let ns = line as NSString
    guard ns.length > 0 else { return [] }

    var claimed = [Bool](repeating: false, count: ns.length)
    var spans: [(range: NSRange, type: TokenType)] = []

    for rule in rules {
      let fullRange = NSRange(location: 0, length: ns.length)
      rule.regex.enumerateMatches(in: line, range: fullRange) { match, _, _ in
        guard let match else { return }
        let range = match.range(at: rule.group)
        guard range.location != NSNotFound, range.length > 0 else { return }
        let indices = range.location..<(range.location + range.length)
        guard !indices.contains(where: { claimed[$0] }) else { return }
        for i in indices { claimed[i] = true }
        spans.append((range, rule.type))
      }
    }

    spans.sort { $0.range.location < $1.range.location }

    var tokens: [Token] = []
    var cursor = 0
    for span in spans {
      if span.range.location > cursor {
        let gap = NSRange(location: cursor, length: span.range.location - cursor)
        tokens.append(Token(ns.substring(with: gap), .plain))
      }
      tokens.append(Token(ns.substring(with: span.range), span.type))
      cursor = span.range.location + span.range.length
    }
    if cursor < ns.length {
      tokens.append(Token(ns.substring(from: cursor), .plain))
    }
    return tokens
  }
}

/// Splits a line into code and trailing comment, respecting quoted strings.
enum CommentSplit {
  /// Finds a comment introduced by `marker` (e.g. `#`) outside of quotes.
  /// When `requireBoundary` is true the marker must be at the start of the
  /// line or preceded by whitespace (YAML semantics).
  static func split(
    line: String,
    marker: Character = "#",
    requireBoundary: Bool = true
  ) -> (code: String, comment: String?) {
    var inSingle = false
    var inDouble = false
    var previous: Character?
    var index = line.startIndex
    while index < line.endIndex {
      let char = line[index]
      if inDouble {
        if char == "\\" {
          index = line.index(after: index)
          if index < line.endIndex { index = line.index(after: index) }
          previous = nil
          continue
        }
        if char == "\"" { inDouble = false }
      } else if inSingle {
        if char == "'" { inSingle = false }
      } else {
        switch char {
        case "\"": inDouble = true
        case "'": inSingle = true
        case marker:
          let atBoundary = previous == nil || previous?.isWhitespace == true
          if !requireBoundary || atBoundary {
            return (String(line[..<index]), String(line[index...]))
          }
        default: break
        }
      }
      previous = char
      index = line.index(after: index)
    }
    return (line, nil)
  }

  /// Finds a `//` comment outside of double-quoted strings (JSONC semantics).
  static func splitDoubleSlash(line: String) -> (code: String, comment: String?) {
    var inDouble = false
    var index = line.startIndex
    while index < line.endIndex {
      let char = line[index]
      if inDouble {
        if char == "\\" {
          index = line.index(after: index)
          if index < line.endIndex { index = line.index(after: index) }
          continue
        }
        if char == "\"" { inDouble = false }
      } else if char == "\"" {
        inDouble = true
      } else if char == "/" {
        let next = line.index(after: index)
        if next < line.endIndex, line[next] == "/" {
          return (String(line[..<index]), String(line[index...]))
        }
      }
      index = line.index(after: index)
    }
    return (line, nil)
  }
}
