import Foundation

enum SearchField {
    case key
    case value
    case lineNumber
}

struct SearchMatch: Identifiable {
    let id = UUID()
    let recordIndex: Int
    let field: SearchField
    let keyPath: String?
    let matchedText: String
    let context: String
}

@Observable
class SearchManager {
    var query: String = ""
    var isCaseSensitive: Bool = false
    var isWholeWord: Bool = false
    var isRegex: Bool = false
    
    private(set) var matches: [SearchMatch] = []
    private(set) var currentMatchIndex: Int = -1
    
    var currentMatch: SearchMatch? {
        guard currentMatchIndex >= 0, currentMatchIndex < matches.count else { return nil }
        return matches[currentMatchIndex]
    }
    
    var matchCount: Int {
        matches.count
    }
    
    var currentMatchNumber: Int {
        matches.isEmpty ? 0 : currentMatchIndex + 1
    }
    
    func search(in records: [JSONRecord]) {
        matches = []
        currentMatchIndex = -1
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return }
        
        for (recordIndex, record) in records.enumerated() {
            // Search line number
            let lineNumberStr = "\(record.lineNumber)"
            if matchesQuery(lineNumberStr) {
                matches.append(SearchMatch(
                    recordIndex: recordIndex,
                    field: .lineNumber,
                    keyPath: nil,
                    matchedText: lineNumberStr,
                    context: "Line \(record.lineNumber)"
                ))
            }
            
            // Search keys and values
            if let data = record.data {
                searchInDict(data, recordIndex: recordIndex, prefix: "")
            }
        }
        
        if !matches.isEmpty {
            currentMatchIndex = 0
        }
    }
    
    private func searchInDict(_ dict: [String: Any], recordIndex: Int, prefix: String) {
        for (key, value) in dict {
            let fullKeyPath = prefix.isEmpty ? key : "\(prefix).\(key)"
            
            // Search key
            if matchesQuery(key) {
                matches.append(SearchMatch(
                    recordIndex: recordIndex,
                    field: .key,
                    keyPath: fullKeyPath,
                    matchedText: key,
                    context: fullKeyPath
                ))
            }
            
            // Search value
            searchValue(value, recordIndex: recordIndex, keyPath: fullKeyPath)
        }
    }
    
    private func searchValue(_ value: Any, recordIndex: Int, keyPath: String) {
        switch value {
        case let s as String:
            if matchesQuery(s) {
                let context = s.count > 50 ? String(s.prefix(50)) + "..." : s
                matches.append(SearchMatch(
                    recordIndex: recordIndex,
                    field: .value,
                    keyPath: keyPath,
                    matchedText: s,
                    context: "\(keyPath): \(context)"
                ))
            }
        case let n as Double:
            let numStr = n.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(n))" : String(format: "%.4g", n)
            if matchesQuery(numStr) {
                matches.append(SearchMatch(
                    recordIndex: recordIndex,
                    field: .value,
                    keyPath: keyPath,
                    matchedText: numStr,
                    context: "\(keyPath): \(numStr)"
                ))
            }
        case let n as Int:
            let numStr = "\(n)"
            if matchesQuery(numStr) {
                matches.append(SearchMatch(
                    recordIndex: recordIndex,
                    field: .value,
                    keyPath: keyPath,
                    matchedText: numStr,
                    context: "\(keyPath): \(numStr)"
                ))
            }
        case let b as Bool:
            let boolStr = b ? "true" : "false"
            if matchesQuery(boolStr) {
                matches.append(SearchMatch(
                    recordIndex: recordIndex,
                    field: .value,
                    keyPath: keyPath,
                    matchedText: boolStr,
                    context: "\(keyPath): \(boolStr)"
                ))
            }
        case let obj as [String: Any]:
            searchInDict(obj, recordIndex: recordIndex, prefix: keyPath)
        case let arr as [Any]:
            for (index, item) in arr.enumerated() {
                searchValue(item, recordIndex: recordIndex, keyPath: "\(keyPath)[\(index)]")
            }
        default:
            break
        }
    }
    
    private func matchesQuery(_ text: String) -> Bool {
        let searchText = isCaseSensitive ? text : text.lowercased()
        let searchQuery = isCaseSensitive ? query : query.lowercased()
        
        if isRegex {
            guard let regex = try? NSRegularExpression(pattern: query, options: isCaseSensitive ? [] : [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, range: range) != nil
        }
        
        if isWholeWord {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: searchQuery))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: isCaseSensitive ? [] : [.caseInsensitive]) else {
                return false
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.firstMatch(in: text, range: range) != nil
        }
        
        return searchText.contains(searchQuery)
    }
    
    func nextMatch() {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matches.count
    }
    
    func prevMatch() {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matches.count) % matches.count
    }
    
    func clear() {
        query = ""
        matches = []
        currentMatchIndex = -1
    }
}
