import SwiftUI

struct TabBarView: View {
    @Bindable var tabManager: TabManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabManager.tabs) { tab in
                    TabItemView(
                        tab: tab,
                        isSelected: tab.id == tabManager.selectedTabId,
                        onSelect: { tabManager.selectTab(tab.id) },
                        onClose: { tabManager.closeTab(tab.id) }
                    )
                }
                
                // "+" button
                Button(action: { tabManager.addTab(.newTab()) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("New tab")
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 38)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct TabItemView: View {
    let tab: TabItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            // File icon
            if tab.fileURL != nil {
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "plus.circle")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // File name
            Text(tab.fileName)
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
            
            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isHovered ? .secondary : .clear)
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isSelected ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(isSelected ? Color(nsColor: .windowBackgroundColor) : Color.clear)
        )
        .overlay(
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: isSelected ? 2 : 0),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in isHovered = hovering }
    }
}
