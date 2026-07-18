import Foundation

/// Tokenizer for XML-family documents (XML, plist, SVG) with stateful
/// multi-line comment handling.
struct XMLHighlighter: SyntaxHighlighter {
  private static let tagRules = LineRules([
    HighlightRule(#"^</?[A-Za-z][\w:.-]*"#, .keyword),
    HighlightRule(#"/?>$"#, .keyword),
    HighlightRule(#""[^"]*"|'[^']*'"#, .string),
    HighlightRule(#"[\w:-]+(?==)"#, .key),
    HighlightRule(#"="#, .punctuation),
  ])

  private static let textRules = LineRules([
    HighlightRule(#"&#?\w+;"#, .constant)
  ])

  func tokenize(_ text: String) -> [Token] {
    var inComment = false
    return tokenizeLines(text) { line in
      var tokens: [Token] = []
      var rest = Substring(line)

      while !rest.isEmpty {
        if inComment {
          if let end = rest.range(of: "-->") {
            tokens.append(Token(String(rest[..<end.upperBound]), .comment))
            rest = rest[end.upperBound...]
            inComment = false
          } else {
            tokens.append(Token(String(rest), .comment))
            rest = rest[rest.endIndex...]
          }
          continue
        }

        guard let open = rest.firstIndex(of: "<") else {
          tokens.append(contentsOf: Self.textRules.tokenize(line: String(rest)))
          break
        }
        if open > rest.startIndex {
          tokens.append(contentsOf: Self.textRules.tokenize(line: String(rest[..<open])))
        }
        rest = rest[open...]

        if rest.hasPrefix("<!--") {
          inComment = true
          continue
        }
        guard let close = rest.firstIndex(of: ">") else {
          // Unterminated tag on this line; leave it unstyled.
          tokens.append(Token(String(rest), .plain))
          break
        }
        let tag = String(rest[...close])
        rest = rest[rest.index(after: close)...]

        if tag.hasPrefix("<?") || tag.hasPrefix("<!") {
          tokens.append(Token(tag, .meta))
        } else {
          tokens.append(contentsOf: Self.tagRules.tokenize(line: tag))
        }
      }
      return tokens
    }
  }
}
