import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appState: AppState
    let agent: Agent
    
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var currentToolUse: String?
    @State private var streamingText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, accentColor: agent.accentColor)
                                    .id(message.id)
                            }
                            
                            // Streaming response
                            if !streamingText.isEmpty {
                                MessageBubble(
                                    message: Message(role: .assistant, text: streamingText),
                                    accentColor: agent.accentColor,
                                    isStreaming: true
                                )
                                .id("streaming")
                            }
                            
                            // Tool use indicator
                            if let tool = currentToolUse {
                                ToolIndicator(toolName: tool, accentColor: agent.accentColor)
                                    .id("tool")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: streamingText) { _, _ in
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Input bar
                InputBar(
                    text: $inputText,
                    isLoading: isLoading,
                    accentColor: agent.accentColor,
                    onSend: sendMessage
                )
            }
            .navigationTitle(agent.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(agent.name)
                            .font(.headline)
                        Text(agent.role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Task { await clearChat() }
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadHistory()
            }
        }
    }
    
    private func loadHistory() async {
        do {
            messages = try await appState.fetchHistory(for: agent.id)
        } catch {
            print("Failed to load history: \(error)")
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        inputText = ""
        isLoading = true
        streamingText = ""
        
        // Add user message immediately
        let userMessage = Message(role: .user, text: text)
        messages.append(userMessage)
        
        Task {
            do {
                for try await event in appState.sendMessage(text, to: agent.id) {
                    await MainActor.run {
                        handleEvent(event)
                    }
                }
            } catch {
                await MainActor.run {
                    messages.append(Message(role: .error, text: error.localizedDescription))
                }
            }
            
            await MainActor.run {
                // Finalize streaming message
                if !streamingText.isEmpty {
                    messages.append(Message(role: .assistant, text: streamingText))
                    streamingText = ""
                }
                currentToolUse = nil
                isLoading = false
            }
        }
    }
    
    private func handleEvent(_ event: AgentEvent) {
        switch event {
        case .text(let text):
            streamingText += text
            
        case .toolStart(let tool, let args):
            let displayName = ToolUse(tool: tool, args: nil).displayName
            if let path = args?["path"] as? String {
                let filename = URL(fileURLWithPath: path).lastPathComponent
                currentToolUse = "\(displayName) \(filename)..."
            } else {
                currentToolUse = "\(displayName)..."
            }
            
        case .toolEnd:
            currentToolUse = nil
            
        case .error(let message):
            messages.append(Message(role: .error, text: message))
            
        case .status, .done:
            break
        }
    }
    
    private func clearChat() async {
        do {
            try await appState.clearSession(for: agent.id)
            messages = []
        } catch {
            print("Failed to clear chat: \(error)")
        }
    }
}

#Preview {
    let agent = Agent(
        id: "cody",
        name: "Cody",
        role: "Coder",
        description: "Implementation",
        model: "claude-sonnet",
        accent: "#059669",
        status: .idle
    )
    return ChatView(agent: agent)
        .environmentObject(AppState())
}
