import Foundation

class AgentService {
    private var baseURL: URL?
    private var token: String?
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    func configure(baseURL: URL, token: String?) {
        self.baseURL = baseURL
        self.token = token
    }
    
    // MARK: - API Methods
    
    func fetchAgents() async throws -> [Agent] {
        let data = try await request(path: "/api/agents")
        return try decoder.decode([Agent].self, from: data)
    }
    
    func fetchHistory(for agentId: String) async throws -> [Message] {
        let data = try await request(path: "/api/agents/\(agentId)/history")
        return try decoder.decode([Message].self, from: data)
    }
    
    func clearSession(for agentId: String) async throws {
        _ = try await request(path: "/api/agents/\(agentId)/clear", method: "POST")
    }
    
    func sendMessage(_ text: String, to agentId: String) -> AsyncThrowingStream<AgentEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await streamMessage(text, to: agentId, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func request(path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let baseURL else {
            throw AgentServiceError.notConfigured
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentServiceError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            if httpResponse.statusCode == 401 {
                throw AgentServiceError.unauthorized
            }
            throw AgentServiceError.httpError(httpResponse.statusCode)
        }
        
        return data
    }
    
    private func streamMessage(_ text: String, to agentId: String, continuation: AsyncThrowingStream<AgentEvent, Error>.Continuation) async throws {
        guard let baseURL else {
            throw AgentServiceError.notConfigured
        }
        
        var request = URLRequest(url: baseURL.appendingPathComponent("/api/agents/\(agentId)/message"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = try JSONEncoder().encode(["text": text])
        request.httpBody = body
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentServiceError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw AgentServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse SSE stream
        var buffer = ""
        
        for try await byte in bytes {
            let char = String(UnicodeScalar(byte))
            buffer += char
            
            // Look for complete SSE events (double newline)
            while let range = buffer.range(of: "\n\n") {
                let eventStr = String(buffer[..<range.lowerBound])
                buffer = String(buffer[range.upperBound...])
                
                // Parse "data: {...}" lines
                for line in eventStr.split(separator: "\n") {
                    let lineStr = String(line)
                    if lineStr.hasPrefix("data: ") {
                        let jsonStr = String(lineStr.dropFirst(6))
                        if let data = jsonStr.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let event = AgentEvent.from(json: json) {
                            continuation.yield(event)
                            
                            if case .done = event {
                                continuation.finish()
                                return
                            }
                        }
                    }
                }
            }
        }
        
        continuation.finish()
    }
}

enum AgentServiceError: LocalizedError {
    case notConfigured
    case invalidResponse
    case unauthorized
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service not configured. Please connect to a workspace."
        case .invalidResponse:
            return "Invalid response from server."
        case .unauthorized:
            return "Unauthorized. Check your API token."
        case .httpError(let code):
            return "Server error: \(code)"
        }
    }
}
