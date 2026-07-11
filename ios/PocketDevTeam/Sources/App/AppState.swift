import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var currentWorkspace: Workspace?
    @Published var isConnected = false
    @Published var agents: [Agent] = []
    @Published var selectedAgentId: String?
    
    private let agentService = AgentService()
    
    var selectedAgent: Agent? {
        agents.first { $0.id == selectedAgentId }
    }
    
    func connect(to workspace: Workspace) async throws {
        currentWorkspace = workspace
        agentService.configure(baseURL: workspace.url, token: workspace.token)
        
        agents = try await agentService.fetchAgents()
        isConnected = true
        
        if selectedAgentId == nil, let first = agents.first {
            selectedAgentId = first.id
        }
    }
    
    func disconnect() {
        currentWorkspace = nil
        isConnected = false
        agents = []
        selectedAgentId = nil
    }
    
    func sendMessage(_ text: String, to agentId: String) -> AsyncThrowingStream<AgentEvent, Error> {
        agentService.sendMessage(text, to: agentId)
    }
    
    func fetchHistory(for agentId: String) async throws -> [Message] {
        try await agentService.fetchHistory(for: agentId)
    }
    
    func clearSession(for agentId: String) async throws {
        try await agentService.clearSession(for: agentId)
    }
}
