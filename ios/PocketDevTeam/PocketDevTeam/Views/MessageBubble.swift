import SwiftUI

struct MessageBubble: View {
    let message: Message
    let agentColor: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let toolActivity = message.toolActivity {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text(toolActivity)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                Text(message.content.isEmpty && message.isStreaming ? "..." : message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground)
                    .foregroundColor(bubbleForeground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                if message.isStreaming {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(agentColor)
                            .frame(width: 4, height: 4)
                            .opacity(0.6)
                        Circle()
                            .fill(agentColor)
                            .frame(width: 4, height: 4)
                            .opacity(0.8)
                        Circle()
                            .fill(agentColor)
                            .frame(width: 4, height: 4)
                    }
                    .padding(.leading, 8)
                }
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var bubbleBackground: Color {
        message.role == .user ? .blue : Color(.systemGray5)
    }
    
    private var bubbleForeground: Color {
        message.role == .user ? .white : .primary
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(
            message: Message(role: .user, content: "Hello, can you help me?"),
            agentColor: .purple
        )
        
        MessageBubble(
            message: Message(role: .assistant, content: "Of course! I'd be happy to help you explore the codebase."),
            agentColor: .purple
        )
        
        MessageBubble(
            message: Message(role: .assistant, content: "", isStreaming: true, toolActivity: "Reading file..."),
            agentColor: .purple
        )
    }
    .padding()
}
