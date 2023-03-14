//
//  Client.swift
//  
//
//  Created by X Tommy on 2023/1/28.
//

import Foundation
import UIKit
import Combine
import CryptoKit
import CryptoSwift
@_exported import Web3MQNetworking

///
public protocol DappMQClientProtocol {
    
    var sessions: [Session]  { get }
    
    var pendingRequests: [Request] { get }
    
    var requestPublisher: AnyPublisher<Request, Never> { get }
    
    var responsePublisher: AnyPublisher<Response, Never> { get }
    
    func deleteSession(topic: String)
    
    func createSessionProposalURI(requiredNamespaces: [String: ProposalNamespace]) -> DappMQURI
    
    func connectWallet(requiredNamespaces: [String: ProposalNamespace]) async throws -> Session
    
    func personalSign(message: String,
                      address: String,
                      password: String?,
                      topic: String) async throws -> String
    
    @discardableResult
    func approveSessionProposal(proposalId: String,
                                sessionNamespace: [String: SessionNamespace]) async throws -> Web3MQMessage
    
    @discardableResult
    func rejectSessionProposal(proposalId: String) async throws -> Web3MQMessage
    
    func pairURI(_ URI: DappMQURI) throws
    
    func sendSuccessResponse(forRequest request: Request, content: AnyCodable) async throws
    
    func sendErrorResponse(forRequest request: Request, code: Int, message: String) async throws
    
}

///
public class DappMQClient: DappMQClientProtocol {
    
    public static var requestTimeoutInterval: TimeInterval = 30
    
    ///
    public let appId: String
    
    ///
    let metadata: AppMetadata
    
    ///
    var connector: Connector
    
    ///
    public var sessions: [Session] {
        DappMQSessionStorage.shared.getAll()
    }
    
    public var latestSession: Session? {
        DappMQSessionStorage.shared.getAll().first
    }
    
    public var pendingRequests: [Request] {
        RecordStorage.shared.getAllPendingRequests()
    }
    
    public var sessionProposalPublisher: AnyPublisher<SessionProposal, Never> {
        sessionProposalSubject.compactMap({ $0 }).eraseToAnyPublisher()
    }
    
    public var requestPublisher: AnyPublisher<Request, Never> {
        requestSubject.compactMap({ $0 }).eraseToAnyPublisher()
    }
    
    public var responsePublisher: AnyPublisher<Response, Never> {
        responseSubject.eraseToAnyPublisher()
    }
    
    private let sessionProposalSubject = CurrentValueSubject<SessionProposal?, Never>(nil)
    
    private let requestSubject = CurrentValueSubject<Request?, Never>(nil)
    
    private let responseSubject = PassthroughSubject<Response, Never>()
    
    ///
    public required init(appId: String,
                         metadata: AppMetadata,
                         endpoint: URL? = nil,
                         connector: Connector? = nil) {
        self.appId = appId
        self.metadata = metadata
        if let connector {
            self.connector = connector
        } else {
            self.connector = DappMQConnector(appId: appId, url: endpoint, metadata: metadata)
        }
        bindEvents(forConnector: self.connector)
    }
    
    public func connect() async throws {
        try await connector.connect()
    }
    
    public func cleanup() {
        DappMQSessionStorage.shared.removeAll()
        DappMQSessionProposalStorage.shared.removeAll()
        RecordStorage.shared.removeAll()
    }
    
    public func deleteSession(topic: String) {
        DappMQSessionStorage.shared.remove(topic: topic)
        RecordStorage.shared.removeAll(withTopic: topic)
    }
    
    public func fetchAllRecords() -> [Record] {
        RecordStorage.shared.getAll()
    }
    
    public func fetchRecords(withTopic topic: String) -> [Record] {
        RecordStorage.shared.getAll(withTopic: topic)
    }
    
    public func cleanAllRecords(withTopic topic: String) {
        RecordStorage.shared.removeAll(withTopic: topic)
    }
    
    public var requestIdGenerator: IdGenerator = RequestIdGenerator()

    public var keyManager: KeyManagerProtocol = KeyManager.shared
    
    let concurrentQueue = DispatchQueue(label: "com.webemq.sdk.dappmq.client", attributes: .concurrent)
    
    private var connectorSubscriptions: Set<AnyCancellable> = []

    public var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }
    
    public let connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.idle)

    public var endpoint: URL? {
        connector.currentURL
    }
    
    public func switchEndpoint(_ wsURL: URL) {
        connector.disconnect()
        connector = DappMQConnector(appId: appId, url: wsURL, metadata: metadata)
        bindEvents(forConnector: connector)
    }
    
}

