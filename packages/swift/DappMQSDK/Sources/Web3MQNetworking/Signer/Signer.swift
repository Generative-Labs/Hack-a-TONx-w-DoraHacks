//
//  Signer.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import CryptoKit
import CryptoSwift
import Foundation
import Sodium

public struct SignResult {
    public let signature: String
    public let timestamp: UInt64
    public let userId: String
}

//public protocol Signer {
//
//    func sign(_ content: String?) throws -> SignResult
//
//}

//public class Web3MQSigner: Signer {
//
//    public static let shared = Web3MQSigner()
//    private init() {}
//
//    public var keyPair: KeyPair?
//    public var userId: String?
//
//    public static func sign(content: String?,
//                            userId: String,
//                            privateKey: Curve25519.Signing.PrivateKey) throws -> SignResult {
//        let timestamp = Date().millisecondsSince1970
//        let temp = userId + (content ?? "") + String(timestamp)
//        let signature = try privateKey.signature(for: temp.bytes).base64EncodedString()
//        return SignResult(signature: signature, timestamp: timestamp, userId: userId)
//    }
//
//    public func sign(_ content: String?) throws -> SignResult {
//        guard let keyPair, let userId else {
//            throw Web3MQSignError.keyPairInvalid
//        }
//        return try Web3MQSigner.sign(content: content, userId: userId, privateKey: keyPair.privateKey)
//    }
//
//    public func sign(message: String) throws -> String {
//        guard let keyPair else {
//            throw Web3MQSignError.keyPairInvalid
//        }
//        let signature = try keyPair.privateKey.signature(for: message.bytes).base64EncodedString()
//        return signature
//    }
//
//
//}

public enum SignUtils {
    
    public static func sharedSecretWithX25519(publicKeyHex: String, privateKeyHex: String) throws
    -> SharedSecret
    {
        let myKey = try Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: Data(hex: privateKeyHex))
        let theirKey = try Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: Data(hex: publicKeyHex))
        return try myKey.sharedSecretFromKeyAgreement(with: theirKey)
    }
    
    public static func sharedSecretWithEd25519(publicKeyHex: String, privateKeyHex: String) throws
    -> SharedSecret
    {
        let (publicKeyX25519, privateKeyX25519) = try ed25519KeyPairToX25519(
            publicKeyHex: publicKeyHex, privateKeyHex: privateKeyHex)
        return try sharedSecretWithX25519(
            publicKeyHex: publicKeyX25519, privateKeyHex: privateKeyX25519)
    }
    
    private static func ed25519KeyPairToX25519(publicKeyHex: String, privateKeyHex: String) throws -> (
        String, String) {
            let sodium = Sodium()
            guard
                let privateKeyX25519 = sodium.sign.convertEd25519SkToCurve25519(
                    secretKey: Data(hex: privateKeyHex).bytes),
                let publicKeyX25519 = sodium.sign.convertEd25519PkToCurve25519(
                    publicKey: Data(hex: publicKeyHex).bytes) else {
                throw Web3MQSignError.exchangeError
            }
            
            let resultPublicKey = publicKeyX25519.toHexString()
            let resultPrivateKey = privateKeyX25519.toHexString()
            
            return (resultPublicKey, resultPrivateKey)
        }
    
    public static func ed25519PublicKeyToX25519(publicKeyHex: String) throws -> String {
        let sodium = Sodium()
        guard let x25519PublicKeyHex = sodium.sign.convertEd25519PkToCurve25519(
            publicKey: Data(hex: publicKeyHex).bytes)?.toHexString() else {
            throw Web3MQSignError.exchangeError
        }
        return x25519PublicKeyHex
    }
    
    public static func ed25519PrivateKeyToX25519(privateKeyHex: String) throws -> String {
        let sodium = Sodium()
        guard let x25519PrivateKeyHex = sodium.sign.convertEd25519SkToCurve25519(
            secretKey: Data(hex: privateKeyHex).bytes)?.toHexString() else {
            throw Web3MQSignError.exchangeError
        }
        return x25519PrivateKeyHex
    }
    
    public static func symmetricKeyWithEd25519(publicKeyHex: String, privateKeyHex: String) throws
    -> SymmetricKey
    {
        let sharedSecret = try sharedSecretWithEd25519(
            publicKeyHex: publicKeyHex, privateKeyHex: privateKeyHex)
        return try symmetricKey(sharedSecret: sharedSecret)
    }
    
    public static func symmetricKeyWithX25519(publicKeyHex: String, privateKeyHex: String) throws
    -> SymmetricKey
    {
        let sharedSecret = try sharedSecretWithX25519(
            publicKeyHex: publicKeyHex, privateKeyHex: privateKeyHex)
        return try symmetricKey(sharedSecret: sharedSecret)
    }
    
    public static func symmetricKey(sharedSecret: SharedSecret) throws -> SymmetricKey {
        sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA384.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
    }
    
}

extension Date {
    
    public var millisecondsSince1970: UInt64 {
        UInt64((timeIntervalSince1970 * 1000.0).rounded())
    }
    
}

extension Data {
    var bytes: [UInt8] {
        Array(self)
    }
}

extension String {
    var bytes: [UInt8] {
        data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
}
