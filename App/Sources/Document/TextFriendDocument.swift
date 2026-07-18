import SwiftUI
import UniformTypeIdentifiers

nonisolated extension UTType {
  static let markdownDoc = UTType(
    importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
  static let toml = UTType(importedAs: "org.toml.toml", conformingTo: .plainText)
  static let iniFile = UTType(importedAs: "com.cedricziel.textfriend.ini", conformingTo: .plainText)
  static let envFile = UTType(importedAs: "com.cedricziel.textfriend.env", conformingTo: .plainText)
}

/// A plain-text document. TextFriend never transforms content on load or
/// save — bytes in, bytes out (as UTF-8).
nonisolated struct TextFriendDocument: FileDocument {
  // `.data` comes last: any file explicitly handed to TextFriend (share
  // sheet, "Open in…") opens as text, even when the sender vends a generic
  // type — e.g. exported chat artifacts and extensionless config files.
  static let readableContentTypes: [UTType] = [
    .plainText, .text, .yaml, .json, .xml, .shellScript, .commaSeparatedText,
    .markdownDoc, .toml, .iniFile, .envFile, .data,
  ]

  var text: String
  var filename: String?

  init(text: String = "") {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    self.text = try Self.decode(data)
    self.filename = configuration.file.filename
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: encoded())
  }

  /// The exact bytes written to disk.
  func encoded() -> Data {
    Data(text.utf8)
  }

  /// Decodes file data as UTF-8, falling back to Latin-1 for legacy files.
  static func decode(_ data: Data) throws -> String {
    if let string = String(data: data, encoding: .utf8) {
      return string
    }
    if let string = String(data: data, encoding: .isoLatin1) {
      return string
    }
    throw CocoaError(.fileReadInapplicableStringEncoding)
  }
}
