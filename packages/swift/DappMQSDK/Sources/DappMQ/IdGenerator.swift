//
//  RequestIdGenerator.swift
//  
//
//  Created by X Tommy on 2023/1/19.
//

import Foundation
import CryptoKit
import CryptoSwift

///
public protocol IdGenerator {
   
    ///
    func nextId() -> String
}

public struct RequestIdGenerator: IdGenerator {

    public func nextId() -> String {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000) * 1000
        let random = Int64.random(in: 0..<1000)
        return String(random + timestamp)
    }
    
}

///
enum UserIdGenerator {

    static func userId(appId: String, publicKeyBase64String: String) -> String {
        "bridge:" + (appId + "@" + publicKeyBase64String).sha1()
    }
    
}
