import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedAgent: Agent?
    
    var body: some View {
        TabView(selection: $selectedAgent) {
            ForEach(appViewModel.agents) { agent in
                AgentChatView(viewModel: AgentViewModel(agent: agent))
                    .tabItem {
                        Label {
                            Text(agent.name)
                        } icon: {
                            Text(agent.emoji)
                        }
                    }
                    .tag(agent as Agent?)
            }
        }
        .onAppear {
            if selectedAgent == nil {
                selectedAgent = appViewModel.agents.first
            }
        }
    }
}

#Preview {
    let viewModel = AppViewModel()
    viewModel.agents = [
        Agent(id: "lila", name: "Lila", role: "Librarian", emoji: "📚", description: "Explorer", color: "#8B5CF6"),
        Agent(id: "cody", name: "Cody", role: "Coder", emoji: "💻", description: "Builder", color: "#10B981"),
        Agent(id: "quinn", name: "Quinn", role: "QA", emoji: "🔍", description: "Tester", color: "#F59E0B")
    ]
    
    return MainTabView()
        .environmentObject(viewModel)
}
