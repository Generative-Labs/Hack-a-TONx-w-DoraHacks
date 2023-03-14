//
//  Request.swift
//  
//
//  Created by X Tommy on 2023/2/16.
//

import Foundation

public struct RPCRequest: Codable, Equatable {
    
    public let id: String
    
    public let jsonrpc: String

    public let method: String

    public let params: AnyCodable
    
    internal init(id: String, method: String, params: AnyCodable) {
        self.id = id
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
    
}

public struct SessionProposalRPCRequest: Codable, Equatable {
    
    public let id: String
    
    public let jsonrpc: String

    public let method: String

    public let params: Session.Proposal?
    
    init(id: String, method: String, params: Session.Proposal) {
        self.id = id
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
    
}

///
public struct Request: Codable, Equatable {
   
    ///
    public let id: String
    
    ///
    public let method: String
    
    ///
    public let params: AnyCodable
    
    /// sender's topic
    public let topic: String
    
    /// sender's public key
    public let publicKey: String
    
    ///
    public init(rpcRequest: RPCRequest, topic: String, publicKey: String) {
        self.id = rpcRequest.id
        self.method = rpcRequest.method
        self.params = rpcRequest.params
        self.topic = topic
        self.publicKey = publicKey
    }
    
    ///
    public init(id: String, topic: String, method: String, publicKey: String, params: AnyCodable) {
        self.id = id
        self.topic = topic
        self.method = method
        self.params = params
        self.publicKey = publicKey
    }
    
}

enum RequestMethod {

    static let providerAuthorization = "provider_authorization"
    
    static let personalSign = "personal_sign"
    
}


extension Request {
    
    public var sender: Participant? {
        DappMQSessionStorage.shared.getSession(forTopic: topic)?.peerParticipant
    }
    
}
