import SwiftUI

@main
struct PocketDevTeamApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var config = APIConfiguration.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(config)
        }
    }
}