// MARK: - For Dapp

public extension DappMQClient {
    
    func createSessionProposalURI(requiredNamespaces: [String: ProposalNamespace]) -> DappMQURI {
        let privateKey = KeyManager.shared.privateKey
        let topic = UserIdGenerator.userId(appId: appId, publicKeyBase64String: privateKey.publicKeyBase64String)
        let requestId = requestIdGenerator.nextId()
        
        let proposal = Session.Proposal(requiredNamespaces: requiredNamespaces, sessionProperties: .init(expiry: Date().addingTimeInterval(DappMQConfiguration.sessionLifeTimeInterval).string))
        
        return DappMQURI(topic: topic, proposer: Participant(publicKey: privateKey.publicKeyHexString, appMetadata: metadata), request: SessionProposalRPCRequest(id: requestId, method: RequestMethod.providerAuthorization, params: proposal))
    }
    
    func connectWallet(requiredNamespaces: [String: ProposalNamespace]) async throws -> Session {
        let privateKey = KeyManager.shared.privateKey
        let uri = createSessionProposalURI(requiredNamespaces: requiredNamespaces)
        
        await Router.openURLIfCould(uri.deepLinkURL)
        
        let requestId = uri.request.id
        let rawResponse = try await waitingForResponse(requestId: requestId)
        switch rawResponse.result {
        case .response(let value):
            let result = try value.get(SessionNamespacesResult.self)
            let session = Session(topic: rawResponse.topic, pairingTopic: uri.topic, selfParticipant: Participant(publicKey: privateKey.publicKeyHexString, appMetadata: metadata), peerParticipant: Participant(publicKey: rawResponse.publicKey, appMetadata: result.metadata), expiryDate: result.sessionProperties.expiry, namespaces: result.sessionNamespaces)
            DappMQSessionStorage.shared.setSession(session)
            return session
        case .error(let error):
            throw error
        }
    }
    
    func personalSign(message: String,
                      address: String,
                      password: String?,
                      topic: String) async throws -> String {
        guard let session = DappMQSessionStorage.shared.getSession(forTopic: topic) else {
            throw DappMQError.invalidSession
        }
        let requestId = requestIdGenerator.nextId()
        
        let request = RPCRequest(id: requestId, method: RequestMethod.personalSign, params: AnyCodable([message, address]))
        try await connector.send(content: request, topic: topic)
        await Router.routeToWallet(url: session.peerParticipant.appMetadata.redirect)
        let response = try await waitingForResponse(requestId: requestId)
        switch response.result {
        case .response(let value):
            return try value.get(String.self)
        case .error(let error):
            throw error
        }
    }
    
}

// MARK: - For Wallet

public extension DappMQClient {
    
    @discardableResult
    func approveSessionProposal(proposalId: String,
                                sessionNamespace: [String: SessionNamespace]) async throws -> Web3MQMessage {
        guard let proposal = DappMQSessionProposalStorage.shared.getSessionProposal(forProposalId: proposalId) else {
            throw DappMQError.sessionProposalCannotFind
        }
        
        let result = RPCResult.response(AnyCodable(SessionNamespacesResult(sessionNamespaces: sessionNamespace,
                                                                           metadata: metadata)))
        
        let privateKey = KeyManager.shared.privateKey
        let selfTopic = UserIdGenerator.userId(appId: appId, publicKeyBase64String: privateKey.publicKeyBase64String)
        
        let session = Session(topic: proposal.pairingTopic, pairingTopic: selfTopic, selfParticipant: Participant(publicKey: privateKey.publicKeyHexString, appMetadata: metadata), peerParticipant: proposal.proposer, expiryDate: proposal.sessionProperties?.expiry ?? Date().addingTimeInterval(7*24*60*60).string, namespaces: sessionNamespace)
        
        DappMQSessionProposalStorage.shared.remove(proposalId: proposalId)
        DappMQSessionStorage.shared.setSession(session)
        
        let message = try await connector.send(content: RPCResponse(id: proposalId, method: RequestMethod.providerAuthorization, outcome: result), topic: proposal.pairingTopic)
        await Router.backToDapp(redirectUrl: proposal.proposer.appMetadata.redirect)
        return message
    }
    
