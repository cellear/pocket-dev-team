import Foundation

class APIConfiguration: ObservableObject {
    static let shared = APIConfiguration()
    
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
        }
    }
    
    @Published var authToken: String {
        didSet {
            UserDefaults.standard.set(authToken, forKey: "authToken")
        }
    }
    
    @Published var isConnected: Bool = false
    
    private init() {
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? "http://localhost:3000"
        self.authToken = UserDefaults.standard.string(forKey: "authToken") ?? ""
    }
    
    var baseURL: URL? {
        URL(string: serverURL)
    }
    
    func authHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        if !authToken.isEmpty {
            headers["Authorization"] = "Bearer \(authToken)"
        }
        return headers
    }
}
