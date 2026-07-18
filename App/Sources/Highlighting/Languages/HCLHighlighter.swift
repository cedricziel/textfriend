import Foundation

/// Tokenizer for HCL / Terraform files with stateful `/* */` block comments.
struct HCLHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(
      #"^\s*(resource|data|variable|provider|module|output|locals|terraform|backend|dynamic|import|moved|check)\b"#,
      .keyword),
    HighlightRule(#"^\s*([A-Za-z_][\w-]*)\s*(?==[^=])"#, .key, group: 1),
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"<<-?\w+"#, .meta),
    HighlightRule(#"\b(true|false|null)\b"#, .constant),
    HighlightRule(#"(?<![\w.])-?\d+(?:\.\d+)?\b"#, .number),
    HighlightRule(#"\b(for|in|if|each|count|depends_on|source|version)\b"#, .keyword),
    HighlightRule(#"[={}\[\],]"#, .punctuation),
  ])

  private static let blockCommentOpen = "/*"
  private static let blockCommentClose = "*/"

  func tokenize(_ text: String) -> [Token] {
    var inBlockComment = false
    return tokenizeLines(text) { line in
      var tokens: [Token] = []
      var rest = Substring(line)

      while !rest.isEmpty {
        if inBlockComment {
          if let end = rest.range(of: Self.blockCommentClose) {
            tokens.append(Token(String(rest[..<end.upperBound]), .comment))
            rest = rest[end.upperBound...]
            inBlockComment = false
          } else {
            tokens.append(Token(String(rest), .comment))
            rest = rest[rest.endIndex...]
          }
          continue
        }

        if let open = rest.range(of: Self.blockCommentOpen) {
          let before = String(rest[..<open.lowerBound])
          tokens.append(contentsOf: Self.tokenizeCode(before))
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

  /// Tokenizes a comment-free stretch, handling `#` and `//` line comments.
  private static func tokenizeCode(_ code: String) -> [Token] {
    guard !code.isEmpty else { return [] }
    let (hashCode, hashComment) = CommentSplit.split(line: code, requireBoundary: false)
    let (slashCode, slashComment) = CommentSplit.splitDoubleSlash(line: hashCode)
    var tokens = rules.tokenize(line: slashCode)
    if let slashComment {
      tokens.append(Token(slashComment, .comment))
    }
    if let hashComment {
      tokens.append(Token(hashComment, .comment))
    }
    return tokens
  }
}