    @discardableResult
    func rejectSessionProposal(proposalId: String) async throws -> Web3MQMessage {
        guard let proposal = DappMQSessionProposalStorage.shared.getSessionProposal(forProposalId: proposalId) else {
            throw DappMQError.sessionProposalCannotFind
        }
        let result = RPCResult.error(RPCError(code: 5001, message: "User disapproved requested methods"))
        let privateKey = KeyManager.shared.privateKey
        let message = try await connector.send(content: RPCResponse(id: proposalId, method: RequestMethod.providerAuthorization, outcome: result), topicId: proposal.pairingTopic, peerPublicKeyHex: proposal.proposer.publicKey, privateKey: privateKey)
        DappMQSessionProposalStorage.shared.remove(proposalId: proposalId)
        await Router.backToDapp(redirectUrl: proposal.proposer.appMetadata.redirect)
        return message
    }
    
    func pairURI(_ URI: DappMQURI) throws {
        let request = URI.request
        let proposal = request.params
        let sessionProposal = SessionProposal(id: request.id, pairingTopic: URI.topic, proposer: URI.proposer, requiredNamespaces: proposal?.requiredNamespaces, sessionProperties: proposal?.sessionProperties ?? Session.Properties(expiry: Date().addingTimeInterval(7*24*60*60).string))
        
        DappMQSessionProposalStorage.shared.setSessionProposal(sessionProposal, proposalId: request.id)
        sessionProposalSubject.send(sessionProposal)
    }
    
    func sendSuccessResponse(forRequest request: Request, content: AnyCodable) async throws {
        let response = RPCResponse(id: request.id, method: request.method, outcome: RPCResult.response(content))
        try await sendResponse(forRequest: request, response: response)
    }
    
    func sendErrorResponse(forRequest request: Request, code: Int, message: String) async throws {
        let response = RPCResponse(id: request.id, method: request.method, outcome: RPCResult.error(RPCError(code: code, message: message)))
        try await sendResponse(forRequest: request, response: response)
    }
    
    private func sendResponse(forRequest request: Request, response: RPCResponse) async throws {
        try await connector.send(content: response, topic: request.topic)
        RecordStorage.shared.setResponse(Response(rpcResponse: response, topic: request.topic, publicKey: request.publicKey))
        let session = DappMQSessionStorage.shared.getSession(forTopic: request.topic)
        await Router.backToDapp(redirectUrl: session?.peerParticipant.appMetadata.redirect)
    }
    
    private func sendRequest(method: String, params: AnyCodable, topic: String) async throws {
        guard let session = DappMQSessionStorage.shared.getSession(forTopic: topic) else {
            throw DappMQError.invalidSession
        }
        let id = requestIdGenerator.nextId()
        let rpcRequest = RPCRequest(id: id, method: method, params: params)
        let request = Request(rpcRequest: rpcRequest, topic: session.pairingTopic, publicKey: session.selfParticipant.publicKey)
        let privateKey = KeyManager.shared.privateKey
        RecordStorage.shared.setRequest(request)
        try await connector.send(content: rpcRequest, topicId: topic, peerPublicKeyHex: session.peerParticipant.publicKey, privateKey: privateKey)
        await Router.routeToWallet()
    }
    
}

// MARK: - Private

extension DappMQClient {
    
    private func bindEvents(forConnector connector: Connector) {
        connectorSubscriptions.forEach { $0.cancel() }
        connectorSubscriptions.removeAll()
        
        connector.requestPublisher.sink { [weak self] request in
            self?.requestSubject.send(request)
            RecordStorage.shared.setRequest(request)
        }.store(in: &connectorSubscriptions)
        
        connector.responsePublisher.sink { [weak self] response in
            self?.responseSubject.send(response)
            RecordStorage.shared.setResponse(response)
        }.store(in: &connectorSubscriptions)
    
        connector.connectionStatusPublisher.sink { [weak self] status in
            self?.connectionStatusSubject.send(status)
        }.store(in: &connectorSubscriptions)
        
    }
    
    func waitingForResponse(requestId: String) async throws -> Response {
        return try await withUnsafeThrowingContinuation { [weak self] continuation in
            var cancellable: AnyCancellable?
            cancellable = self?.responsePublisher
                .setFailureType(to: TimeoutError.self)
                .timeout(.seconds(DappMQConfiguration.timeoutInterval),
                         scheduler: concurrentQueue,
                         options: nil,
                         customError: { TimeoutError() })
                .filter { $0.id == requestId }
                .prefix(1)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        cancellable?.cancel()
                        continuation.resume(throwing: error)
                    case .finished:
                        break
                    }
                }, receiveValue: { value in
                    cancellable?.cancel()
                    continuation.resume(returning: value)
                })
        }
    }
    
}
