import Foundation

@Observable
class LazyRecordLoader {
    let fileURL: URL
    private(set) var allRecords: [JSONRecord] = []
    private(set) var isLoading = false
    private(set) var isFullyLoaded = false
    private(set) var totalLineCount: Int = 0
    private(set) var error: String?
    
    private var lines: [String] = []
    private var currentLineIndex = 0
    private let batchSize = 50
    
    init(url: URL) {
        self.fileURL = url
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            self.lines = content.components(separatedBy: .newlines)
            self.totalLineCount = self.lines.count
            loadNextBatch()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func loadNextBatch() {
        guard !isFullyLoaded, !isLoading else { return }
        isLoading = true
        
        let linesToProcess = lines
        let startIndex = currentLineIndex
        let batch = batchSize
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            var newRecords: [JSONRecord] = []
            var processedCount = 0
            var localIndex = startIndex
            
            while processedCount < batch && localIndex < linesToProcess.count {
                let lineIndex = localIndex
                let line = linesToProcess[lineIndex]
                localIndex += 1
                
                guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
                
                if let record = self.parseLine(line, lineNumber: lineIndex + 1) {
                    newRecords.append(record)
                }
                processedCount += 1
            }
            
            await MainActor.run {
                self.currentLineIndex = localIndex
                self.allRecords.append(contentsOf: newRecords)
                self.isFullyLoaded = localIndex >= linesToProcess.count
                self.isLoading = false
            }
        }
    }
    
    func loadAllIfNeeded() {
        guard !isFullyLoaded else { return }
        
        let linesToProcess = lines
        let startIndex = currentLineIndex
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            var allRemainingRecords: [JSONRecord] = []
            var localIndex = startIndex
            
            while localIndex < linesToProcess.count {
                let lineIndex = localIndex
                let line = linesToProcess[localIndex]
                localIndex += 1
                
                guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
                
                if let record = self.parseLine(line, lineNumber: lineIndex + 1) {
                    allRemainingRecords.append(record)
                }
            }
            
            await MainActor.run {
                self.currentLineIndex = localIndex
                self.allRecords.append(contentsOf: allRemainingRecords)
                self.isFullyLoaded = true
                self.isLoading = false
            }
        }
    }
    
    private func parseLine(_ line: String, lineNumber: Int) -> JSONRecord? {
        guard let lineData = line.data(using: .utf8) else {
            return JSONRecord(id: lineNumber, lineNumber: lineNumber, data: nil, error: "Invalid UTF-8")
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: lineData)
            if let dict = json as? [String: Any] {
                return JSONRecord(id: lineNumber, lineNumber: lineNumber, data: dict, error: nil)
            } else if let array = json as? [Any] {
                return JSONRecord(id: lineNumber, lineNumber: lineNumber, data: ["_array": array], error: nil)
            } else {
                return JSONRecord(id: lineNumber, lineNumber: lineNumber, data: ["_value": json], error: nil)
            }
        } catch {
            return JSONRecord(id: lineNumber, lineNumber: lineNumber, data: nil, error: error.localizedDescription)
        }
    }
}
