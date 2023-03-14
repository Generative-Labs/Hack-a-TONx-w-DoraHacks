//
//  AnyParameterSigner.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation
import CryptoKit

/// For Web3MQ signature
public protocol ParameterSigner {
    
    func signed(_ parameters: Parameters?,
                signContent: String?,
                signatureKey: String) -> Parameters?
}

//struct AnyParameterSigner: ParameterSigner {
//
//    var block: (Parameters?, String?, String, String?, Curve25519.Signing.PrivateKey?) throws -> Parameters
//
//    func signed(_ parameters: Parameters?, signContent: String?, signatureKey: String) throws -> Parameters {
//        return try block(parameters, signContent, signatureKey)
//    }
//
//}
