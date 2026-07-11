import SwiftUI

struct AgentChatView: View {
    @StateObject var viewModel: AgentViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    agentColor: viewModel.agent.swiftUIColor
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if let toolActivity = viewModel.currentToolActivity {
                    ToolActivityIndicator(activity: toolActivity, color: viewModel.agent.swiftUIColor)
                }
                
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
                
                MessageInputView(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    accentColor: viewModel.agent.swiftUIColor,
                    onSend: viewModel.sendMessage,
                    onCancel: viewModel.cancelStreaming
                )
                .focused($isInputFocused)
            }
            .navigationTitle("\(viewModel.agent.emoji) \(viewModel.agent.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.clearSession()
                            }
                        } label: {
                            Label("Clear History", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            await viewModel.loadHistory()
        }
    }
}

struct ToolActivityIndicator: View {
    let activity: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(color)
            
            Text(activity)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
    }
}

#Preview {
    let agent = Agent(id: "lila", name: "Lila", role: "Librarian", emoji: "📚", description: "Explorer", color: "#8B5CF6")
    return AgentChatView(viewModel: AgentViewModel(agent: agent))
}
