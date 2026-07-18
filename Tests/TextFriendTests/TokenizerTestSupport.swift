import Testing

@testable import TextFriend

/// Concatenates token texts — every tokenizer must reproduce its input.
func rejoined(_ tokens: [Token]) -> String {
  tokens.map(\.text).joined()
}

/// Returns the type of the first token whose text equals `text`.
func type(of text: String, in tokens: [Token]) -> TokenType? {
  tokens.first { $0.text == text }?.type
}

/// Returns the type of the first token whose text contains `substring`.
func typeContaining(_ substring: String, in tokens: [Token]) -> TokenType? {
  tokens.first { $0.text.contains(substring) }?.type
}
