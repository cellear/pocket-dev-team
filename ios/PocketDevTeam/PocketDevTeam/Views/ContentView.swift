import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var config: APIConfiguration
    @State private var showingSettings = false
    
    var body: some View {
        Group {
            if appViewModel.isConnected && !appViewModel.agents.isEmpty {
                MainTabView()
            } else {
                ConnectionView()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
                    .font(.title2)
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .environmentObject(APIConfiguration.shared)
}
