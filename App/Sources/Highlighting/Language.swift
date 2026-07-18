import Foundation

/// The set of formats TextFriend understands.
enum Language: String, CaseIterable, Identifiable, Sendable {
  case yaml
  case json
  case toml
  case ini
  case env
  case markdown
  case xml
  case shell
  case plain

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .yaml: "YAML"
    case .json: "JSON"
    case .toml: "TOML"
    case .ini: "INI"
    case .env: ".env"
    case .markdown: "Markdown"
    case .xml: "XML"
    case .shell: "Shell"
    case .plain: "Plain Text"
    }
  }

  var highlighter: any SyntaxHighlighter {
    switch self {
    case .yaml: YAMLHighlighter()
    case .json: JSONHighlighter()
    case .toml: TOMLHighlighter()
    case .ini: INIHighlighter()
    case .env: EnvHighlighter()
    case .markdown: MarkdownHighlighter()
    case .xml: XMLHighlighter()
    case .shell: ShellHighlighter()
    case .plain: PlainHighlighter()
    }
  }

  /// Detects the language from a file name, considering well-known
  /// extension-less names (`.env`, `Dockerfile`, …) first.
  static func detect(filename: String) -> Language {
    let lower = filename.lowercased()

    if lower == ".env" || lower.hasPrefix(".env.") { return .env }
    if lower == "dockerfile" || lower == "makefile" { return .shell }
    if lower == ".gitignore" || lower == ".dockerignore" { return .shell }
    if lower == ".gitconfig" || lower == ".editorconfig" { return .ini }

    switch (lower as NSString).pathExtension {
    case "yml", "yaml": return .yaml
    case "json", "jsonc", "geojson", "webmanifest": return .json
    case "toml": return .toml
    case "ini", "cfg", "conf", "properties", "editorconfig": return .ini
    case "env": return .env
    case "md", "markdown", "mdown": return .markdown
    case "xml", "plist", "svg", "xsd", "xsl", "xslt", "storyboard", "xib": return .xml
    case "sh", "bash", "zsh", "ksh": return .shell
    default: return .plain
    }
  }
}
