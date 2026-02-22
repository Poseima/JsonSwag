import SwiftUI

struct KeyValueRowView: View {
    let key: String
    let value: Any?
    var searchQuery: String = ""
    var isCaseSensitive: Bool = false
    var isWholeWord: Bool = false
    var isRegex: Bool = false
    var isKeyHighlighted: Bool = false
    var keyPath: String = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if searchQuery.isEmpty {
                Text(key)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } else {
                HighlightedTextView(
                    text: key,
                    searchQuery: searchQuery,
                    isCaseSensitive: isCaseSensitive,
                    isWholeWord: isWholeWord,
                    isRegex: isRegex,
                    isHighlighted: isKeyHighlighted
                )
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            }
            
            Text(":")
                .foregroundColor(.secondary)
            
            ValueView(
                value: value,
                searchQuery: searchQuery,
                isCaseSensitive: isCaseSensitive,
                isWholeWord: isWholeWord,
                isRegex: isRegex,
                currentKeyPath: keyPath
            )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
