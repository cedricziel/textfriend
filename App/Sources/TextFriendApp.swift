import SwiftData
import SwiftUI

@main
struct TextFriendApp: App {
  let container: ModelContainer

  init() {
    do {
      container = try ModelContainer(for: EditorSettings.self)
    } catch {
      // The schema is tiny and local; if the store is corrupt, start fresh
      // in memory rather than crash on launch.
      let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
      container = try! ModelContainer(for: EditorSettings.self, configurations: fallback)
    }
    SettingsStore.fetchOrCreate(in: container.mainContext)
  }

  var body: some Scene {
    DocumentGroup(newDocument: TextFriendDocument()) { file in
      EditorView(document: file.$document, fileURL: file.fileURL)
    }
    .modelContainer(container)
  }
}
