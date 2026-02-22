import SwiftUI

struct HighlightedTextView: View {
    let text: String
    let searchQuery: String
    let isCaseSensitive: Bool
    let isWholeWord: Bool
    let isRegex: Bool
    let isHighlighted: Bool
    
    @State private var cachedRanges: [Range<String.Index>]?
    @State private var cachedQuery: String = ""
    @State private var cachedCaseSensitive: Bool = false
    @State private var cachedWholeWord: Bool = false
    @State private var cachedRegex: Bool = false
    
    private var highlightRanges: [Range<String.Index>] {
        // Check cache
        if cachedQuery == searchQuery &&
           cachedCaseSensitive == isCaseSensitive &&
           cachedWholeWord == isWholeWord &&
           cachedRegex == isRegex,
           let cached = cachedRanges {
            return cached
        }
        
        // Compute new ranges
        let ranges = computeRanges()
        
        // Update cache on next run loop to avoid modifying state during view update
        Task { @MainActor in
            cachedRanges = ranges
            cachedQuery = searchQuery
            cachedCaseSensitive = isCaseSensitive
            cachedWholeWord = isWholeWord
            cachedRegex = isRegex
        }
        
        return ranges
    }
    
    private func computeRanges() -> [Range<String.Index>] {
        guard !searchQuery.isEmpty else { return [] }
        
        var ranges: [Range<String.Index>] = []
        
        if isRegex {
            guard let regex = try? NSRegularExpression(pattern: searchQuery, options: isCaseSensitive ? [] : [.caseInsensitive]) else {
                return []
            }
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: nsRange)
            for match in matches {
                if let range = Range(match.range, in: text) {
                    ranges.append(range)
                }
            }
        } else if isWholeWord {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: searchQuery))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: isCaseSensitive ? [] : [.caseInsensitive]) else {
                return []
            }
            let nsRange = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: nsRange)
            for match in matches {
                if let range = Range(match.range, in: text) {
                    ranges.append(range)
                }
            }
        } else {
            var searchStartIndex = text.startIndex
            let compareOptions: String.CompareOptions = isCaseSensitive ? [] : [.caseInsensitive]
            
            while searchStartIndex < text.endIndex,
                  let range = text.range(of: searchQuery, options: compareOptions, range: searchStartIndex..<text.endIndex) {
                ranges.append(range)
                searchStartIndex = range.upperBound
            }
        }
        
        return ranges
    }
    
    var body: some View {
        let ranges = highlightRanges
        if !ranges.isEmpty {
            Text(attributedString(ranges: ranges))
        } else {
            Text(text)
        }
    }
    
    private func attributedString(ranges: [Range<String.Index>]) -> AttributedString {
        var result = AttributedString(text)
        
        for range in ranges {
            if let lowerBound = AttributedString.Index(range.lowerBound, within: result),
               let upperBound = AttributedString.Index(range.upperBound, within: result) {
                let attrRange = lowerBound..<upperBound
                if isHighlighted {
                    result[attrRange].backgroundColor = .accentColor.opacity(0.4)
                    result[attrRange].foregroundColor = .primary
                } else {
                    result[attrRange].backgroundColor = .accentColor.opacity(0.2)
                }
            }
        }
        
        return result
    }
}
