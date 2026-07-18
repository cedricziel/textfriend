import Foundation

struct ShellHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"'[^']*'"#, .string),
    HighlightRule(
      #"(?<![\w$-])(if|then|else|elif|fi|for|in|while|until|do|done|case|esac|function|select|return|exit|export|local|readonly|declare|unset|shift|source|alias|set|echo|cd)(?![\w-])"#,
      .keyword),
    HighlightRule(#"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*|\$[@#?$!*0-9-]"#, .meta),
    HighlightRule(#"(?<![\w.])-?\d+(?:\.\d+)?\b"#, .number),
    HighlightRule(#"[|&;<>()]+"#, .punctuation),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      if line.hasPrefix("#!") {
        return [Token(line, .meta)]
      }
      let (code, comment) = CommentSplit.split(line: line)
      var tokens = Self.rules.tokenize(line: code)
      if let comment {
        tokens.append(Token(comment, .comment))
      }
      return tokens
    }
  }
}
