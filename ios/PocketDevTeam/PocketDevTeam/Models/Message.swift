import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool
    var toolActivity: String?
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false, toolActivity: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.toolActivity = toolActivity
    }
}

struct HistoryMessage: Codable {
    let role: String
    let content: String
    let timestamp: String
}

struct HistoryResponse: Codable {
    let agentId: String
    let messages: [HistoryMessage]
}
