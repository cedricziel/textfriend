import Foundation

struct DockerfileHighlighter: SyntaxHighlighter {
  private static let rules = LineRules([
    HighlightRule(
      #"^\s*(?i:FROM|RUN|CMD|LABEL|MAINTAINER|EXPOSE|ENV|ADD|COPY|ENTRYPOINT|VOLUME|USER|WORKDIR|ARG|ONBUILD|STOPSIGNAL|HEALTHCHECK|SHELL)\b"#,
      .keyword),
    HighlightRule(#"\b(?i:AS)\b"#, .keyword),
    HighlightRule(#""(?:[^"\\]|\\.)*""#, .string),
    HighlightRule(#"'[^']*'"#, .string),
    HighlightRule(#"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*"#, .meta),
    HighlightRule(#"(?<=\s)--[a-z][\w-]*(?==|\s|$)"#, .constant),
    HighlightRule(#"(?<![\w.])\d+(?:\.\d+)?\b"#, .number),
    HighlightRule(#"[\[\],]"#, .punctuation),
  ])

  func tokenize(_ text: String) -> [Token] {
    tokenizeLines(text) { line in
      let (code, comment) = CommentSplit.split(line: line)
      var tokens = Self.rules.tokenize(line: code)
      if let comment {
        tokens.append(Token(comment, .comment))
      }
      return tokens
    }
  }
}
