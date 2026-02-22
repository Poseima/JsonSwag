import SwiftUI

@Observable
class ExpandState {
    var expandedPaths: Set<String> = []
    var globalState: ExpandAllState = .none
    
    func isExpanded(_ path: String) -> Bool {
        if globalState == .expandAll { return true }
        if globalState == .collapseAll { return false }
        return expandedPaths.contains(path)
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
