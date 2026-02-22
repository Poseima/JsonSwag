import Foundation

@Observable
class LazyJSONArrayLoader {
    let fullArray: [Any]
    private(set) var visibleItems: [Any] = []
    private let batchSize: Int
    private var loadedCount: Int = 0
    
    var isLoading: Bool = false
    var isFullyLoaded: Bool = false
    
    let totalCount: Int
    let needsLazyLoading: Bool
    
    @MainActor
    init(array: [Any], threshold: Int = 100, batchSize: Int = 50) {
        self.fullArray = array
        self.totalCount = array.count
        self.batchSize = batchSize
        self.needsLazyLoading = array.count > threshold
        
        if needsLazyLoading {
            // Load initial batch synchronously
            let endIndex = min(batchSize, totalCount)
            self.visibleItems = Array(fullArray[0..<endIndex])
            self.loadedCount = endIndex
            self.isFullyLoaded = loadedCount >= totalCount
        } else {
            // Load all immediately for small arrays
            visibleItems = array
            loadedCount = array.count
            isFullyLoaded = true
        }
    }
    
    @MainActor
    func loadNextBatch() {
        guard !isFullyLoaded && !isLoading else { return }
        
        isLoading = true
        
        let endIndex = min(loadedCount + batchSize, totalCount)
        let newItems = Array(fullArray[loadedCount..<endIndex])
        
        visibleItems.append(contentsOf: newItems)
        loadedCount = endIndex
        isFullyLoaded = loadedCount >= totalCount
        isLoading = false
    }
    
    @MainActor
    func loadAllIfNeeded() {
        if !isFullyLoaded {
            visibleItems = fullArray
            loadedCount = totalCount
            isFullyLoaded = true
        }
    }
}
