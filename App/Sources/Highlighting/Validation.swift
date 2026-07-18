import Foundation

/// A problem found in a document, anchored to a 1-based line number.
struct ValidationIssue: Identifiable, Equatable, Hashable {
  enum Severity: Equatable, Hashable {
    case warning
    case error
  }

  let line: Int
  let message: String
  let severity: Severity

  var id: String { "\(line):\(message)" }
}

/// Cheap, dependency-free validation for the formats where broken files
/// hurt the most.
enum ValidationEngine {
  static func validate(_ text: String, language: Language) -> [ValidationIssue] {
    switch language {
    case .json: validateJSON(text)
    case .yaml: validateYAML(text)
    case .env: validateEnv(text)
    default: []
    }
  }

  // MARK: - JSON

  static func validateJSON(_ text: String) -> [ValidationIssue] {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let data = Data(text.utf8)
    do {
      _ = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
      return []
    } catch let error as NSError {
      let description =
        (error.userInfo[NSDebugDescriptionErrorKey] as? String) ?? error.localizedDescription
      let line = jsonErrorLine(from: description, in: text)
      return [
        ValidationIssue(line: line, message: "Invalid JSON: \(description)", severity: .error)
      ]
    }
  }

  /// Extracts the failure position from a JSONSerialization error message.
  /// Depending on the Foundation version the message says either
  /// "around line N, column M" or "around character N".
  private static func jsonErrorLine(from description: String, in text: String) -> Int {
    if let match = description.firstMatch(of: /line (\d+)/), let line = Int(match.1) {
      return line
    }
    guard
      let match = description.firstMatch(of: /character (\d+)/),
      let offset = Int(match.1)
    else { return 1 }
    let bytes = Array(text.utf8.prefix(offset))
    return bytes.count(where: { $0 == UInt8(ascii: "\n") }) + 1
  }

  // MARK: - YAML

  private static let yamlKeyPattern = try! NSRegularExpression(
    pattern: #"^(\s*)(?:- +)*("(?:[^"\\]|\\.)*"|'(?:[^']|'')*'|[^\s#\{\[][^:#]*?)\s*:(?:\s|$)"#)

  static func validateYAML(_ text: String) -> [ValidationIssue] {
    var issues: [ValidationIssue] = []
    // Keys seen per indentation depth. A key at indent i resets all deeper
    // levels, so sibling maps under different parents don't collide.
    var keysByIndent: [Int: Set<String>] = [:]

    for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false)
      .enumerated()
    {
      let lineNumber = index + 1
      let line = String(rawLine)

      let leadingWhitespace = line.prefix { $0 == " " || $0 == "\t" }
      if leadingWhitespace.contains("\t") {
        issues.append(
          ValidationIssue(
            line: lineNumber,
            message: "Tab character in indentation — YAML requires spaces",
            severity: .error))
      }

      let ns = line as NSString
      guard
        let match = yamlKeyPattern.firstMatch(
          in: line, range: NSRange(location: 0, length: ns.length))
      else { continue }

      let indent = match.range(at: 1).length
      let key = ns.substring(with: match.range(at: 2))

      for deeperIndent in keysByIndent.keys where deeperIndent > indent {
        keysByIndent.removeValue(forKey: deeperIndent)
      }
      if keysByIndent[indent, default: []].contains(key) {
        issues.append(
          ValidationIssue(
            line: lineNumber,
            message: "Duplicate key “\(key)”",
            severity: .warning))
      }
      keysByIndent[indent, default: []].insert(key)
    }
    return issues
  }

  // MARK: - .env

  private static let envLinePattern = try! NSRegularExpression(
    pattern: #"^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*="#)

  static func validateEnv(_ text: String) -> [ValidationIssue] {
    var issues: [ValidationIssue] = []
    var seenKeys: Set<String> = []

    for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false)
      .enumerated()
    {
      let lineNumber = index + 1
      let line = String(rawLine)
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

      let ns = line as NSString
      guard
        let match = envLinePattern.firstMatch(
          in: line, range: NSRange(location: 0, length: ns.length))
      else {
        issues.append(
          ValidationIssue(
            line: lineNumber,
            message: "Line is not a KEY=value assignment",
            severity: .warning))
        continue
      }

      let key = ns.substring(with: match.range(at: 1))
      if seenKeys.contains(key) {
        issues.append(
          ValidationIssue(
            line: lineNumber,
            message: "Duplicate key “\(key)” — the last value wins",
            severity: .warning))
      }
      seenKeys.insert(key)
    }
    return issues
  }
}
