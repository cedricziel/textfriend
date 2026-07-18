import SwiftData
import SwiftUI

@main
struct TextFriendApp: App {
  let container: ModelContainer

  init() {
    // On a fresh install Application Support doesn't exist yet; creating it
    // up front spares SwiftData a noisy CoreData error-and-recover cycle.
    try? FileManager.default.createDirectory(
      at: .applicationSupportDirectory, withIntermediateDirectories: true)
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
