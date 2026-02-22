import SwiftUI

struct ContentView: View {
    var records: [JSONRecord]
    var error: String?
    var hasFile: Bool
    var isLoading: Bool
    var hasMoreRecords: Bool
    var searchManager: SearchManager?
    @Binding var scrollToRecordId: Int?
    var onLoadMore: () -> Void
    var onFileOpened: (URL) -> Void
    
    @State private var isTargeted = false
    
    // Pre-compute matches by record ID for O(1) lookup
    private var matchesByRecordId: [Int: [SearchMatch]] {
        guard let searchManager = searchManager else { return [:] }
        var result: [Int: [SearchMatch]] = [:]
        for match in searchManager.matches {
            guard match.recordIndex < records.count else { continue }
            let recordId = records[match.recordIndex].lineNumber
            result[recordId, default: []].append(match)
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let error = error {
                errorView(error)
            } else if records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .overlay(
            Group {
                if isTargeted {
                    Color.accentColor.opacity(0.1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                        )
                        .padding(20)
                        .ignoresSafeArea()
                }
            }
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(hasFile ? "Empty File" : "Open a JSONL File")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Drag and drop a file here, or click Open")
                .foregroundColor(.secondary)
            
            Button(action: openFile) {
                Text("Open File")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("o", modifiers: .command)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var recordsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(records) { record in
                        RecordCardView(
                            record: record,
                            searchQuery: searchManager?.query ?? "",
                            isCaseSensitive: searchManager?.isCaseSensitive ?? false,
                            isWholeWord: searchManager?.isWholeWord ?? false,
                            isRegex: searchManager?.isRegex ?? false,
                            isCurrentMatch: searchManager?.currentMatch?.recordIndex == records.firstIndex(where: { $0.id == record.id }),
                            highlightedKeys: highlightedKeysForRecord(record)
                        )
                        .contextMenu {
                            Button(action: {
                                copyRecordToClipboard(record)
                            }) {
                                Label("Copy JSON", systemImage: "doc.on.doc")
                            }
                        }
                        .onAppear {
                            // Trigger load more when near the end
                            if record.id == records.last?.id && hasMoreRecords {
                                onLoadMore()
                            }
                        }
                        .id(record.lineNumber)
                    }
                    
                    // Loading indicator
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading more...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                    }
                    
                    if hasMoreRecords && !isLoading {
                        Text("Scroll down for more records")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
                .padding(20)
            }
            .onChange(of: scrollToRecordId) { _, newValue in
                if let id = newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error Loading File")
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        
        if panel.runModal() == .OK, let url = panel.url {
            onFileOpened(url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                onFileOpened(url)
            }
        }
    }
    
    private func copyRecordToClipboard(_ record: JSONRecord) {
        guard let data = record.data,
              let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(jsonString, forType: .string)
    }
    
    private func highlightedKeysForRecord(_ record: JSONRecord) -> Set<String> {
        guard let searchManager = searchManager, !searchManager.query.isEmpty else { return [] }
        
        var keys = Set<String>()
        if let matches = matchesByRecordId[record.lineNumber] {
            for match in matches {
                if let keyPath = match.keyPath {
                    keys.insert(keyPath)
                }
            }
        }
        return keys
    }
}

#Preview {
    ContentView(
        records: [],
        error: nil,
        hasFile: false,
        isLoading: false,
        hasMoreRecords: false,
        searchManager: nil,
        scrollToRecordId: .constant(nil),
        onLoadMore: {},
        onFileOpened: { _ in }
    )
    .frame(width: 800, height: 600)
}
