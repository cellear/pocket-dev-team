import Foundation
import SwiftUI

@MainActor
class AgentViewModel: ObservableObject {
    let agent: Agent
    
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var currentToolActivity: String?
    @Published var error: String?
    @Published var inputText: String = ""
    
    private let sseService = SSEService()
    private var currentStreamingMessageId: UUID?
    
    init(agent: Agent) {
        self.agent = agent
    }
    
    func loadHistory() async {
        do {
            messages = try await AgentService.shared.fetchHistory(for: agent.id)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        inputText = ""
        
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        
        let assistantMessageId = UUID()
        let assistantMessage = Message(id: assistantMessageId, role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        currentStreamingMessageId = assistantMessageId
        
        isLoading = true
        error = nil
        
        sseService.sendMessage(
            to: agent.id,
            message: text,
            onEvent: { [weak self] event in
                self?.handleSSEEvent(event)
            },
            onComplete: { [weak self] in
                self?.finishStreaming()
            },
            onError: { [weak self] error in
                self?.handleError(error)
            }
        )
    }
    
    private func handleSSEEvent(_ event: SSEEvent) {
        switch event.type {
        case .text:
            if let text = event.text, let id = currentStreamingMessageId {
                updateStreamingMessage(id: id) { message in
                    message.content += text
                }
            }
            
        case .toolStart:
            currentToolActivity = event.display ?? "Working..."
            if let id = currentStreamingMessageId {
                updateStreamingMessage(id: id) { message in
                    message.toolActivity = event.display
                }
            }
            
        case .toolEnd:
            currentToolActivity = nil
            if let id = currentStreamingMessageId {
                updateStreamingMessage(id: id) { message in
                    message.toolActivity = nil
                }
            }
            
        case .done:
            finishStreaming()
            
        case .error:
            error = event.error ?? "Unknown error"
            finishStreaming()
        }
    }
    
    private func updateStreamingMessage(id: UUID, update: (inout Message) -> Void) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            update(&messages[index])
        }
    }
    
    private func finishStreaming() {
        isLoading = false
        currentToolActivity = nil
        
        if let id = currentStreamingMessageId {
            updateStreamingMessage(id: id) { message in
                message.isStreaming = false
                message.toolActivity = nil
            }
        }
        currentStreamingMessageId = nil
    }
    
    private func handleError(_ error: Error) {
        self.error = error.localizedDescription
        finishStreaming()
    }
    
    func clearSession() async {
        do {
            try await AgentService.shared.clearSession(for: agent.id)
            messages = []
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func cancelStreaming() {
        sseService.cancel()
        finishStreaming()
    }
}
