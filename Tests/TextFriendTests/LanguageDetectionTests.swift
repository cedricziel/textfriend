import Testing

@testable import TextFriend

@MainActor
struct LanguageDetectionTests {
  @Test(arguments: [
    ("docker-compose.yml", Language.yaml),
    ("config.yaml", Language.yaml),
    ("package.json", Language.json),
    ("tsconfig.jsonc", Language.json),
    ("Cargo.toml", Language.toml),
    ("php.ini", Language.ini),
    ("app.conf", Language.ini),
    ("nginx.cfg", Language.ini),
    ("gradle.properties", Language.ini),
    ("secrets.env", Language.env),
    ("README.md", Language.markdown),
    ("Info.plist", Language.xml),
    ("icon.svg", Language.xml),
    ("deploy.sh", Language.shell),
    ("setup.bash", Language.shell),
    ("notes.txt", Language.plain),
    ("mystery.xyz", Language.plain),
  ])
  func detectsByExtension(filename: String, expected: Language) {
    #expect(Language.detect(filename: filename) == expected)
  }

  @Test(arguments: [
    (".env", Language.env),
    (".env.local", Language.env),
    (".ENV.production", Language.env),
    ("Dockerfile", Language.shell),
    ("Makefile", Language.shell),
    (".gitignore", Language.shell),
    (".editorconfig", Language.ini),
    (".gitconfig", Language.ini),
  ])
  func detectsSpecialFilenames(filename: String, expected: Language) {
    #expect(Language.detect(filename: filename) == expected)
  }

  @Test func caseInsensitiveExtensions() {
    #expect(Language.detect(filename: "CONFIG.YAML") == .yaml)
    #expect(Language.detect(filename: "Data.JSON") == .json)
  }

  @Test func emptyFilenameIsPlain() {
    #expect(Language.detect(filename: "") == .plain)
  }

  @Test func everyLanguageHasDisplayNameAndHighlighter() {
    for language in Language.allCases {
      #expect(!language.displayName.isEmpty)
      #expect(language.highlighter.tokenize("sample").isEmpty == false)
    }
  }
}
