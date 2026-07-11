import SwiftUI

struct ConnectView: View {
    @EnvironmentObject var appState: AppState
    @State private var serverURL = ""
    @State private var token = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo / Header
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Pocket Dev Team")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your AI colleagues, anywhere")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Connection form
                VStack(spacing: 16) {
                    TextField("Server URL", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    SecureField("API Token (optional)", text: $token)
                        .textFieldStyle(.roundedBorder)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button {
                        Task { await connect() }
                    } label: {
                        HStack {
                            if isConnecting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isConnecting ? "Connecting..." : "Connect")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(serverURL.isEmpty || isConnecting)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Help text
                VStack(spacing: 8) {
                    Text("Need a workspace?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Link("Create one on Drupal Forge", destination: URL(string: "https://drupalforge.org")!)
                        .font(.subheadline)
                }
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func connect() async {
        guard let url = URL(string: serverURL) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isConnecting = true
        errorMessage = nil
        
        let workspace = Workspace(
            name: url.host ?? "Workspace",
            url: url,
            token: token.isEmpty ? nil : token
        )
        
        do {
            try await appState.connect(to: workspace)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isConnecting = false
    }
}

#Preview {
    ConnectView()
        .environmentObject(AppState())
}
