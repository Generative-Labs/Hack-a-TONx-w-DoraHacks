//
//  File.swift
//  
//
//  Created by X Tommy on 2023/1/7.
//

import UIKit
import Starscream
import Combine
import CryptoKit

public typealias NodeId = String

/// Status of the connection to the websocket
public enum ConnectionStatus {
    
    /// the initial status
    case idle
    
    /// is connecting to the web3mq websocket
    case connecting
    
    /// The web socket is connected, waiting for the node id
    case waitingForNodeId
    
    /// The connection is successful and nodeId is returned
    case connected(nodeId: String?)
    
    /// The connection has been disconnected
    case disconnected(source: DisconnectionSource)
    
    /// Some errors occurs
    case error(_ error: Error?)
    
    /// Provides additional information about the source of disconnecting.
    public enum DisconnectionSource: Equatable {
        /// A user initiated web socket disconnecting.
        case user
        
        /// The system initiated web socket disconnecting.
        case system
        
        /// didn't get a pong response.
        case noPongReceived
    }
    
    /// Checks if the connection state is connected.
    public var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
    
    public var isConnecting: Bool {
        if case .connecting = self {
            return true
        }
        return false
    }
    
    /// Returns false if the connection state is in the `notConnected` state.
    public var isActive: Bool {
        if case .disconnected = self {
            return false
        }
        return true
    }
    
    /// Returns `true` is the state requires and allows automatic reconnection.
    public var isAutomaticReconnectionEnabled: Bool {
        guard case let .disconnected(source) = self else { return false }
        switch source {
        case .system: return true
        case .noPongReceived: return true
        case .user: return false
        }
    }
    
}

enum WebSocketConnectionMode {
    
    case `default`
    
    /// Which sends bridge connect command
    case bridge
}

///
public protocol WebSocketClient {
    
    var currentURL: URL? { get }
    
    var currentNodeId: String? { get }
    
    func connectWebSocket(URL: URL) async throws
    
    func connect(url: URL?,
                 nodeId: String?,
                 userId: String,
                 privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId
    
    func bridgeConnect(url: URL?,
                       nodeId: String?,
                       appId: String,
                       topic: String,
                       privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId
    
    func disconnect(source: ConnectionStatus.DisconnectionSource,
                    completion: () -> Void)
    
    func write(commandType: UInt8, bytes: [UInt8]) async
    
    func sendMessage(content: Any,
                     topicId: String,
                     messageType: Web3MQMessageType,
                     cipherSuite: String,
                     userId: String,
                     privateKey: Curve25519.Signing.PrivateKey) async throws -> Web3MQMessage
    
    var messagePublisher: AnyPublisher<Web3MQMessage, Never> { get }
    
    var messageStatusPublisher: AnyPublisher<Web3MQMessageStatusItem, Never> { get }
    
    var notificationPublisher: AnyPublisher<[NotificationMessage], Never> { get }
    
    var connectionStatusSubject: CurrentValueSubject<ConnectionStatus, Never> { get set }
    
}

extension WebSocketClient {
    
    @discardableResult
    public func sendMessage(content: Any,
                            topicId: String,
                            messageType: Web3MQMessageType = .chat,
                            cipherSuite: String = "NONE",
                            userId: String,
                            privateKey: Curve25519.Signing.PrivateKey
    ) async throws -> Web3MQMessage {
        guard let currentNodeId else {
            throw Web3MQNetworkingError.sendMessageFailed(reason: .disconnected)
        }
        let payloadData: Data
        let payloadType: String
        if let text = content as? String {
            guard let data = text.data(using: .utf8) else {
                throw Web3MQNetworkingError.sendMessageFailed(reason: .messageInvalid)
            }
            payloadData = data
            payloadType = "text/plain; charset=utf-8"
        } else if let data = content as? Data {
            payloadData = data
            payloadType = "application/json"
        } else {
            throw Web3MQNetworkingError.sendMessageFailed(reason: .messageInvalid)
        }
        
        var message = Pb_Web3MQMessage()
        let timestamp = Date().millisecondsSince1970
        let messageId =
        (try? MessageIdGenerator.generate(
            userId: userId,
            topic: topicId,
            timestamp: timestamp,
            payload: payloadData.bytes)) ?? ""
        message.messageID = messageId
        message.version = 1
        message.payload = payloadData
        message.payloadType = payloadType
        message.comeFrom = userId
        message.validatePubKey = privateKey.publicKey.rawRepresentation.base64EncodedString()
        
        let content = messageId + userId + topicId + currentNodeId + String(timestamp)
        message.fromSign = try privateKey.signature(for: content.bytes).base64EncodedString()
        message.contentTopic = topicId
        message.cipherSuite = cipherSuite
        message.timestamp = timestamp
        message.needStore = true
        message.messageType = messageType.rawValue
        Log.print("debug:writeMessage:\((try? message.jsonString()) ?? "")")
        let bytes = try message.serializedData().bytes
        await write(commandType: WebSocketMessageType.message.rawValue, bytes: bytes)
        return Web3MQMessage(messageItem: message)
    }
    
}

/// 
public class WebSocketManager: WebSocketClient {
    
    private var subscriptions: Set<AnyCancellable> = []
    
    var websocket: WebSocket?
    
    public var isConnected: Bool {
        connectionStatusSubject.value.isConnected
    }
    
    public var connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.idle)
    
    private let timerType: Timer.Type = DefaultTimer.self
    
    private var retryTimer: TimerControl?
    
    // the default retry strategy
    private lazy var retryStrategy = DefaultRetryStrategy()
    
    /// The queue on which web socket engine methods are called
    private let engineQueue: DispatchQueue = .init(label: "io.web3mq.com.web_socket_engine_queue",
                                                   qos: .userInitiated)
    
    lazy var pingManager = WebSocketPingManager(timerType: DefaultTimer.self, timerQueue: engineQueue)
    
    var userId: String?
    
    var privateKey: Curve25519.Signing.PrivateKey?
    
    var appId: String?
    
    public private(set) var currentURL: URL?
    
    public private(set) var currentNodeId: String?
    
    private var mode: WebSocketConnectionMode = .default
    
    public init() {
        bindEvents()
    }
    
    private var connectContinuation: UnsafeContinuation<Void, any Error>?
    
    private var tempConnectContinuation: UnsafeContinuation<Void, any Error>?
    
    private var connectNodeIdContinuation: UnsafeContinuation<NodeId, any Error>?
    
    private var tempConnectNodeIdContinuation: UnsafeContinuation<NodeId, any Error>?
    
    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }
    
