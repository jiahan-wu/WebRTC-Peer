//
//  WebSocketClient.swift
//  Peer
//
//  Created by Jia-Han Wu on 2025/4/13.
//

import Foundation

protocol WebSocketClientDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data)
    func webSocketClientDidDisconnect(_ client: WebSocketClient)
}

class WebSocketClient {
    
    private let url: URL
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    weak var delegate: WebSocketClientDelegate?
    
    init(url: URL) {
        self.url = url
    }
    
    func connect() {
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    func send(_ data: Data) async throws {
        guard let webSocketTask else { return }
        try await webSocketTask.send(.data(data))
    }
    
    private func receiveMessage() {
        guard let webSocketTask else { return }
        
        Task {
            do {
                let message = try await webSocketTask.receive()
                
                switch message {
                case .data(let data):
                    delegate?.webSocketClient(self, didReceiveData: data)
                case .string(let string):
                    print("Received text: \(string)")
                @unknown default:
                    break
                }
                
                receiveMessage()
            } catch {
                delegate?.webSocketClientDidDisconnect(self)
                self.webSocketTask = nil
            }
        }
    }
    
}
