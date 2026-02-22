import SwiftUI

enum ExpandAllState: Equatable {
    case none
    case expandAll
    case collapseAll
}

private struct ExpandAllKey: EnvironmentKey {
    static let defaultValue: ExpandAllState = .none
}

extension EnvironmentValues {
    var expandAllState: ExpandAllState {
        get { self[ExpandAllKey.self] }
        set { self[ExpandAllKey.self] = newValue }
    }
}
