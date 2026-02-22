import SwiftUI

@Observable
class ExpandState {
    var expandedPaths: Set<String> = []
    var globalState: ExpandAllState = .none
    var maxExpandDepth: Int = 4  // Limit depth to prevent crashes
    
    func isExpanded(_ path: String) -> Bool {
        if globalState == .collapseAll { return false }
        if globalState == .expandAll {
            let depth = pathDepth(path)
            return depth < maxExpandDepth
        }
        return expandedPaths.contains(path)
    }
    
    private func pathDepth(_ path: String) -> Int {
        // Empty or root path is depth 0
        if path.isEmpty { return 0 }
        // Count dots and brackets to determine depth
        return path.filter { $0 == "." || $0 == "[" }.count
    }
    
    func toggle(_ path: String) {
        // Reset global state when manually toggling
        if globalState != .none {
            globalState = .none
        }
        
        if expandedPaths.contains(path) {
            expandedPaths.remove(path)
        } else {
            expandedPaths.insert(path)
        }
    }
    
    func setGlobalState(_ state: ExpandAllState) {
        globalState = state
        if state == .collapseAll {
            expandedPaths.removeAll()
        }
    }
    
    func reset() {
        globalState = .none
        expandedPaths.removeAll()
    }
}

private struct ExpandStateKey: EnvironmentKey {
    static let defaultValue = ExpandState()
}

extension EnvironmentValues {
    var expandState: ExpandState {
        get { self[ExpandStateKey.self] }
        set { self[ExpandStateKey.self] = newValue }
    }
}
