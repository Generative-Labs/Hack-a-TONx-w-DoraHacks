//
//  SignMessagePayload.swift
//  
//
//  Created by X Tommy on 2023/1/9.
//

import Foundation

///
public struct DappMQMessagePayload: Codable {
    
    ///
    public let content: String
    
    /// ed25519 hex string
    public let publicKey: String

}

///
public struct DappMQMessage: Codable {
    
    ///
    public let payload: DappMQMessagePayload
    
    ///
    public let fromTopic: String
}
