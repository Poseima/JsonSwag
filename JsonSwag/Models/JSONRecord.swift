import Foundation

struct JSONRecord: Identifiable, Equatable {
    let id: Int
    let lineNumber: Int
    let data: [String: Any]?
    let sortedKeys: [String]
    let error: String?
    
    static func == (lhs: JSONRecord, rhs: JSONRecord) -> Bool {
        lhs.id == rhs.id &&
        lhs.lineNumber == rhs.lineNumber &&
        lhs.sortedKeys == rhs.sortedKeys &&
        lhs.error == rhs.error
    }
    
    init(id: Int, lineNumber: Int, data: [String: Any]?, error: String?) {
        self.id = id
        self.lineNumber = lineNumber
        self.data = data
        self.sortedKeys = data?.keys.sorted() ?? []
        self.error = error
    }
    
    init(from parsed: ParsedRecord) {
        self.id = parsed.lineNumber
        self.lineNumber = parsed.lineNumber
        self.data = parsed.data
        self.sortedKeys = parsed.data?.keys.sorted() ?? []
        self.error = parsed.error
    }
}
