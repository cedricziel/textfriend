import Foundation

/// Tokenizer for Apple `.strings` localization files.
struct StringsHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#""(?:[^"\\]|\\.)*"(?=\s*=)"#, .key),
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"[=;]"#, .punctuation),
  ])

  func tokenize(_ text: String) -> [Token] {
    var inBlockComment = false
    return tokenizeLines(text) { line in
      var tokens: [Token] = []
      var rest = Substring(line)

      while !rest.isEmpty {
        if inBlockComment {
          if let end = rest.range(of: "*/") {
            tokens.append(Token(String(rest[..<end.upperBound]), .comment))
            rest = rest[end.upperBound...]
            inBlockComment = false
          } else {
            tokens.append(Token(String(rest), .comment))
            rest = rest[rest.endIndex...]
          }
          continue
        }

        if let open = rest.range(of: "/*") {
          tokens.append(contentsOf: Self.tokenizeCode(String(rest[..<open.lowerBound])))
          rest = rest[open.lowerBound...]
          inBlockComment = true
          continue
        }

        tokens.append(contentsOf: Self.tokenizeCode(String(rest)))
        break
      }
      return tokens
    }
  }

  private static func tokenizeCode(_ code: String) -> [Token] {
    guard !code.isEmpty else { return [] }
    let (slashCode, slashComment) = CommentSplit.splitDoubleSlash(line: code)
    var tokens = rules.tokenize(line: slashCode)
    if let slashComment {
      tokens.append(Token(slashComment, .comment))
    }
    return tokens
  }
}
