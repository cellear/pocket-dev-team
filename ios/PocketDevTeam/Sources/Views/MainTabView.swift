import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedAgentId) {
            ForEach(appState.agents) { agent in
                ChatView(agent: agent)
                    .tabItem {
                        Label(agent.name, systemImage: iconForRole(agent.role))
                    }
                    .tag(agent.id as String?)
                    .badge(badgeFor(agent))
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(nil as String?)
        }
        .tint(.primary)
    }
    
    private func iconForRole(_ role: String) -> String {
        switch role.lowercased() {
        case "librarian": return "books.vertical"
        case "coder": return "chevron.left.forwardslash.chevron.right"
        case "qa / tester", "qa", "tester": return "checkmark.shield"
        default: return "person.circle"
        }
    }
    
    private func badgeFor(_ agent: Agent) -> Int {
        switch agent.status {
        case .working: return 0  // Could show a spinner instead
        case .needsInput: return 1
        default: return 0
        }
    }
}

#Preview {
    let appState = AppState()
    return MainTabView()
        .environmentObject(appState)
}
