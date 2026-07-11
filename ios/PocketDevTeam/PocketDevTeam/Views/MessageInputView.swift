import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let accentColor: Color
    let onSend: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)
                .disabled(isLoading)
            
            Button {
                if isLoading {
                    onCancel()
                } else {
                    onSend()
                }
            } label: {
                Image(systemName: isLoading ? "stop.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend || isLoading ? accentColor : .gray)
            }
            .disabled(!canSend && !isLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isLoading: false,
            accentColor: .purple,
            onSend: {},
            onCancel: {}
        )
        
        MessageInputView(
            text: .constant("Hello"),
            isLoading: false,
            accentColor: .purple,
            onSend: {},
            onCancel: {}
        )
        
        MessageInputView(
            text: .constant("Sending..."),
            isLoading: true,
            accentColor: .purple,
            onSend: {},
            onCancel: {}
        )
    }
}
