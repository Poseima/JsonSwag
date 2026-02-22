import Foundation

enum FileType {
    case jsonl       // JSONL - multiple objects, one per line
    case jsonObject  // JSON - single object
    case jsonArray   // JSON - array (may need lazy loading)
    
    static func detect(from url: URL) -> FileType {
        let pathExtension = url.pathExtension.lowercased()
        
        // Explicit .jsonl extension
        if pathExtension == "jsonl" {
            return .jsonl
        }
        
        // For .json files, check content structure
        if pathExtension == "json" {
            return detectJsonType(from: url)
        }
        
        // Default to JSONL for unknown extensions
        return .jsonl
    }
    
    private static func detectJsonType(from url: URL) -> FileType {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return .jsonObject
        }
        
        // Find first non-whitespace character
        for char in content {
            if char == "{" {
                return .jsonObject
            } else if char == "[" {
                return .jsonArray
            } else if !char.isWhitespace {
                break
            }
        }
        
        return .jsonObject
    }
    
    var displayName: String {
        switch self {
        case .jsonl:
            return "JSONL"
        case .jsonObject:
            return "JSON"
        case .jsonArray:
            return "JSON Array"
        }
    }
}
