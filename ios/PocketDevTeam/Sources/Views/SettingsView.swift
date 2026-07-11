import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                // Current workspace
                if let workspace = appState.currentWorkspace {
                    Section("Connected Workspace") {
                        LabeledContent("Name", value: workspace.name)
                        LabeledContent("URL", value: workspace.url.absoluteString)
                    }
                }
                
                // Agents
                Section("Agents") {
                    ForEach(appState.agents) { agent in
                        HStack {
                            Circle()
                                .fill(agent.accentColor)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading) {
                                Text(agent.name)
                                    .font(.headline)
                                Text(agent.role)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(agent.status.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Actions
                Section {
                    Button(role: .destructive) {
                        appState.disconnect()
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                }
                
                // About
                Section("About") {
                    LabeledContent("Version", value: "0.1.0")
                    
                    Link(destination: URL(string: "https://drupalforge.org")!) {
                        Label("Drupal Forge", systemImage: "link")
                    }
                    
                    Link(destination: URL(string: "https://github.com/cellear/pocket-dev-team")!) {
                        Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
