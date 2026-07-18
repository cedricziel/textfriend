import SwiftData
import SwiftUI

/// The main editor. Uses the iOS 26 `TextEditor` with an `AttributedString`
/// binding; highlighting mutates attributes only, so the caret and undo
/// stack survive re-highlights.
struct EditorView: View {
  @Binding var document: TextFriendDocument
  let fileURL: URL?

  @Query private var settingsRows: [EditorSettings]

  @State private var text = AttributedString()
  @State private var selection = AttributedTextSelection()
  @State private var isLoaded = false
  @State private var lastHighlightedSource: String?
  @State private var highlightTask: Task<Void, Never>?
  @State private var stats = TextStats.empty
  @State private var issues: [ValidationIssue] = []
  @State private var languageOverride: Language?
  @State private var isFindPresented = false
  @State private var isSettingsPresented = false

  private var settings: EditorSettings? { settingsRows.first }
  private var fontSize: Double { settings?.fontSize ?? 14 }
  private var theme: EditorTheme { EditorTheme.theme(id: settings?.themeID ?? "friend") }
  private var highlightingEnabled: Bool { settings?.syntaxHighlightingEnabled ?? true }
  private var validationEnabled: Bool { settings?.validationEnabled ?? true }

  private var detectedLanguage: Language {
    Language.detect(filename: fileURL?.lastPathComponent ?? document.filename ?? "")
  }
  private var language: Language { languageOverride ?? detectedLanguage }

  var body: some View {
    TextEditor(text: $text, selection: $selection)
      .font(.system(size: fontSize, design: .monospaced))
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .findNavigator(isPresented: $isFindPresented)
      .scrollEdgeEffectStyle(.soft, for: .top)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        StatusBarView(language: language, stats: stats, issues: issues)
      }
      .toolbar { toolbarContent }
      .sheet(isPresented: $isSettingsPresented) {
        if let settings {
          SettingsView(settings: settings)
        }
      }
      .onAppear(perform: loadIfNeeded)
      .onChange(of: text) { syncDocumentAndScheduleHighlight() }
      .onChange(of: language) { rehighlightNow() }
      .onChange(of: settings?.themeID) { rehighlightNow() }
      .onChange(of: settings?.syntaxHighlightingEnabled) { rehighlightNow() }
      .onChange(of: settings?.validationEnabled) { refreshDiagnostics() }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Button("Find", systemImage: "magnifyingglass") {
        isFindPresented = true
      }
    }
    ToolbarItem(placement: .topBarTrailing) {
      languageMenu
    }
    ToolbarSpacer(.fixed)
    ToolbarItem(placement: .topBarTrailing) {
      Button("Settings", systemImage: "gearshape") {
        isSettingsPresented = true
      }
    }
    ToolbarItemGroup(placement: .keyboard) {
      keyboardAccessory
    }
  }

  private var languageMenu: some View {
    Menu {
      Picker("Syntax", selection: languageSelection) {
        ForEach(Language.allCases) { candidate in
          Text(candidate.displayName).tag(candidate)
        }
      }
    } label: {
      Label("Syntax", systemImage: "chevron.left.forwardslash.chevron.right")
    }
  }

  private var languageSelection: Binding<Language> {
    Binding(
      get: { language },
      set: { languageOverride = $0 == detectedLanguage ? nil : $0 }
    )
  }

  private var keyboardAccessory: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        Button("Indent", systemImage: "arrow.forward.to.line") { insert("  ") }
        ForEach(["-", ":", "=", "#", "\"", "'", "[", "]", "{", "}", "|", ">", "$"], id: \.self) {
          symbol in
          Button {
            insert(symbol)
          } label: {
            Text(symbol)
              .font(.system(size: 16, design: .monospaced))
              .frame(minWidth: 28)
          }
          .accessibilityLabel("Insert \(symbol)")
        }
      }
    }
  }

  // MARK: - Editing

  private func insert(_ snippet: String) {
    let insertion = AttributedString(snippet)
    switch selection.indices(in: text) {
    case .insertionPoint(let index):
      text.transform(updating: &selection) { working in
        working.insert(insertion, at: index)
      }
    case .ranges(let ranges):
      if let first = ranges.ranges.first {
        text.transform(updating: &selection) { working in
          working.replaceSubrange(first, with: insertion)
        }
      }
    @unknown default:
      text.append(insertion)
    }
  }

  // MARK: - Highlighting pipeline

  private func loadIfNeeded() {
    guard !isLoaded else { return }
    isLoaded = true
    text = AttributedString(document.text)
    performHighlight()
  }

  private func syncDocumentAndScheduleHighlight() {
    let source = String(text.characters)
    if document.text != source {
      document.text = source
    }
    guard source != lastHighlightedSource else { return }
    highlightTask?.cancel()
    highlightTask = Task {
      try? await Task.sleep(for: .milliseconds(150))
      guard !Task.isCancelled else { return }
      performHighlight()
    }
  }

  private func rehighlightNow() {
    lastHighlightedSource = nil
    performHighlight()
  }

  private func performHighlight() {
    let source = String(text.characters)
    lastHighlightedSource = source
    let tokens =
      highlightingEnabled
      ? language.highlighter.tokenize(source)
      : PlainHighlighter().tokenize(source)
    text.transform(updating: &selection) { working in
      HighlightRenderer.apply(tokens: tokens, to: &working, theme: theme)
    }
    stats = TextStats.compute(from: source)
    refreshDiagnostics(source: source)
  }

  private func refreshDiagnostics(source: String? = nil) {
    let current = source ?? String(text.characters)
    issues = validationEnabled ? ValidationEngine.validate(current, language: language) : []
  }
}
