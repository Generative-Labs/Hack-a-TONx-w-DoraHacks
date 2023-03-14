//
//  MessageIdGenerator.swift
//  
//
//  Created by X Tommy on 2023/3/2.
//

import Foundation
import CryptoSwift

enum MessageIdGenerator {

    static func generate(userId: String, topic: String, timestamp: UInt64, payload: [UInt8])
    throws -> String
    {
        var digest = SHA3(variant: .sha224)
        let _ = try digest.update(withBytes: userId.bytes, isLast: false)
        let _ = try digest.update(withBytes: topic.bytes, isLast: false)
        let _ = try digest.update(withBytes: String(timestamp).bytes, isLast: false)
        let result = try digest.update(withBytes: payload, isLast: true)
        return result.toHexString()
    }

}
