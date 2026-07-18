import Testing

@testable import TextFriend

@MainActor
struct JSONValidationTests {
  @Test func validJSONHasNoIssues() {
    #expect(ValidationEngine.validateJSON(#"{"a": [1, 2], "b": null}"#).isEmpty)
  }

  @Test func emptyTextHasNoIssues() {
    #expect(ValidationEngine.validateJSON("").isEmpty)
    #expect(ValidationEngine.validateJSON("  \n ").isEmpty)
  }

  @Test func invalidJSONReportsError() {
    let issues = ValidationEngine.validateJSON(#"{"a": }"#)
    #expect(issues.count == 1)
    #expect(issues.first?.severity == .error)
  }

  @Test func errorLineIsExtractedFromParserMessage() {
    let source = """
      {
        "a": 1,
        "b":
      }
      """
    let issues = ValidationEngine.validateJSON(source)
    #expect(issues.count == 1)
    #expect(issues.first.map { $0.line >= 3 } == true)
  }

  @Test func fragmentsAreAccepted() {
    #expect(ValidationEngine.validateJSON("42").isEmpty)
  }
}

@MainActor
struct YAMLValidationTests {
  @Test func cleanDocumentHasNoIssues() {
    let source = """
      services:
        web:
          image: nginx
        db:
          image: postgres
      """
    #expect(ValidationEngine.validateYAML(source).isEmpty)
  }

  @Test func tabIndentationIsAnError() {
    let issues = ValidationEngine.validateYAML("key:\n\tnested: 1")
    #expect(issues.count == 1)
    #expect(issues.first?.severity == .error)
    #expect(issues.first?.line == 2)
  }

  @Test func duplicateSiblingKeysAreFlagged() {
    let source = """
      name: a
      name: b
      """
    let issues = ValidationEngine.validateYAML(source)
    #expect(issues.count == 1)
    #expect(issues.first?.line == 2)
    #expect(issues.first?.severity == .warning)
  }

  @Test func sameKeyUnderDifferentParentsIsFine() {
    let source = """
      web:
        image: nginx
      db:
        image: postgres
      """
    #expect(ValidationEngine.validateYAML(source).isEmpty)
  }

  @Test func duplicateNestedKeysAreFlagged() {
    let source = """
      web:
        image: nginx
        image: httpd
      """
    let issues = ValidationEngine.validateYAML(source)
    #expect(issues.count == 1)
    #expect(issues.first?.line == 3)
  }

  @Test func commentsAndBlankLinesAreIgnored() {
    let source = """
      # a comment
      key: 1

      other: 2
      """
    #expect(ValidationEngine.validateYAML(source).isEmpty)
  }
}

@MainActor
struct EnvValidationTests {
  @Test func cleanFileHasNoIssues() {
    let source = """
      # comment
      A=1
      export B=2
      """
    #expect(ValidationEngine.validateEnv(source).isEmpty)
  }

  @Test func duplicateKeysAreFlagged() {
    let issues = ValidationEngine.validateEnv("A=1\nA=2")
    #expect(issues.count == 1)
    #expect(issues.first?.line == 2)
  }

  @Test func nonAssignmentLinesAreFlagged() {
    let issues = ValidationEngine.validateEnv("just some words")
    #expect(issues.count == 1)
    #expect(issues.first?.severity == .warning)
  }

  @Test func dispatchByLanguage() {
    #expect(ValidationEngine.validate("{", language: .json).isEmpty == false)
    #expect(ValidationEngine.validate("a: 1\na: 2", language: .yaml).isEmpty == false)
    #expect(ValidationEngine.validate("A=1\nA=2", language: .env).isEmpty == false)
    #expect(ValidationEngine.validate("anything", language: .plain).isEmpty)
    #expect(ValidationEngine.validate("anything", language: .markdown).isEmpty)
  }
}
