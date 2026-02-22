import SwiftUI

struct MainView: View {
    @Bindable var tabManager: TabManager
    @Binding var isSearchVisible: Bool
    @FocusState private var isSearchFocused: Bool
    @State private var scrollToRecordId: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(tabManager: tabManager)
            Divider()
            
            if let selectedId = tabManager.selectedTabId,
               let selectedIndex = tabManager.tabs.firstIndex(where: { $0.id == selectedId }) {
                let tab = tabManager.tabs[selectedIndex]
                
                // Search bar
                if isSearchVisible {
                    VStack(spacing: 0) {
                        SearchBarView(
                            searchManager: tab.searchManager,
                            isFocused: $isSearchFocused,
                            onClose: {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    isSearchVisible = false
                                    tab.searchManager.clear()
                                }
                            },
                            onNextMatch: {
                                tab.searchManager.nextMatch()
                                scrollToCurrentMatch(tab: tab)
                            },
                            onPrevMatch: {
                                tab.searchManager.prevMatch()
                                scrollToCurrentMatch(tab: tab)
                            }
                        )
                        .padding(8)
                        Divider()
                    }
                    .onAppear {
                        tab.searchManager.search(in: tab.records)
                    }
                    .onChange(of: tab.searchManager.query) { _, _ in
                        // Load all records for search
                        if tab.fileType == .jsonl {
                            if let loader = tab.recordLoader {
                                loader.loadAllIfNeeded()
                                // Re-search after loading
                                Task {
                                    try? await Task.sleep(nanoseconds: 100_000_000)
                                    tab.searchManager.search(in: loader.allRecords)
                                }
                            }
                        } else if let loader = tab.arrayLoader {
                            loader.loadAllIfNeeded()
                        }
                    }
                }
                
                ContentView(
                    records: tab.records,
                    error: tab.error,
                    hasFile: tab.fileURL != nil,
                    isLoading: tab.isLoading,
                    hasMoreRecords: !tab.isFullyLoaded,
                    searchManager: tab.searchManager,
                    fileType: tab.fileType,
                    jsonRootValue: tab.jsonRootValue,
                    arrayLoader: tab.arrayLoader,
                    scrollToRecordId: $scrollToRecordId,
                    onLoadMore: {
                        if tab.fileType == .jsonl {
                            tab.recordLoader?.loadNextBatch()
                        } else {
                            tab.arrayLoader?.loadNextBatch()
                        }
                    },
                    onFileOpened: { url in
                        let newItem = TabItem.fromFile(url, preservingId: selectedId)
                        tabManager.updateTab(selectedId, with: newItem)
                    }
                )
            }
        }
        .onAppear {
            if tabManager.tabs.isEmpty {
                tabManager.addTab(.newTab())
            }
        }
    }
    
    private func scrollToCurrentMatch(tab: TabItem) {
        if let match = tab.searchManager.currentMatch {
            scrollToRecordId = tab.records[match.recordIndex].lineNumber
        }
    }
}
