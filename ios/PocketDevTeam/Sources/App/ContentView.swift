import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isConnected {
                MainTabView()
            } else {
                ConnectView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
