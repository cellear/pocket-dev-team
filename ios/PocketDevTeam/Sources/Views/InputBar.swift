import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let accentColor: Color
    let onSend: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Message...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .onSubmit {
                    if !text.isEmpty && !isLoading {
                        onSend()
                    }
                }
            
            // Send button
            Button {
                onSend()
                isFocused = false
            } label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 32, height: 32)
                .background(canSend ? accentColor : Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

#Preview {
    VStack {
        Spacer()
        InputBar(
            text: .constant("Hello"),
            isLoading: false,
            accentColor: .green,
            onSend: {}
        )
    }
}
