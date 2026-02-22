import SwiftUI

@main
struct JsonSwagApp: App {
    @State private var tabManager = TabManager()
    @State private var isSearchVisible = false
    
    var body: some Scene {
        WindowGroup {
            MainView(tabManager: tabManager, isSearchVisible: $isSearchVisible)
                .frame(minWidth: 700, minHeight: 500)
                .onOpenURL { url in
                    tabManager.addTab(.fromFile(url))
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    tabManager.addTab(.newTab())
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            
            CommandGroup(after: .importExport) {
                Button("Close Tab") {
                    if let selectedId = tabManager.selectedTabId {
                        tabManager.closeTab(selectedId)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            CommandGroup(after: .toolbar) {
                Button("Find...") {
                    isSearchVisible = true
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Find Next") {
                    if let selectedId = tabManager.selectedTabId,
                       let selectedIndex = tabManager.tabs.firstIndex(where: { $0.id == selectedId }) {
                        tabManager.tabs[selectedIndex].searchManager.nextMatch()
                    }
                }
                .keyboardShortcut("g", modifiers: .command)
                
                Button("Find Previous") {
                    if let selectedId = tabManager.selectedTabId,
                       let selectedIndex = tabManager.tabs.firstIndex(where: { $0.id == selectedId }) {
                        tabManager.tabs[selectedIndex].searchManager.prevMatch()
                    }
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
        }
    }
}
