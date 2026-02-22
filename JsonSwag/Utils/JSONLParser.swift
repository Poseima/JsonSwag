import Foundation

enum JSONLParseError: Error, LocalizedError {
    case emptyFile
    case invalidUTF8
    case parseError(lineNumber: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty"
        case .invalidUTF8:
            return "The file contains invalid UTF-8 data"
        case .parseError(let line, let message):
            return "Line \(line): \(message)"
        }
    }
}

struct ParsedRecord {
    let lineNumber: Int
    let data: [String: Any]?
    let error: String?
}

struct JSONLParser {
    static func parse(_ url: URL) throws -> [ParsedRecord] {
        guard let data = try? Data(contentsOf: url) else {
            throw JSONLParseError.invalidUTF8
        }
        return try parseFromData(data)
    }
    
    static func parseFromData(_ data: Data) throws -> [ParsedRecord] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw JSONLParseError.invalidUTF8
        }
        
        let lines = content.components(separatedBy: .newlines)
        var records: [ParsedRecord] = []
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            
            guard let lineData = line.data(using: .utf8) else {
                records.append(ParsedRecord(lineNumber: lineNumber, data: nil, error: "Invalid UTF-8"))
                continue
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: lineData)
                if let dict = json as? [String: Any] {
                    records.append(ParsedRecord(lineNumber: lineNumber, data: dict, error: nil))
                } else if let array = json as? [Any] {
                    records.append(ParsedRecord(lineNumber: lineNumber, data: ["_array": array], error: nil))
                } else {
                    records.append(ParsedRecord(lineNumber: lineNumber, data: ["_value": json], error: nil))
                }
            } catch {
                records.append(ParsedRecord(lineNumber: lineNumber, data: nil, error: error.localizedDescription))
            }
        }
        
        if records.isEmpty {
            throw JSONLParseError.emptyFile
        }
        
        return records
    }
}
