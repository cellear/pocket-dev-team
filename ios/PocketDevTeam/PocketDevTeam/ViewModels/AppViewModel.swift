import Foundation
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var agents: [Agent] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isConnected: Bool = false
    
    private var connectionCheckTask: Task<Void, Never>?
    
    init() {
        startConnectionMonitoring()
    }
    
    deinit {
        connectionCheckTask?.cancel()
    }
    
    func loadAgents() async {
        isLoading = true
        error = nil
        
        do {
            agents = try await AgentService.shared.fetchAgents()
            isConnected = true
        } catch {
            self.error = error.localizedDescription
            isConnected = false
        }
        
        isLoading = false
    }
    
    func checkConnection() async {
        isConnected = await AgentService.shared.checkConnection()
    }
    
    private func startConnectionMonitoring() {
        connectionCheckTask = Task {
            while !Task.isCancelled {
                await checkConnection()
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }
    
    func connect() async {
        await loadAgents()
    }
    
    func disconnect() {
        agents = []
        isConnected = false
    }
}
