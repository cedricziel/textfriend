import Foundation
import SwiftData

/// User preferences, persisted with SwiftData. The app keeps exactly one row.
@Model
final class EditorSettings {
  var fontSize: Double
  var themeID: String
  var syntaxHighlightingEnabled: Bool
  var validationEnabled: Bool

  init(
    fontSize: Double = 14,
    themeID: String = "friend",
    syntaxHighlightingEnabled: Bool = true,
    validationEnabled: Bool = true
  ) {
    self.fontSize = fontSize
    self.themeID = themeID
    self.syntaxHighlightingEnabled = syntaxHighlightingEnabled
    self.validationEnabled = validationEnabled
  }
}

enum SettingsStore {
  /// Returns the single settings row, creating it on first launch.
  @discardableResult
  static func fetchOrCreate(in context: ModelContext) -> EditorSettings {
    if let existing = (try? context.fetch(FetchDescriptor<EditorSettings>()))?.first {
      return existing
    }
    let settings = EditorSettings()
    context.insert(settings)
    try? context.save()
    return settings
  }
}
