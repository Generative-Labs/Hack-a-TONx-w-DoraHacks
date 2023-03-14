//
//  KeyPair.swift
//
//
//  Created by X Tommy on 2022/10/11.
//

import Foundation
import CryptoKit
import CryptoSwift

///
public struct KeyPair {
    
    public let privateKey: Curve25519.Signing.PrivateKey
    public let publicKey: Curve25519.Signing.PublicKey
    
    public init(_ privateKeyString: String) throws {
        self.privateKey = try Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(hex: privateKeyString))
        self.publicKey = privateKey.publicKey
    }
    
    public init(privateKey: Curve25519.Signing.PrivateKey)
    {
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey
    }
    
}

extension KeyPair {
    
    public var privateKeyString: String {
        return privateKey.rawRepresentation.toHexString()
    }
    
    public var publicKeyString: String {
        return publicKey.rawRepresentation.toHexString()
    }
}

extension KeyPair {
    
    public static func generate() -> KeyPair {
        let signingPrivateKey = Curve25519.Signing.PrivateKey()
        return KeyPair(privateKey: signingPrivateKey)
    }
    
}

public enum KeyGenerator {
    
    public static func generateKeyPair() -> KeyPair {
        return KeyPair.generate()
    }
    
    // https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
    public static func generateRandomKey() -> String? {
        var bytes = [Int8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            return nil
        }
    }
}


