import SwiftUI

struct JSONTreeView: View {
    let rootValue: Any
    var searchQuery: String = ""
    var isCaseSensitive: Bool = false
    var isWholeWord: Bool = false
    var isRegex: Bool = false
    var arrayLoader: LazyJSONArrayLoader?
    var onLoadMore: (() -> Void)?
    
    @State private var expandState: ExpandAllState = .none
    @Environment(\.expandAllState) private var parentExpandState
    @State private var lastParentState: ExpandAllState = .none
    
    private var displayValue: Any {
        if let loader = arrayLoader {
            return loader.visibleItems
        }
        return rootValue
    }
    
    private var arrayCount: Int {
        if let loader = arrayLoader {
            return loader.totalCount
        }
        if let arr = rootValue as? [Any] {
            return arr.count
        }
        return 0
    }
    
    private var isLoading: Bool {
        arrayLoader?.isLoading ?? false
    }
    
    private var hasMoreItems: Bool {
        guard let loader = arrayLoader else { return false }
        return !loader.isFullyLoaded
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                if let loader = arrayLoader {
                    Text("JSON Array (\(loader.totalCount) items)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                } else if rootValue is [String: Any] {
                    Text("JSON Object")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                } else {
                    Text("JSON")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
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
            VStack(alignment: .leading, spacing: 8) {
                if let loader = arrayLoader {
                    // Array with lazy loading
                    ForEach(Array(loader.visibleItems.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("[\(index)]")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .leading)
                            Text(":")
                                .foregroundColor(.secondary)
                            ValueView(
                                value: item,
                                searchQuery: searchQuery,
                                isCaseSensitive: isCaseSensitive,
                                isWholeWord: isWholeWord,
                                isRegex: isRegex,
                                currentKeyPath: "[\(index)]"
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onAppear {
                            if index == loader.visibleItems.count - 1 && hasMoreItems {
                                onLoadMore?()
                            }
                        }
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
                        .padding(.vertical, 8)
                    }
                    
                    if hasMoreItems && !isLoading {
                        Text("Scroll down for more items")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                } else if let obj = rootValue as? [String: Any] {
                    // Object
                    ForEach(Array(obj.keys.sorted()), id: \.self) { key in
                        KeyValueRowView(
                            key: key,
                            value: obj[key],
                            searchQuery: searchQuery,
                            isCaseSensitive: isCaseSensitive,
                            isWholeWord: isWholeWord,
                            isRegex: isRegex,
                            isKeyHighlighted: false,
                            keyPath: key
                        )
                    }
                } else if let arr = rootValue as? [Any] {
                    // Small array (no lazy loading needed)
                    ForEach(Array(arr.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("[\(index)]")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 40, alignment: .leading)
                            Text(":")
                                .foregroundColor(.secondary)
                            ValueView(
                                value: item,
                                searchQuery: searchQuery,
                                isCaseSensitive: isCaseSensitive,
                                isWholeWord: isWholeWord,
                                isRegex: isRegex,
                                currentKeyPath: "[\(index)]"
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
        )
        .environment(\.expandAllState, expandState)
        .onChange(of: parentExpandState) { _, newState in
            if newState != lastParentState {
                withAnimation(.easeInOut(duration: 0.15)) {
                    switch newState {
                    case .expandAll:
                        expandState = .expandAll
                    case .collapseAll:
                        expandState = .collapseAll
                    case .none:
                        break
                    }
                }
                lastParentState = newState
            }
        }
    }
    
    private func copyToClipboard() {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: rootValue, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(jsonString, forType: .string)
    }
}
