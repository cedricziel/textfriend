import Testing

@testable import TextFriend

@MainActor
struct DockerfileHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    DockerfileHighlighter().tokenize(source)
  }

  @Test func highlightsInstructions() {
    let result = tokens("FROM nginx:latest AS base\nRUN apt-get update")
    #expect(type(of: "FROM", in: result) == .keyword)
    #expect(type(of: "AS", in: result) == .keyword)
    #expect(type(of: "RUN", in: result) == .keyword)
  }

  @Test func highlightsVariablesFlagsAndComments() {
    let result = tokens("# build stage\nCOPY --from=builder $APP ${DEST}/bin")
    #expect(type(of: "# build stage", in: result) == .comment)
    #expect(type(of: "--from", in: result) == .constant)
    #expect(type(of: "$APP", in: result) == .meta)
    #expect(type(of: "${DEST}", in: result) == .meta)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      FROM node:20 AS build
      WORKDIR /app
      COPY package.json .
      RUN npm ci # install
      CMD ["node", "server.js"]
      """
    #expect(rejoined(tokens(source)) == source)
  }
}

@MainActor
struct HCLHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    HCLHighlighter().tokenize(source)
  }

  @Test func highlightsBlocksAndLabels() {
    let result = tokens(#"resource "aws_instance" "web" {"#)
    #expect(type(of: "resource", in: result) == .keyword)
    #expect(type(of: #""aws_instance""#, in: result) == .string)
  }

  @Test func highlightsAttributesAndValues() {
    let result = tokens("  instance_type = \"t3.micro\"\n  count = 2\n  enabled = true")
    #expect(type(of: "instance_type", in: result) == .key)
    #expect(type(of: #""t3.micro""#, in: result) == .string)
    #expect(type(of: "2", in: result) == .number)
    #expect(type(of: "true", in: result) == .constant)
  }

  @Test func supportsAllThreeCommentStyles() {
    let result = tokens("# hash\n// slashes\na = 1 /* block */ b = 2")
    #expect(type(of: "# hash", in: result) == .comment)
    #expect(type(of: "// slashes", in: result) == .comment)
    #expect(type(of: "/* block */", in: result) == .comment)
    #expect(type(of: "b", in: result) == .key)
  }

  @Test func multiLineBlockCommentIsStateful() {
    let result = tokens("/* start\nmiddle\nend */\nx = 1")
    #expect(typeContaining("middle", in: result) == .comment)
    #expect(type(of: "x", in: result) == .key)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      terraform {
        required_version = ">= 1.5"
      }

      resource "aws_s3_bucket" "assets" {
        bucket = "textfriend-assets" # main bucket
        tags = {
          Environment = "production"
        }
      }
      """
    #expect(rejoined(tokens(source)) == source)
  }
}

@MainActor
struct SQLHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    SQLHighlighter().tokenize(source)
  }

  @Test func highlightsKeywordsCaseInsensitively() {
    let result = tokens("SELECT id FROM users where active = 1;")
    #expect(type(of: "SELECT", in: result) == .keyword)
    #expect(type(of: "FROM", in: result) == .keyword)
    #expect(type(of: "where", in: result) == .keyword)
  }

  @Test func highlightsStringsIdentifiersAndTypes() {
    let result = tokens(#"CREATE TABLE "users" (name VARCHAR, age integer);"#)
    #expect(type(of: #""users""#, in: result) == .key)
    #expect(type(of: "VARCHAR", in: result) == .constant)
    #expect(type(of: "integer", in: result) == .constant)
  }

  @Test func lineCommentRespectsStrings() {
    let result = tokens("SELECT 'a--b' -- real comment")
    #expect(type(of: "'a--b'", in: result) == .string)
    #expect(type(of: "-- real comment", in: result) == .comment)
  }

  @Test func multiLineBlockCommentIsStateful() {
    let result = tokens("/* multi\nline */ SELECT 1")
    #expect(typeContaining("line */", in: result) == .comment)
    #expect(type(of: "SELECT", in: result) == .keyword)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      -- schema
      CREATE TABLE documents (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL DEFAULT 'untitled'
      );
      SELECT * FROM documents WHERE id BETWEEN 1 AND 10;
      """
    #expect(rejoined(tokens(source)) == source)
  }
}

@MainActor
struct DiffHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    DiffHighlighter().tokenize(source)
  }

  @Test func classifiesLineTypes() {
    let source = """
      diff --git a/x.txt b/x.txt
      --- a/x.txt
      +++ b/x.txt
      @@ -1,2 +1,2 @@
       context
      -removed line
      +added line
      """
    let result = tokens(source)
    #expect(typeContaining("diff --git", in: result) == .meta)
    #expect(typeContaining("--- a/x.txt", in: result) == .meta)
    #expect(typeContaining("@@ -1,2", in: result) == .heading)
    #expect(typeContaining("-removed", in: result) == .keyword)
    #expect(typeContaining("+added", in: result) == .string)
    #expect(typeContaining(" context", in: result) == .plain)
    #expect(rejoined(result) == source)
  }
}

@MainActor
struct LogHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    LogHighlighter().tokenize(source)
  }

  @Test func highlightsTimestampsAndLevels() {
    let result = tokens("2026-07-18T20:15:01.123Z ERROR something broke")
    #expect(type(of: "2026-07-18T20:15:01.123Z", in: result) == .number)
    #expect(type(of: "ERROR", in: result) == .keyword)
  }

  @Test func distinguishesSeverities() {
    let result = tokens("WARN a\nINFO b\nDEBUG c")
    #expect(type(of: "WARN", in: result) == .emphasis)
    #expect(type(of: "INFO", in: result) == .key)
    #expect(type(of: "DEBUG", in: result) == .comment)
  }

  @Test func highlightsSyslogTimestampsAndIPs() {
    let result = tokens("Jul 18 20:15:01 host sshd: from 192.168.1.10:22")
    #expect(type(of: "Jul 18 20:15:01", in: result) == .number)
    #expect(type(of: "192.168.1.10:22", in: result) == .constant)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      2026-07-18 20:15:01,123 INFO  Starting service
      2026-07-18 20:15:02,456 ERROR Connection refused from 10.0.0.5
      """
    #expect(rejoined(tokens(source)) == source)
  }
}

