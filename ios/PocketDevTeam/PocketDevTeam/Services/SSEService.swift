import Foundation

class SSEService: NSObject, URLSessionDataDelegate {
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var buffer = Data()
    private var eventHandler: ((SSEEvent) -> Void)?
    private var completionHandler: (() -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private let config = APIConfiguration.shared
    
    override init() {
        super.init()
    }
    
    func sendMessage(
        to agentId: String,
        message: String,
        onEvent: @escaping (SSEEvent) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard let url = config.baseURL?.appendingPathComponent("api/agents/\(agentId)/message") else {
            onError(APIError.invalidURL)
            return
        }
        
        self.eventHandler = onEvent
        self.completionHandler = onComplete
        self.errorHandler = onError
        self.buffer = Data()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        config.authHeaders().forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        let body = ["message": message]
        request.httpBody = try? JSONEncoder().encode(body)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        task = session?.dataTask(with: request)
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            if (error as NSError).code != NSURLErrorCancelled {
                errorHandler?(error)
            }
        }
        completionHandler?()
    }
    
    private func processBuffer() {
        guard let bufferString = String(data: buffer, encoding: .utf8) else { return }
        
        let lines = bufferString.components(separatedBy: "\n\n")
        
        for (index, line) in lines.enumerated() {
            if index < lines.count - 1 {
                processEvent(line)
            } else if !line.isEmpty {
                buffer = line.data(using: .utf8) ?? Data()
            } else {
                buffer = Data()
            }
        }
    }
    
    private func processEvent(_ eventString: String) {
        let lines = eventString.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let event = try JSONDecoder().decode(SSEEvent.self, from: jsonData)
                        eventHandler?(event)
                        
                        if event.type == .done || event.type == .error {
                            cancel()
                        }
                    } catch {
                        print("Failed to decode SSE event: \(error)")
                    }
                }
            }
        }
    }
}
