import Foundation
import SwiftData
import SwiftUI
import Testing

@testable import TextFriend

@MainActor
struct TextStatsTests {
  @Test func emptyText() {
    let stats = TextStats.compute(from: "")
    #expect(stats == TextStats.empty)
    #expect(stats.lines == 1)
  }

  @Test func countsWordsLinesAndCharacters() {
    let stats = TextStats.compute(from: "hello world\nsecond line\n")
    #expect(stats.words == 4)
    #expect(stats.lines == 3)
    #expect(stats.characters == 24)
  }

  @Test func multipleSpacesDoNotInflateWordCount() {
    #expect(TextStats.compute(from: "a   b\t\tc").words == 3)
  }
}

@MainActor
struct EditorThemeTests {
  @Test func allThemesHaveUniqueIDs() {
    let ids = EditorTheme.all.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test func everyThemeColorsAllNonPlainTokenTypes() {
    for theme in EditorTheme.all {
      for tokenType in TokenType.allCases where tokenType != .plain {
        #expect(theme.color(for: tokenType) != nil, "\(theme.id) missing \(tokenType)")
      }
    }
  }

  @Test func plainHasNoColorSoSystemLabelIsUsed() {
    for theme in EditorTheme.all {
      #expect(theme.color(for: .plain) == nil)
    }
  }

  @Test func unknownThemeIDFallsBackToDefault() {
    #expect(EditorTheme.theme(id: "nope") == .friend)
    #expect(EditorTheme.theme(id: "midnight") == .midnight)
  }
}

@MainActor
struct HighlightRendererTests {
  @Test func appliesColorsToMatchingRanges() {
    let source = "name: value"
    let text = HighlightRenderer.highlighted(source, language: .yaml, theme: .friend)
    #expect(String(text.characters) == source)

    let keyRun = text.runs.first { run in
      String(text[run.range].characters) == "name"
    }
    #expect(keyRun?.foregroundColor == EditorTheme.friend.color(for: .key))
  }

  @Test func mismatchedTokensFallBackToUnstyled() {
    var text = AttributedString("short")
    let tokens = [Token("much longer than the text", .keyword)]
    HighlightRenderer.apply(tokens: tokens, to: &text, theme: .friend)
    #expect(text.runs.allSatisfy { $0.foregroundColor == nil })
  }

  @Test func linksAreUnderlined() {
    let source = "[a](https://b.dev)"
    let text = HighlightRenderer.highlighted(source, language: .markdown, theme: .friend)
    #expect(text.runs.contains { $0.underlineStyle == .single })
  }
}

@MainActor
struct DocumentTests {
  @Test func decodeUTF8() throws {
    let text = "grüße: welt ✓"
    #expect(try TextFriendDocument.decode(Data(text.utf8)) == text)
  }

  @Test func decodeLatin1Fallback() throws {
    let latin1 = "caf\u{E9}".data(using: .isoLatin1)!
    let decoded = try TextFriendDocument.decode(latin1)
    #expect(decoded == "café")
  }

  @Test func writeProducesUTF8Bytes() {
    let document = TextFriendDocument(text: "key: välue")
    #expect(document.encoded() == Data("key: välue".utf8))
  }

  @Test func roundTrip() throws {
    let original = "a: 1\nb: \"zwei\"\n"
    let document = TextFriendDocument(text: original)
    let decoded = try TextFriendDocument.decode(document.encoded())
    #expect(decoded == original)
  }
}

@MainActor
struct EditorSettingsTests {
  // The context references its container weakly, so tests must keep the
  // container alive for their whole duration.
  private func inMemoryContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: EditorSettings.self, configurations: configuration)
  }

  @Test func fetchOrCreateCreatesDefaultsOnce() throws {
    let container = try inMemoryContainer()
    let context = container.mainContext
    let first = SettingsStore.fetchOrCreate(in: context)
    #expect(first.fontSize == 14)
    #expect(first.themeID == "friend")
    #expect(first.syntaxHighlightingEnabled)
    #expect(first.validationEnabled)

    let second = SettingsStore.fetchOrCreate(in: context)
    let all = try context.fetch(FetchDescriptor<EditorSettings>())
    #expect(all.count == 1)
    #expect(first === second)
  }

  @Test func changesPersistInContext() throws {
    let container = try inMemoryContainer()
    let context = container.mainContext
    let settings = SettingsStore.fetchOrCreate(in: context)
    settings.fontSize = 18
    settings.themeID = "midnight"
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<EditorSettings>()).first
    #expect(fetched?.fontSize == 18)
    #expect(fetched?.themeID == "midnight")
  }
}