    public var notificationPublisher: AnyPublisher<[NotificationMessage], Never> {
        notificationSubject.eraseToAnyPublisher()
    }
    
    public var messagePublisher: AnyPublisher<Web3MQMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    public var messageStatusPublisher: AnyPublisher<Web3MQMessageStatusItem, Never> {
        messageStatusSubject.eraseToAnyPublisher()
    }
    
    let notificationSubject = PassthroughSubject<[NotificationMessage], Never>()
    let messageSubject = PassthroughSubject<Web3MQMessage, Never>()
    let messageStatusSubject = PassthroughSubject<Web3MQMessageStatusItem, Never>()
    
    private func findWebSocketURL(value: URL?) async -> URL {
        return value ?? Endpoint.devSg1.websocketURL
    }
    
    @discardableResult
    /// - Returns: may throws Timeout error.
    public func connect(url: URL? = nil,
                        nodeId: String? = nil,
                        userId: String,
                        privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId {
        self.userId = userId
        self.privateKey = privateKey
        let finalURL = await findWebSocketURL(value: url)
        mode = .default
        try await connectWebSocket(URL: finalURL)
        return try await sendConnectCommand(nodeId: nodeId,
                                            userId: userId,
                                            privateKey:  privateKey)
    }
    
    @discardableResult
    public func bridgeConnect(url: URL? = nil,
                              nodeId: String? = nil,
                              appId: String,
                              topic: String,
                              privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId {
        self.appId = appId
        self.userId = topic
        self.privateKey = privateKey
        let finalURL = await findWebSocketURL(value: url)
        mode = .bridge
        try await connectWebSocket(URL: finalURL)
        return try await sendBridgeConnectCommand(nodeId: nodeId,
                                                  appId: appId,
                                                  topic: topic,
                                                  privateKey: privateKey)
    }
    
    /// 若没有抛出异常，则表示连接成功
    public func connectWebSocket(URL: URL) async throws {
        websocket = WebSocket(request: URLRequest(url: URL), useCustomEngine: true)
        websocket?.delegate = self
        websocket?.connect()
        connectionStatusSubject.send(.connecting)
        currentURL = URL
        
        try await withUnsafeThrowingContinuation({ [weak self] continuation in
            self?.connectContinuation = continuation
        })
    }
    
    private func sendBridgeConnectCommand(nodeId: String?,
                                          appId: String,
                                          topic: String,
                                          privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId {
        
        Log.print("send bridge command: appId:\(appId), topic: \(topic)")
        
        let nodeId = nodeId ?? "nodeId"
        let ts = Date().millisecondsSince1970
        
        let signMessage = appId + topic + String(ts)
        let signature = try privateKey.signature(for: signMessage.bytes)
        let dAppSignature = signature.base64EncodedString()
        
        var command = Pb_BridgeConnectCommand()
        command.nodeID = nodeId
        command.dappID = appId
        command.dappSignature = dAppSignature
        command.topicID = topic
        command.signatureTimestamp = ts
        await write(commandType: command.commandType.rawValue,
                    bytes: try command.serializedData().bytes)
        
        return try await withUnsafeThrowingContinuation({ [weak self] continuation in
            self?.tempConnectNodeIdContinuation = continuation
        })
    }
    
    private func sendConnectCommand(nodeId: String?,
                                    userId: String,
                                    privateKey: Curve25519.Signing.PrivateKey) async throws -> NodeId {
        
        let nodeId = nodeId ?? "nodeId"
        let ts = Date().millisecondsSince1970
        
        let signMessage = nodeId + userId + String(ts)
        let signature = try privateKey.signature(for: signMessage.bytes)
        let signatureString = signature.base64EncodedString()
        
        var command = Pb_ConnectCommand()
        command.nodeID = nodeId
        command.timestamp = UInt64(ts)
        command.userID = userId
        command.msgSign = signatureString
        await write(commandType: command.commandType.rawValue,
                    bytes: try command.serializedData().bytes)
        
        return try await withUnsafeThrowingContinuation({ [weak self] continuation in
            self?.connectNodeIdContinuation = continuation
        })
    }
    
    private func canReconnectAutomatically() -> Bool {
        connectionStatusSubject.value.isAutomaticReconnectionEnabled
    }
    
    func scheduleReconnectionTimerIfNeeded() {
        if canReconnectAutomatically() {
            scheduleReconnectionTimer()
        }
    }
    
    func scheduleReconnectionTimer() {
        let delay = retryStrategy.getDelayAfterTheFailure()
        Log.print("Reconnect Timer \(delay) sec")
        
        retryTimer = timerType.schedule(
            timeInterval: delay,
            queue: .main) { [weak self] in
                Log.print("Firing timer for a reconnect")
                self?.reconnectIfNeeded()
            }
    }
    
    func cancelReconnectionTimer() {
        guard retryTimer != nil else { return }
        
        Log.print("Timer ❌")
        
        retryTimer?.cancel()
        retryTimer = nil
    }
    
    private func reconnectIfNeeded() {
        guard canReconnectAutomatically(), let currentURL else { return }
        switch mode {
        case .`default`:
            guard let privateKey, let userId else {
                return
            }
            defaultReconnect(url: currentURL, userId: userId, privateKey: privateKey)
        case .bridge:
            guard let appId, let userId, let privateKey else {
                return
            }
            bridgeReconnect(url: currentURL, appId: appId, userId: userId, privateKey: privateKey)
        }
    }
    
    private func defaultReconnect(url: URL, userId: String, privateKey: Curve25519.Signing.PrivateKey) {
        Task {
            try await connectWebSocket(URL: url)
            return try await sendConnectCommand(nodeId: nil, userId: userId, privateKey: privateKey)
        }
    }
    
    private func bridgeReconnect(url: URL,
                                 appId: String,
                                 userId: String,
                                 privateKey: Curve25519.Signing.PrivateKey) {
        Task {
            try await connectWebSocket(URL: url)
            return try await sendBridgeConnectCommand(nodeId: nil,
                                                      appId: appId,
                                                      topic: userId,
                                                      privateKey: privateKey)
        }
    }
    
    /// Disconnects the web socket.
    ///
    /// Calling this function has no effect, if the connection is in an inactive state.
    /// - Parameter source: Additional information about the source of the disconnection. Default value is `.user`.
    public func disconnect(source: ConnectionStatus.DisconnectionSource = .user,
                           completion: () -> Void) {
        // force disconnect will not send disconnect delegate
        connectionStatusSubject.send(.disconnected(source: source))
        
        websocket?.forceDisconnect()
        completion()
    }
    
    ///
    public func write(commandType: UInt8, bytes: [UInt8]) async {
        guard let websocket else {
            return
        }
        return await withUnsafeContinuation({ continuation in
            let data = webSocketData(commandType: commandType, bytes: bytes)
            websocket.write(data: data) {
                continuation.resume()
            }
        })
    }
    
    func webSocketData(commandType: UInt8, bytes: [UInt8]) -> Data {
        let categoryType = 10
        var resultBytes = [UInt8]()
        resultBytes.append(UInt8(categoryType))
        resultBytes.append(commandType)
        resultBytes.append(contentsOf: bytes)
        return Data(resultBytes)
    }
    
    deinit {
        disconnect { }
        cancelReconnectionTimer()
    }
    
}

// MARK: - WebSocketDelegate

extension WebSocketManager: WebSocketDelegate {
    
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        Log.print("didReceive:\(event)")
        switch event {
        case .connected(_):
            connectionStatusSubject.send(.waitingForNodeId)
            
            connectContinuation?.resume()
            connectContinuation = nil
            
            tempConnectContinuation?.resume()
            tempConnectContinuation = nil
        case .disconnected(_, let code):
            if case .abnormalClosure = URLSessionWebSocketTask.CloseCode(rawValue: Int(code)) {
                connectionStatusSubject.send(.disconnected(source: .user))
            } else {
                connectionStatusSubject.send(.disconnected(source: .system))
            }
        case .binary(let data):
            let responseData = data.bytes
            let type = responseData[1]
            let bytes = responseData[2...responseData.count - 1]
            didReceiveMessage(messageType: type, content: Array(bytes))
        case .text(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_ ):
            break
        case .cancelled:
            connectionStatusSubject.send(.disconnected(source: .system))
        case .error(let error):
            connectionStatusSubject.send(.error(error))
        case .pong(_ ):
            pingManager.pongReceived()
        default:
            break
        }
    }
    
    private func didReceiveMessage(messageType: UInt8, content: [UInt8]) {
        guard let messageType = WebSocketMessageType(rawValue: messageType) else {
            return
        }
        
        switch messageType {
        case .connectResponse:
            let command = try? Pb_ConnectCommand(contiguousBytes: content)
            Log.print("debug:connectResponse:NodeID:\(command?.nodeID ?? "")")
            connectionStatusSubject.send(.connected(nodeId: command?.nodeID))
            if let nodeId = command?.nodeID {
                currentNodeId = nodeId
                connectNodeIdContinuation?.resume(returning: nodeId)
                connectNodeIdContinuation = nil
            }
        case .bridgeConnectResponse:
            let command = try? Pb_BridgeConnectCommand(contiguousBytes: content)
            Log.print("debug:bridgeConnectResponse:NodeID:\(command?.nodeID ?? "")")
            connectionStatusSubject.send(.connected(nodeId: command?.nodeID))
            if let nodeId = command?.nodeID {
                currentNodeId = nodeId
                tempConnectNodeIdContinuation?.resume(returning: nodeId)
                tempConnectNodeIdContinuation = nil
            }
        case .notificationList:
            guard let messageItem = try? Pb_Web3MQNotificationList(contiguousBytes: content)
            else {
                return
            }
            let notifications = messageItem.data.map({ NotificationMessage(messageItem: $0) })
            notificationSubject.send(notifications)
            Log.print("debug:Web3MQConnector:notificationList:\(notifications)")
        case .message:
            guard let messageItem = try? Pb_Web3MQMessage(contiguousBytes: content) else {
                return
            }
            
            messageSubject.send(Web3MQMessage(messageItem: messageItem))
            Log.print("debug:Web3MQConnector:message:\((try? messageItem.jsonString()) ?? "")")
        case .messageSendingStatusUpdate:
            guard let messageItem = try? Pb_Web3MQMessageStatus(contiguousBytes: content)
            else {
                return
            }
            let message = Web3MQMessageStatusItem(item: messageItem)
            Log.print(
                "debug:Web3MQConnector:messageDelivered:\((try? messageItem.jsonString()) ?? "")"
            )
            messageStatusSubject.send(message)
        case .pong:
            pingManager.pongReceived()
            
        default: break
        }
        
        // reset ping timer if receives message.
        pingManager.connectionStateDidChange(.connected(nodeId: nil))
    }
}

extension WebSocketManager {
    
    func sendPing(_ pingCommand: Pb_WebsocketPingCommand? = nil) {
        if let pingBytes = try? pingCommand?.serializedData().bytes {
            Task {
                await write(commandType: WebSocketMessageType.ping.rawValue, bytes: pingBytes)
            }
        } else {
            var pingCommand = Pb_WebsocketPingCommand()
            pingCommand.timestamp = Date().millisecondsSince1970
            sendPing(pingCommand)
        }
    }
    
    private func bindEvents() {
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            guard let _ = self?.websocket?.request else {
                return
            }
            self?.scheduleReconnectionTimerIfNeeded()
        }
        
        connectionStatusSubject.sink { [weak self] status in
            self?.pingManager.connectionStateDidChange(status)
            switch status {
            case .connecting:
                self?.cancelReconnectionTimer()
            case .disconnected(let source):
                if case .user = source {
                    return
                }
                self?.scheduleReconnectionTimerIfNeeded()
            case .error(_ ):
                self?.scheduleReconnectionTimerIfNeeded()
            default:
                break
            }
        }.store(in: &subscriptions)
        
        pingManager.eventPublisher.sink { [weak self] event in
            switch event {
            case .disconnectOnNoPongReceived:
                self?.disconnect(source: .noPongReceived) {
                    Log.print("Websocket is disconnected because of no pong received")
                }
            case .sendPing:
                self?.sendPing()
            }
        }.store(in: &subscriptions)
    }
    
}
