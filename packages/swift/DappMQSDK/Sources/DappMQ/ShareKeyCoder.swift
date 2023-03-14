//
//  ShareKeyCoder.swift
//
//
//  Created by X Tommy on 2023/1/28.
//

import Foundation
import CryptoKit
import CryptoSwift
import Web3MQNetworking

public protocol ShareKeyCoder {

    func encrypt<T: Codable>(_ object: T,
                             peerPublicKeyHexString: String,
                             privateKey: Curve25519.Signing.PrivateKey) throws -> String
    
    
    func encryptData(_ data: Array<UInt8>,
                            peerPublicKeyHexString: String,
                            privateKey: Curve25519.Signing.PrivateKey) throws -> String
    
    func decode<T: Codable>(content: String,
                                   peerPublicKeyHexString: String,
                                   privateKey: Curve25519.Signing.PrivateKey) throws -> T
    
    func decodeToData(content: String,
                       peerPublicKeyHexString: String,
                       privateKey: Curve25519.Signing.PrivateKey) throws -> Data
        
}

///
public struct DappMQShareKeyCoder: ShareKeyCoder {
    
    ///
    public func encrypt<T: Codable>(_ object: T,
                                    peerPublicKeyHexString: String,
                                    privateKey: Curve25519.Signing.PrivateKey) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        return try encryptData(data.bytes, peerPublicKeyHexString: peerPublicKeyHexString, privateKey: privateKey)
    }
    
    /// Uses ed25519 public key from other side and self's private key to generate the shared AES key data,
    /// then aes encode the data into an base64 string.
    /// - Parameters:
    ///   - data: The data to be encrypted.
    ///   - otherSidePublicKeyHexString: the other side public key in hex
    ///   - privateKey: private key in hex
    /// - Returns: the encrypt result in base64.
    public func encryptData(_ data: Array<UInt8>,
                            peerPublicKeyHexString: String,
                            privateKey: Curve25519.Signing.PrivateKey) throws -> String {
        
        let aes = try aes(peerPublicKeyHexString: peerPublicKeyHexString, privateKey: privateKey)
        
        return try aes.encrypt(data).toBase64()
    }
    
    /// Uses ed25519 public key from other side and self's private key to generate the shared AES key data,
    /// then aes decode the content string into a codable object.
    /// - Parameters:
    ///   - content: Base 64 format string
    ///   - otherSidePublicKeyHexString: the other side public key hex
    ///   - privateKey: private key in hex
    /// - Returns:
    public func decode<T: Codable>(content: String,
                                   peerPublicKeyHexString: String,
                                   privateKey: Curve25519.Signing.PrivateKey) throws -> T {
        let data = try decodeToData(content: content,
                              peerPublicKeyHexString: peerPublicKeyHexString,
                              privateKey: privateKey)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    public func decodeToData(content: String,
                       peerPublicKeyHexString: String,
                       privateKey: Curve25519.Signing.PrivateKey) throws -> Data {
        let aes = try aes(peerPublicKeyHexString: peerPublicKeyHexString, privateKey: privateKey)
        let contentData = [UInt8](base64: content)
        let decryptedData = try aes.decrypt(contentData)
        return Data(decryptedData)
    }
    
    private func aes(peerPublicKeyHexString: String,
                            privateKey: Curve25519.Signing.PrivateKey) throws -> CryptoSwift.AES {
        let publicKeyHexString = peerPublicKeyHexString
        let privateKeyEd255519HexString = privateKey.rawRepresentation.toHexString()
        
        let symmetricKey = try SignUtils.symmetricKeyWithEd25519(publicKeyHex: publicKeyHexString,
                                                                 privateKeyHex: privateKeyEd255519HexString)
        
        let symmetricKeyBase64 = symmetricKey.withUnsafeBytes { Data($0).base64EncodedString() }
        let ivString = String(symmetricKeyBase64.prefix(16))
        
        let keyData = [UInt8](base64: symmetricKeyBase64)
        let iv = [UInt8](base64: ivString)
        
        return try AES(key: keyData,
                       blockMode: GCM(iv: iv, mode: .combined),
                       padding: .noPadding)
    }
    
    public init() { }
    
}

extension Curve25519.Signing.PrivateKey {
    
    var publicKeyHexString: String {
        publicKey.rawRepresentation.toHexString()
    }
    
    var publicKeyBase64String: String {
        publicKey.rawRepresentation.base64EncodedString()
    }
    
}

extension Sequence {
    
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
}

