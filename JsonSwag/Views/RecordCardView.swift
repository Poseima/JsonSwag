import SwiftUI

struct RecordCardView: View, Equatable {
    let record: JSONRecord
    var searchQuery: String = ""
    var isCaseSensitive: Bool = false
    var isWholeWord: Bool = false
    var isRegex: Bool = false
    var isCurrentMatch: Bool = false
    var highlightedKeys: Set<String> = []
    
    @State private var expandState: ExpandAllState = .none
    
    static func == (lhs: RecordCardView, rhs: RecordCardView) -> Bool {
        lhs.record.id == rhs.record.id &&
        lhs.record.sortedKeys == rhs.record.sortedKeys &&
        lhs.searchQuery == rhs.searchQuery &&
        lhs.isCurrentMatch == rhs.isCurrentMatch &&
        lhs.highlightedKeys == rhs.highlightedKeys
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Text("Record \(record.lineNumber)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isCurrentMatch ? .accentColor : .secondary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    // Expand/Collapse button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandState == .expandAll {
                                expandState = .collapseAll
                            } else {
                                expandState = .expandAll
                            }
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(expandState == .expandAll ? .accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(expandState == .expandAll ? "Collapse All" : "Expand All")
                    
                    // Copy button
                    Button(action: copyToClipboard) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Copy JSON")
                }
            }
            
            Divider()
            
            // Content
            if let error = record.error {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                }
            } else if record.data != nil {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(record.sortedKeys, id: \.self) { key in
                        KeyValueRowView(
                            key: key,
                            value: record.data?[key],
                            searchQuery: searchQuery,
                            isCaseSensitive: isCaseSensitive,
                            isWholeWord: isWholeWord,
                            isRegex: isRegex,
                            isKeyHighlighted: highlightedKeys.contains(key),
                            keyPath: key
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentMatch ? Color.accentColor : Color(nsColor: .separatorColor).opacity(0.3),
                        lineWidth: isCurrentMatch ? 2 : 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            copyToClipboard()
        }
        .environment(\.expandAllState, expandState)
    }
    
    private func copyToClipboard() {
        guard let data = record.data,
              let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(jsonString, forType: .string)
    }
}
