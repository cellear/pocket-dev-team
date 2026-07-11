import SwiftUI

struct Agent: Identifiable, Codable {
    let id: String
    let name: String
    let role: String
    let description: String?
    let model: String
    let accent: String
    var status: AgentStatus
    
    var accentColor: Color {
        Color(hex: accent) ?? .blue
    }
    
    enum AgentStatus: String, Codable {
        case idle
        case working
        case error
        case needsInput = "needs_input"
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
