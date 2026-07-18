import Foundation

/// Tokenizer for SQL with stateful `/* */` block comments and `--` line
/// comments (respecting quoted strings).
struct SQLHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#"'(?:[^']|'')*'"#, .string),
    HighlightRule(#""[^"]*""#, .key),
    HighlightRule(
      #"\b(?i:select|from|where|insert|into|values|update|set|delete|create|table|index|view|drop|alter|add|primary|key|foreign|references|not|null|default|unique|join|left|right|inner|outer|cross|on|as|order|by|group|having|limit|offset|union|all|distinct|and|or|in|is|like|between|exists|case|when|then|else|end|begin|commit|rollback|transaction|if|constraint|cascade|returning|with|explain|analyze|vacuum|grant|revoke)\b"#,
      .keyword),
    HighlightRule(
      #"\b(?i:integer|int|bigint|smallint|serial|text|varchar|char|boolean|bool|real|float|double|decimal|numeric|blob|bytea|date|time|timestamp|timestamptz|interval|uuid|json|jsonb)\b"#,
      .constant),
    HighlightRule(#"(?<![\w.])-?\d+(?:\.\d+)?\b"#, .number),
    HighlightRule(#"[(),;=<>*+]"#, .punctuation),
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

  /// Splits off a `--` comment outside of single-quoted strings.
  private static func tokenizeCode(_ code: String) -> [Token] {
    guard !code.isEmpty else { return [] }
    var inSingle = false
    var index = code.startIndex
    while index < code.endIndex {
      let char = code[index]
      if char == "'" {
        inSingle.toggle()
      } else if !inSingle, char == "-" {
        let next = code.index(after: index)
        if next < code.endIndex, code[next] == "-" {
          var tokens = rules.tokenize(line: String(code[..<index]))
          tokens.append(Token(String(code[index...]), .comment))
          return tokens
        }
      }
      index = code.index(after: index)
    }
    return rules.tokenize(line: code)
  }
}
