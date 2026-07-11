import Foundation

enum AgentEvent {
    case text(String)
    case toolStart(tool: String, args: [String: Any]?)
    case toolEnd(tool: String)
    case status(String)
    case error(String)
    case done
    
    static func from(json: [String: Any]) -> AgentEvent? {
        guard let type = json["type"] as? String else { return nil }
        
        switch type {
        case "text":
            guard let text = json["text"] as? String else { return nil }
            return .text(text)
        case "tool_start":
            guard let tool = json["tool"] as? String else { return nil }
            let args = json["args"] as? [String: Any]
            return .toolStart(tool: tool, args: args)
        case "tool_end":
            guard let tool = json["tool"] as? String else { return nil }
            return .toolEnd(tool: tool)
        case "status":
            guard let status = json["status"] as? String else { return nil }
            return .status(status)
        case "error":
            let message = json["message"] as? String ?? "Unknown error"
            return .error(message)
        case "done":
            return .done
        default:
            return nil
        }
    }
}
