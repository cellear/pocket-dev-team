import SwiftUI

struct MessageBubble: View {
    let message: Message
    let accentColor: Color
    var isStreaming = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(backgroundColor)
                    .foregroundStyle(foregroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                // Tool uses (if any)
                if let toolUses = message.toolUses, !toolUses.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(toolUses.indices, id: \.self) { index in
                            let tool = toolUses[index]
                            Text(tool.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                // Timestamp
                if !isStreaming {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if message.role != .user {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return Color(.systemGray5)
        case .tool:
            return accentColor.opacity(0.2)
        case .error:
            return .red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch message.role {
        case .user:
            return .white
        case .error:
            return .red
        default:
            return .primary
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubble(
            message: Message(role: .user, text: "Add rate limiting to the API"),
            accentColor: .green
        )
        MessageBubble(
            message: Message(role: .assistant, text: "I'll add rate limiting using express-rate-limit. Let me check the current server setup first."),
            accentColor: .green
        )
        MessageBubble(
            message: Message(role: .error, text: "Connection failed"),
            accentColor: .green
        )
    }
    .padding()
}
