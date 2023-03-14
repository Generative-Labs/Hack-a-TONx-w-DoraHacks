//
//  Web3MQParameterSigner.swift
//  
//
//  Created by X Tommy on 2023/3/2.
//

import Foundation
import CryptoKit

class Web3MQParameterSigner: ParameterSigner {

    var userId: String?
    var privateKey: Curve25519.Signing.PrivateKey?
    
    static let shared = Web3MQParameterSigner()
    
    func signed(_ parameters: Parameters?,
                signContent: String?,
                signatureKey: String) -> Parameters? {
        // If didn't set `userId` or `privateKey`, just return the origin parameters
        // and the request may get an response with an inaccessible error code.
        guard var parameters, let userId, let privateKey else {
            return parameters
        }
        let signResult = try? sign(content: signContent, userId: userId, privateKey: privateKey)
        parameters[signatureKey] = signResult?.signature
        parameters["userid"] = signResult?.userId
        parameters["timestamp"] = signResult?.timestamp
        return parameters
    }
    
    func sign(content: String?,
              userId: String,
              privateKey: Curve25519.Signing.PrivateKey) throws -> SignResult {
        let timestamp = Date().millisecondsSince1970
        let temp = userId + (content ?? "") + String(timestamp)
        let signature = try privateKey.signature(for: temp.bytes).base64EncodedString()
        return SignResult(signature: signature, timestamp: timestamp, userId: userId)
    }
    
}
