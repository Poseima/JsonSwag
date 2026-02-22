import SwiftUI

@Observable
class TabManager {
    var tabs: [TabItem] = []
    var selectedTabId: UUID?
    
    func addTab(_ item: TabItem) {
        tabs.append(item)
        selectedTabId = item.id
    }
    
    func closeTab(_ id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)
        
        // If closing selected tab, select another
        if selectedTabId == id {
            if tabs.isEmpty {
                // Add a new empty tab
                let newTab = TabItem.newTab()
                tabs.append(newTab)
                selectedTabId = newTab.id
            } else {
                // Select the tab at same index or previous
                let newIndex = min(index, tabs.count - 1)
                selectedTabId = tabs[newIndex].id
            }
        }
    }
    
    func selectTab(_ id: UUID) {
        selectedTabId = id
    }
    
    func updateTab(_ id: UUID, with item: TabItem) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index] = item
    }
}

struct TabItem: Identifiable {
    let id: UUID
    var fileURL: URL?
    var fileName: String
    var recordLoader: LazyRecordLoader?
    var searchManager = SearchManager()
    var error: String?
    
    var records: [JSONRecord] {
        recordLoader?.allRecords ?? []
    }
    
    var isLoading: Bool {
        recordLoader?.isLoading ?? false
    }
    
    var isFullyLoaded: Bool {
        recordLoader?.isFullyLoaded ?? true
    }
    
    static func newTab() -> TabItem {
        TabItem(
            id: UUID(),
            fileURL: nil,
            fileName: "New Tab",
            recordLoader: nil,
            error: nil
        )
    }
    
    static func fromFile(_ url: URL, preservingId id: UUID? = nil) -> TabItem {
        let loader = LazyRecordLoader(url: url)
        return TabItem(
            id: id ?? UUID(),
            fileURL: url,
            fileName: url.lastPathComponent,
            recordLoader: loader,
            error: loader.error
        )
    }
}
