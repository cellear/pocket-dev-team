import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var config: APIConfiguration
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var serverURL: String = ""
    @State private var authToken: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var connectionTestResult: ConnectionTestResult?
    
    enum ConnectionTestResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server URL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("http://localhost:3000", text: $serverURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auth Token")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SecureField("Enter token", text: $authToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Enter the URL of your Pocket Dev Team backend server.")
                }
                
                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                            } else {
                                Image(systemName: "network")
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(isTestingConnection || serverURL.isEmpty)
                    
                    if let result = connectionTestResult {
                        HStack {
                            switch result {
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Connection successful!")
                            case .failure(let error):
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(config.isConnected ? .green : .red)
                                .frame(width: 8, height: 8)
                            Text(config.isConnected ? "Connected" : "Disconnected")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if config.isConnected {
                        Button(role: .destructive) {
                            appViewModel.disconnect()
                        } label: {
                            Text("Disconnect")
                        }
                    }
                } header: {
                    Text("Status")
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/cellear/pocket-dev-team")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                serverURL = config.serverURL
                authToken = config.authToken
            }
        }
    }
    
    private func saveSettings() {
        config.serverURL = serverURL
        config.authToken = authToken
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        config.serverURL = serverURL
        config.authToken = authToken
        
        Task {
            let success = await AgentService.shared.checkConnection()
            
            await MainActor.run {
                isTestingConnection = false
                connectionTestResult = success ? .success : .failure("Could not connect to server")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(APIConfiguration.shared)
        .environmentObject(AppViewModel())
}
