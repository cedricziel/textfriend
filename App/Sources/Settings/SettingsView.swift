import SwiftData
import SwiftUI

struct SettingsView: View {
  @Bindable var settings: EditorSettings
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack {
            Text("Font Size")
            Spacer()
            Text("\(Int(settings.fontSize)) pt")
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
          Slider(value: $settings.fontSize, in: 11...24, step: 1) {
            Text("Font Size")
          }
        } header: {
          Text("Text")
        }

        Section {
          Picker("Theme", selection: $settings.themeID) {
            ForEach(EditorTheme.all) { theme in
              Text(theme.name).tag(theme.id)
            }
          }
          Toggle("Syntax Highlighting", isOn: $settings.syntaxHighlightingEnabled)
          Toggle("Check for Problems", isOn: $settings.validationEnabled)
        } header: {
          Text("Highlighting")
        } footer: {
          Text(
            "Problem checks cover JSON syntax, YAML indentation and duplicate keys, and .env files."
          )
        }

        Section {
          LabeledContent("Version", value: appVersion)
        } header: {
          Text("About")
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
  }
}
