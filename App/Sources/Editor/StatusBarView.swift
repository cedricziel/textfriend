import SwiftUI

/// Bottom bar showing the active syntax, live document stats, and any
/// validation issues (tap to see details).
struct StatusBarView: View {
  let language: Language
  let stats: TextStats
  let issues: [ValidationIssue]

  @State private var isIssueListPresented = false

  var body: some View {
    HStack(spacing: 12) {
      Text(language.displayName)
        .fontWeight(.medium)

      Spacer()

      if !issues.isEmpty {
        Button {
          isIssueListPresented = true
        } label: {
          Label("\(issues.count)", systemImage: issueIcon)
            .foregroundStyle(issueColor)
        }
        .popover(isPresented: $isIssueListPresented) {
          issueList
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("\(issues.count) issues found")
      }

      Text("\(stats.lines) lines")
      Text("\(stats.words) words")
      Text("\(stats.characters) chars")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(.bar)
  }

  private var hasErrors: Bool {
    issues.contains { $0.severity == .error }
  }

  private var issueIcon: String {
    hasErrors ? "xmark.octagon.fill" : "exclamationmark.triangle.fill"
  }

  private var issueColor: Color {
    hasErrors ? .red : .orange
  }

  private var issueList: some View {
    List(issues) { issue in
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(
          systemName: issue.severity == .error
            ? "xmark.octagon.fill" : "exclamationmark.triangle.fill"
        )
        .foregroundStyle(issue.severity == .error ? .red : .orange)
        VStack(alignment: .leading, spacing: 2) {
          Text("Line \(issue.line)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
          Text(issue.message)
            .font(.callout)
        }
      }
    }
    .frame(minWidth: 300, minHeight: 180)
  }
}

#Preview {
  StatusBarView(
    language: .yaml,
    stats: TextStats(characters: 345, words: 56, lines: 12),
    issues: [
      ValidationIssue(line: 3, message: "Duplicate key “name”", severity: .warning)
    ])
}
