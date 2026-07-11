import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let text: String
    let toolUses: [ToolUse]?
    let timestamp: Date
    
    init(id: String = UUID().uuidString, role: MessageRole, text: String, toolUses: [ToolUse]? = nil, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.toolUses = toolUses
        self.timestamp = timestamp
    }
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        case tool
        case error
    }
}

struct ToolUse: Codable {
    let tool: String
    let args: [String: AnyCodable]?
    
    var displayName: String {
        switch tool {
        case "read_file", "Read": return "Reading"
        case "write_file", "Write": return "Writing"
        case "edit_file", "StrReplace": return "Editing"
        case "list_files", "Glob": return "Listing"
        case "search", "Grep": return "Searching"
        case "bash", "Shell": return "Running"
        default: return tool
        }
    }
    
    var displayPath: String? {
        if let path = args?["path"]?.value as? String {
            return URL(fileURLWithPath: path).lastPathComponent
        }
        return nil
    }
}

// Helper for encoding/decoding arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String: try container.encode(string)
        case let int as Int: try container.encode(int)
        case let double as Double: try container.encode(double)
        case let bool as Bool: try container.encode(bool)
        default: try container.encodeNil()
        }
    }
}
