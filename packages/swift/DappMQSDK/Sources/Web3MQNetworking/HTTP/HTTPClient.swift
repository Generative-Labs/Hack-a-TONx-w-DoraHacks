//
//  HTTPClient.swift
//  
//
//  Created by X Tommy on 2023/2/28.
//

import Foundation
import CryptoKit

///
public protocol Web3MQChatSession {
    var userId: String { get set }
    var privateKey: Curve25519.Signing.PrivateKey { get set }
    var nodeId: String? { get set }
}

public struct HTTPSession: Web3MQChatSession {
        
    public var userId: String
    
    public var privateKey: Curve25519.Signing.PrivateKey
    
    public var nodeId: String?
    
    public init(userId: String, privateKey: Curve25519.Signing.PrivateKey, nodeId: String? = nil) {
        self.userId = userId
        self.privateKey = privateKey
        self.nodeId = nodeId
    }
    
//    public func updateNodeId(_ nodeId: String?) {
//        self.nodeId = nodeId
//    }
    
}

///
public protocol HTTPClient {
    
    var session: Web3MQChatSession? { set get }
    
    ///
    @discardableResult
    func send<T: Web3MQRequest>(request: T) async throws -> Web3MQResponse<T.Response>
    
}