@MainActor
struct CrontabHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    CrontabHighlighter().tokenize(source)
  }

  @Test func highlightsScheduleFields() {
    let result = tokens("*/5 2-4 * * 1 /usr/local/bin/backup.sh")
    #expect(type(of: "*/5 2-4 * * 1", in: result) == .number)
  }

  @Test func highlightsNicknamesAndEnv() {
    let result = tokens("@daily /bin/cleanup\nMAILTO=admin@example.com")
    #expect(type(of: "@daily", in: result) == .meta)
    #expect(type(of: "MAILTO", in: result) == .key)
  }

  @Test func highlightsComments() {
    let result = tokens("# run backups\n0 3 * * * $HOME/backup")
    #expect(type(of: "# run backups", in: result) == .comment)
    #expect(type(of: "$HOME", in: result) == .meta)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      # m h dom mon dow command
      MAILTO=ops@example.com
      */15 * * * * /usr/bin/health-check # every 15 min
      @reboot /usr/local/bin/startup
      """
    #expect(rejoined(tokens(source)) == source)
  }
}

@MainActor
struct StringsHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    StringsHighlighter().tokenize(source)
  }

  @Test func distinguishesKeysFromValues() {
    let result = tokens(#""welcome.title" = "Hello, friend!";"#)
    #expect(type(of: #""welcome.title""#, in: result) == .key)
    #expect(type(of: #""Hello, friend!""#, in: result) == .string)
    #expect(type(of: "=", in: result) == .punctuation)
  }

  @Test func supportsBothCommentStyles() {
    let result = tokens("/* section */\n// note\n\"a\" = \"b\";")
    #expect(type(of: "/* section */", in: result) == .comment)
    #expect(type(of: "// note", in: result) == .comment)
  }

  @Test func multiLineBlockCommentIsStateful() {
    let result = tokens("/* start\nend */\n\"k\" = \"v\";")
    #expect(typeContaining("end */", in: result) == .comment)
    #expect(type(of: #""k""#, in: result) == .key)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      /* Localizable.strings */
      "app.name" = "TextFriend";
      "error.encoding" = "The file couldn\\'t be decoded.";
      """
    #expect(rejoined(tokens(source)) == source)
  }
}

@MainActor
struct CSVHighlighterTests {
  private func tokens(_ source: String) -> [Token] {
    CSVHighlighter().tokenize(source)
  }

  @Test func firstLineIsHeader() {
    let result = tokens("name,age,city\nAlice,30,Berlin")
    #expect(type(of: "name", in: result) == .key)
    #expect(type(of: "age", in: result) == .key)
    #expect(type(of: "Alice", in: result) == .plain)
    #expect(type(of: "30", in: result) == .number)
  }

  @Test func highlightsQuotedFieldsAndDelimiters() {
    let result = tokens("a,b\n\"quoted, field\",2.5")
    #expect(type(of: "\"quoted, field\"", in: result) == .string)
    #expect(type(of: "2.5", in: result) == .number)
    #expect(result.filter { $0.type == .punctuation }.count == 2)
  }

  @Test func tabSeparatedWorksToo() {
    let result = tokens("col1\tcol2\nx\t42")
    #expect(type(of: "col1", in: result) == .key)
    #expect(type(of: "42", in: result) == .number)
  }

  @Test func losslessOnRealisticDocument() {
    let source = """
      id,name,price,active
      1,"Widget, large",9.99,true
      2,Gadget,12.50,false
      """
    #expect(rejoined(tokens(source)) == source)
  }
}
