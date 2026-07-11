import Foundation
import SwiftUI

struct Agent: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let role: String
    let emoji: String
    let description: String
    let color: String
    
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
}

struct AgentsResponse: Codable {
    let agents: [Agent]
}
