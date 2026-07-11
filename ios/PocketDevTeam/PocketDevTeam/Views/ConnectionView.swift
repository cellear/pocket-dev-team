import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var config: APIConfiguration
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "laptopcomputer.and.iphone")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("Pocket Dev Team")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your AI coding agents, always with you")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(appViewModel.isConnected ? .green : .red)
                        .font(.caption)
                    Text(appViewModel.isConnected ? "Connected" : "Disconnected")
                        .font(.subheadline)
                }
                
                Text(config.serverURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if let error = appViewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                Task {
                    await appViewModel.connect()
                }
            } label: {
                HStack {
                    if appViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(appViewModel.isLoading ? "Connecting..." : "Connect")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(appViewModel.isLoading)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ConnectionView()
        .environmentObject(AppViewModel())
        .environmentObject(APIConfiguration.shared)
}
