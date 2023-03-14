//
//  MockWebSocket.swift
//  
//
//  Created by X Tommy on 2023/2/6.
//

import Foundation
import CryptoKit
import Combine
@testable import Web3MQNetworking
@testable import DappMQ

class MockWebSocket: WebSocketClient {
    
    var currentURL: URL?
    
    var currentNodeId: String? {
        nodeId
    }
    
    let nodeId: String = "test_node_id"
    
    var messageStatusPublisher: AnyPublisher<Web3MQMessageStatusItem, Never> {
        messageStatusSubject.eraseToAnyPublisher()
    }
    
    var notificationPublisher: AnyPublisher<[NotificationMessage], Never> {
        notificationSubject.eraseToAnyPublisher()
    }
    
    private let messageStatusSubject = PassthroughSubject<Web3MQMessageStatusItem, Never>()
    private let notificationSubject = PassthroughSubject<[NotificationMessage], Never>()
    
    var connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.idle)
    
    private lazy var defaultURL = URL(string: "wss://web3mq.com/message")!
    
    func connectWebSocket(URL: URL) async throws {
        connectionStatusSubject.send(.connecting)
        try await Task.sleep(nanoseconds: 100_000_000)
        connectionStatusSubject.send(.waitingForNodeId)
    }
    
    func connect(url: URL?,
                 nodeId: String?,
                 userId: String,
                 privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId {
        let finalURL = url ?? defaultURL
        try await connectWebSocket(URL: finalURL)
        try await Task.sleep(nanoseconds: 100_000_000)
        connectionStatusSubject.send(.connected(nodeId: nodeId))
        currentURL = finalURL
        return self.nodeId
    }
    
    func bridgeConnect(url: URL?,
                       nodeId: String?,
                       appId: String,
                       topic: String,
                       privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId {
        let finalURL = url ?? defaultURL
        try await connectWebSocket(URL: finalURL)
        try await Task.sleep(nanoseconds: 100_000_000)
        connectionStatusSubject.send(.connected(nodeId: nodeId))
        self.currentURL = url
        return self.nodeId
    }
    
    func disconnect(source: ConnectionStatus.DisconnectionSource, completion: () -> Void) {
        currentURL = nil
        completion()
    }
    
    func write(commandType: UInt8, bytes: [UInt8]) async {
        
    }
    
    var messagePublisher: AnyPublisher<Web3MQMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }
    
    private let messageSubject = PassthroughSubject<Web3MQMessage, Never>()
    
    func updateConnectionStatus(_ status: ConnectionStatus) {
        connectionStatusSubject.send(status)
    }
    
    func makeReceiveMessage(_ message: Web3MQMessage) async throws {
        messageSubject.send(message)
    }
    
}
