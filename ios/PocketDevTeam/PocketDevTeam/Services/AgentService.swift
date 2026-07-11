import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized - check your auth token"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

class AgentService {
    static let shared = AgentService()
    private let config = APIConfiguration.shared
    
    private init() {}
    
    func fetchAgents() async throws -> [Agent] {
        guard let url = config.baseURL?.appendingPathComponent("api/agents") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        config.authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        let agentsResponse = try JSONDecoder().decode(AgentsResponse.self, from: data)
        return agentsResponse.agents
    }
    
    func fetchHistory(for agentId: String) async throws -> [Message] {
        guard let url = config.baseURL?.appendingPathComponent("api/agents/\(agentId)/history") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        config.authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let historyResponse = try JSONDecoder().decode(HistoryResponse.self, from: data)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return historyResponse.messages.compactMap { msg in
            guard let role = MessageRole(rawValue: msg.role) else { return nil }
            let date = dateFormatter.date(from: msg.timestamp) ?? Date()
            return Message(role: role, content: msg.content, timestamp: date)
        }
    }
    
    func clearSession(for agentId: String) async throws {
        guard let url = config.baseURL?.appendingPathComponent("api/agents/\(agentId)/clear") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        config.authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }
    
    func checkConnection() async -> Bool {
        guard let url = config.baseURL?.appendingPathComponent("health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                let connected = httpResponse.statusCode == 200
                await MainActor.run {
                    self.config.isConnected = connected
                }
                return connected
            }
        } catch {
            await MainActor.run {
                self.config.isConnected = false
            }
        }
        
        return false
    }
}
