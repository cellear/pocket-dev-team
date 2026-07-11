import Foundation

struct Workspace: Identifiable, Codable {
    let id: String
    var name: String
    var url: URL
    var token: String?
    var lastConnected: Date?
    
    init(id: String = UUID().uuidString, name: String, url: URL, token: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.token = token
        self.lastConnected = nil
    }
}
