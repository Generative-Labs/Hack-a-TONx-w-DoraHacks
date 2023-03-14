//
//  MockClient.swift
//  
//
//  Created by X Tommy on 2023/2/6.
//

import Foundation
import Combine
import CryptoKit
@testable import DappMQ
@testable import Web3MQNetworking

class MockDappMQClient: DappMQClient {
    
    let peerPrivateKey = Curve25519.Signing.PrivateKey()
    
    required init(appId: String, metadata: AppMetadata, endpoint: URL? = nil, connector: Connector? = nil) {
        super.init(appId: appId, metadata: metadata, connector: connector)
    }
    
    func messageForApproveSessionProposal(proposalId: String,
                                          sessionNamespace: [String: SessionNamespace]) async throws -> Web3MQMessage {
        let result = RPCResult.response(AnyCodable(SessionNamespacesResult(sessionNamespaces: sessionNamespace,
                                                                           metadata: AppMetadata(name: "", description: "", url: "", icons: [""]))))
        let content = RPCResponse(id: proposalId, method: RequestMethod.providerAuthorization, outcome: result)
        
        let peerPublicKeyHex = KeyManager.shared.privateKey.publicKeyHexString
        return try await connector.send(content: content, topicId: "test_topic_id", peerPublicKeyHex: peerPublicKeyHex, privateKey: peerPrivateKey)
    }
    
    func messageForRejectSessionProposal(proposalId: String) async throws -> Web3MQMessage {
        let result = RPCResult.error(RPCError(code: 5001, message: "User disapproved requested methods"))
        let content = RPCResponse(id: proposalId, method: RequestMethod.providerAuthorization, outcome: result)
        let peerPublicKeyHex = KeyManager.shared.privateKey.publicKeyHexString
        return try await messageForContent(content)
    }
    
    func messageForPersonalSign(requestId: String, signature: String) async throws -> Web3MQMessage {
        let result = RPCResult.response(AnyCodable(signature))
        let content = RPCResponse(id: requestId, method: RequestMethod.personalSign, outcome: result)
        return try await messageForContent(content)
    }
    
    private func messageForContent(_ content: RPCResponse) async throws -> Web3MQMessage {
        let peerPublicKeyHex = KeyManager.shared.privateKey.publicKeyHexString
        return try await connector.send(content: content, topicId: "test_topic_id", peerPublicKeyHex: peerPublicKeyHex, privateKey: peerPrivateKey)
    }
    
}
