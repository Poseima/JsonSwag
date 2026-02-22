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
    var fileType: FileType
    var recordLoader: LazyRecordLoader?
    var arrayLoader: LazyJSONArrayLoader?
    var jsonRootValue: Any?
    var searchManager = SearchManager()
    var error: String?
    
    var records: [JSONRecord] {
        recordLoader?.allRecords ?? []
    }
    
    var isLoading: Bool {
        if fileType == .jsonl {
            return recordLoader?.isLoading ?? false
        } else {
            return arrayLoader?.isLoading ?? false
        }
    }
    
    var isFullyLoaded: Bool {
        if fileType == .jsonl {
            return recordLoader?.isFullyLoaded ?? true
        } else {
            return arrayLoader?.isFullyLoaded ?? true
        }
    }
    
    static func newTab() -> TabItem {
        TabItem(
            id: UUID(),
            fileURL: nil,
            fileName: "New Tab",
            fileType: .jsonl,
            recordLoader: nil,
            arrayLoader: nil,
            jsonRootValue: nil,
            error: nil
        )
    }
    
    @MainActor
    static func fromFile(_ url: URL, preservingId id: UUID? = nil) -> TabItem {
        let fileType = FileType.detect(from: url)
        
        if fileType == .jsonl {
            // JSONL file - use existing loader
            let loader = LazyRecordLoader(url: url)
            return TabItem(
                id: id ?? UUID(),
                fileURL: url,
                fileName: url.lastPathComponent,
                fileType: fileType,
                recordLoader: loader,
                arrayLoader: nil,
                jsonRootValue: nil,
                error: loader.error
            )
        } else {
            // JSON file - parse and create appropriate loader
            do {
                let (type, data) = try JSONFileParser.parse(url)
                
                if type == .jsonArray, let array = data as? [Any] {
                    // Array with potential lazy loading
                    let loader = LazyJSONArrayLoader(array: array)
                    return TabItem(
                        id: id ?? UUID(),
                        fileURL: url,
                        fileName: url.lastPathComponent,
                        fileType: type,
                        recordLoader: nil,
                        arrayLoader: loader,
                        jsonRootValue: array,
                        error: nil
                    )
                } else {
                    // Object or other JSON
                    return TabItem(
                        id: id ?? UUID(),
                        fileURL: url,
                        fileName: url.lastPathComponent,
                        fileType: type,
                        recordLoader: nil,
                        arrayLoader: nil,
                        jsonRootValue: data,
                        error: nil
                    )
                }
            } catch {
                return TabItem(
                    id: id ?? UUID(),
                    fileURL: url,
                    fileName: url.lastPathComponent,
                    fileType: fileType,
                    recordLoader: nil,
                    arrayLoader: nil,
                    jsonRootValue: nil,
                    error: error.localizedDescription
                )
            }
        }
    }
}
