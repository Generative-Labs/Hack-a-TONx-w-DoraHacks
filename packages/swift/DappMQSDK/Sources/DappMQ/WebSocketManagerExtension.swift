//
//  WebSocketManagerExtension.swift
//  
//
//  Created by X Tommy on 2023/1/10.
//

import Foundation
import Web3MQNetworking
import CryptoKit

extension WebSocketClient {

    func send(_ message: DappMQMessagePayload,
              topicId: String,
              userId: String,
              privateKey: Curve25519.Signing.PrivateKey) async throws -> Web3MQMessage {
        let data = try JSONEncoder().encode(message)
        return try await sendMessage(content: data,
                              topicId: topicId,
                              messageType: .bridge,
                              cipherSuite: "X25519/AES-GCM_SHA384",
                              userId: userId,
                              privateKey: privateKey)
    }
    
}
