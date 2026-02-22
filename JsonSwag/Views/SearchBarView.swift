import SwiftUI

struct SearchBarView: View {
    @Bindable var searchManager: SearchManager
    @FocusState.Binding var isFocused: Bool
    let onClose: () -> Void
    let onNextMatch: () -> Void
    let onPrevMatch: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            // Search field
            TextField("Search (keys, values, line#)", text: $searchManager.query)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    if NSEvent.modifierFlags.contains(.shift) {
                        onPrevMatch()
                    } else {
                        onNextMatch()
                    }
                }
                .onChange(of: searchManager.query) { _, _ in
                    // Parent will handle search
                }
            
            // Toggle buttons
            HStack(spacing: 2) {
                ToggleButton(
                    icon: "a.square",
                    isActive: searchManager.isCaseSensitive,
                    tooltip: "Match Case"
                ) {
                    searchManager.isCaseSensitive.toggle()
                }
                
                ToggleButton(
                    icon: "textformat.alt",
                    isActive: searchManager.isWholeWord,
                    tooltip: "Match Whole Word"
                ) {
                    searchManager.isWholeWord.toggle()
                }
                
                ToggleButton(
                    icon: "chevron.left.slash.chevron.right",
                    isActive: searchManager.isRegex,
                    tooltip: "Use Regular Expression"
                ) {
                    searchManager.isRegex.toggle()
                }
            }
            
            Divider()
                .frame(height: 16)
            
            // Match counter
            Text("\(searchManager.currentMatchNumber)/\(searchManager.matchCount)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(minWidth: 40, alignment: .trailing)
            
            // Navigation buttons
            HStack(spacing: 2) {
                Button(action: onPrevMatch) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .medium))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Previous Match (Shift+Enter)")
                
                Button(action: onNextMatch) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Next Match (Enter)")
            }
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close (Escape)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

struct ToggleButton: View {
    let icon: String
    let isActive: Bool
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .accentColor : .secondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isActive ? Color.accentColor.opacity(0.15) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in isHovered = hovering }
    }
}
