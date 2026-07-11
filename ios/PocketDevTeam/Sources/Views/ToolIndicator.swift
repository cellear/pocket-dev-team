import SwiftUI

struct ToolIndicator: View {
    let toolName: String
    let accentColor: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text(toolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accentColor.opacity(0.1))
            .clipShape(Capsule())
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ToolIndicator(toolName: "Reading server.js...", accentColor: .green)
        ToolIndicator(toolName: "Running npm test...", accentColor: .green)
    }
    .padding()
}
