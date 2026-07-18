import Testing

@testable import TextFriend

@MainActor
struct XMLHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    XMLHighlighter().tokenize(source)
  }

  @Test func highlightsTags() {
    let result = tokens("<note>text</note>")
    #expect(type(of: "<note", in: result) == .keyword)
    #expect(type(of: "</note", in: result) == .keyword)
    #expect(type(of: "text", in: result) == .plain)
  }

  @Test func highlightsAttributes() {
    let result = tokens(#"<a href="https://x.dev" id='m'>"#)
    #expect(type(of: "href", in: result) == .key)
    #expect(type(of: #""https://x.dev""#, in: result) == .string)
    #expect(type(of: "'m'", in: result) == .string)
  }

  @Test func highlightsDeclarationAndDoctype() {
    let result = tokens("<?xml version=\"1.0\"?>\n<!DOCTYPE plist>")
    #expect(typeContaining("<?xml", in: result) == .meta)
    #expect(typeContaining("DOCTYPE", in: result) == .meta)
  }

  @Test func highlightsEntities() {
    let result = tokens("<p>a &amp; b &#169;</p>")
    #expect(type(of: "&amp;", in: result) == .constant)
    #expect(type(of: "&#169;", in: result) == .constant)
  }

  @Test func singleLineComment() {
    let result = tokens("<a/><!-- note --><b/>")
    #expect(type(of: "<!-- note -->", in: result) == .comment)
    #expect(type(of: "<b", in: result) == .keyword)
  }

  @Test func multiLineCommentIsStateful() {
    let result = tokens("<!-- start\nmiddle\nend --><tag/>")
    #expect(typeContaining("middle", in: result) == .comment)
    #expect(typeContaining("end -->", in: result) == .comment)
    #expect(type(of: "<tag", in: result) == .keyword)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key>
        <string>TextFriend &amp; Co</string>
      </dict>
      </plist>
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
