import SwiftUI

enum JSONValue: Equatable {
    case string(String)
    case longString(String)
    case number(Double)
    case boolean(Bool)
    case null
    case object([String: Any])
    case array([Any])
    case unknown
    
    static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case (.string(let a), .string(let b)): return a == b
        case (.longString(let a), .longString(let b)): return a == b
        case (.number(let a), .number(let b)): return a == b
        case (.boolean(let a), .boolean(let b)): return a == b
        case (.null, .null): return true
        case (.unknown, .unknown): return true
        default: return false
        }
    }
}

struct ValueView: View {
    let value: Any?
    var searchQuery: String = ""
    var isCaseSensitive: Bool = false
    var isWholeWord: Bool = false
    var isRegex: Bool = false
    var currentKeyPath: String = ""
    
    @Environment(\.expandAllState) private var expandAllState
    @State private var isExpanded: Bool = false
    @State private var lastExpandState: ExpandAllState = .none
    
    private var jsonValue: JSONValue {
        switch value {
        case let s as String:
            if s.count > 200 || s.components(separatedBy: "\n").count >= 3 {
                return .longString(s)
            }
            return .string(s)
        case let n as Double:
            return .number(n)
        case let n as Int:
            return .number(Double(n))
        case let b as Bool:
            return .boolean(b)
        case is NSNull:
            return .null
        case let obj as [String: Any]:
            return .object(obj)
        case let arr as [Any]:
            return .array(arr)
        default:
            return .unknown
        }
    }
    
    var body: some View {
        switch jsonValue {
        case .string(let s):
            HStack(spacing: 4) {
                if searchQuery.isEmpty {
                    Text("\"\(s)\"")
                        .foregroundColor(.blue)
                } else {
                    HighlightedTextView(
                        text: "\"\(s)\"",
                        searchQuery: searchQuery,
                        isCaseSensitive: isCaseSensitive,
                        isWholeWord: isWholeWord,
                        isRegex: isRegex,
                        isHighlighted: true
                    )
                    .foregroundColor(.blue)
                }
                typeBadge("string")
            }
        case .longString(let s):
            VStack(alignment: .leading, spacing: 4) {
                ScrollView {
                    if searchQuery.isEmpty {
                        Text(s)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    } else {
                        HighlightedTextView(
                            text: s,
                            searchQuery: searchQuery,
                            isCaseSensitive: isCaseSensitive,
                            isWholeWord: isWholeWord,
                            isRegex: isRegex,
                            isHighlighted: true
                        )
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    }
                }
                .frame(height: 80)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
                typeBadge("text")
            }
        case .number(let n):
            HStack(spacing: 4) {
                let numStr = n.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(n))" : String(format: "%.4g", n)
                if searchQuery.isEmpty {
                    Text(numStr)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.purple)
                } else {
                    HighlightedTextView(
                        text: numStr,
                        searchQuery: searchQuery,
                        isCaseSensitive: isCaseSensitive,
                        isWholeWord: isWholeWord,
                        isRegex: isRegex,
                        isHighlighted: true
                    )
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.purple)
                }
                typeBadge("number")
            }
        case .boolean(let b):
            HStack(spacing: 4) {
                let boolStr = b ? "true" : "false"
                if searchQuery.isEmpty {
                    Text(boolStr)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                } else {
                    HighlightedTextView(
                        text: boolStr,
                        searchQuery: searchQuery,
                        isCaseSensitive: isCaseSensitive,
                        isWholeWord: isWholeWord,
                        isRegex: isRegex,
                        isHighlighted: true
                    )
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                }
                typeBadge("bool")
            }
        case .null:
            Text("null")
                .italic()
                .foregroundColor(.gray)
        case .object(let obj):
            VStack(alignment: .leading, spacing: 4) {
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle() 
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("{ \(obj.keys.prefix(3).joined(separator: ", "))\(obj.count > 3 ? "..." : "") }")
                            .foregroundColor(.secondary)
                        typeBadge("{\(obj.count)}")
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: expandAllState) { _, newState in
                    if newState != lastExpandState {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            switch newState {
                            case .expandAll:
                                isExpanded = true
                            case .collapseAll:
                                isExpanded = false
                            case .none:
                                break
                            }
                        }
                        lastExpandState = newState
                    }
                }
                .onAppear {
                    // Handle initial state when view appears (for nested views created after expand)
                    if expandAllState == .expandAll && !isExpanded {
                        isExpanded = true
                        lastExpandState = .expandAll
                    } else if expandAllState == .collapseAll && isExpanded {
                        isExpanded = false
                        lastExpandState = .collapseAll
                    }
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(obj.keys.sorted()), id: \.self) { key in
                            HStack(alignment: .top, spacing: 8) {
                                Text(key)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text(":")
                                    .foregroundColor(.secondary)
                                ValueView(
                                    value: obj[key],
                                    searchQuery: searchQuery,
                                    isCaseSensitive: isCaseSensitive,
                                    isWholeWord: isWholeWord,
                                    isRegex: isRegex,
                                    currentKeyPath: currentKeyPath.isEmpty ? key : "\(currentKeyPath).\(key)"
                                )
                            }
                            .padding(.leading, 16)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        case .array(let arr):
            VStack(alignment: .leading, spacing: 4) {
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle() 
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("[ \(arr.count) items ]")
                            .foregroundColor(.secondary)
                        typeBadge("[\(arr.count)]")
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: expandAllState) { _, newState in
                    if newState != lastExpandState {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            switch newState {
                            case .expandAll:
                                isExpanded = true
                            case .collapseAll:
                                isExpanded = false
                            case .none:
                                break
                            }
                        }
                        lastExpandState = newState
                    }
                }
                .onAppear {
                    // Handle initial state when view appears (for nested views created after expand)
                    if expandAllState == .expandAll && !isExpanded {
                        isExpanded = true
                        lastExpandState = .expandAll
                    } else if expandAllState == .collapseAll && isExpanded {
                        isExpanded = false
                        lastExpandState = .collapseAll
                    }
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(arr.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("[\(index)]")
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(":")
                                    .foregroundColor(.secondary)
                                ValueView(
                                    value: item,
                                    searchQuery: searchQuery,
                                    isCaseSensitive: isCaseSensitive,
                                    isWholeWord: isWholeWord,
                                    isRegex: isRegex,
                                    currentKeyPath: "\(currentKeyPath)[\(index)]"
                                )
                            }
                            .padding(.leading, 16)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        case .unknown:
            Text("unknown")
                .foregroundColor(.gray)
        }
    }
    
    private func typeBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(4)
    }
}
