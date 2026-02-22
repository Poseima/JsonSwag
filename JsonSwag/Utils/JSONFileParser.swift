import Foundation

enum JSONFileParseError: Error, LocalizedError {
    case emptyFile
    case invalidUTF8
    case parseError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty"
        case .invalidUTF8:
            return "The file contains invalid UTF-8 data"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}

struct JSONFileParser {
    static func parse(_ url: URL) throws -> (type: FileType, data: Any) {
        guard let data = try? Data(contentsOf: url) else {
            throw JSONFileParseError.invalidUTF8
        }
        
        if data.isEmpty {
            throw JSONFileParseError.emptyFile
        }
        
        let json = try JSONSerialization.jsonObject(with: data)
        let type = FileType.detect(from: url)
        
        return (type, json)
    }
}
