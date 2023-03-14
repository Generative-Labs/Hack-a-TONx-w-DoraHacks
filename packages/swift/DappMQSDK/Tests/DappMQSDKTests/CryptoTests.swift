//
//  SignTests.swift
//
//
//  Created by X Tommy on 2023/1/28.
//

import XCTest
import CryptoKit
@testable import DappMQ

/// Crypto Tests
final class CryptoTests: XCTestCase {

    private var peerPublicKeyHexString: String!
    
    private var privateKeyHexString: String!
    
    private var shareKeyCoder: ShareKeyCoder!
    
    override func setUpWithError() throws {
        peerPublicKeyHexString = "8820A1E05E5CDFDB96AE25CAE90F2B4F914E642E19FE46ACA5B1ED1CC5FA550D"
        privateKeyHexString = "FC7C969E6492D1AF4F221CF492D1F6D6B37D5774A2BD7826CF95EEDD9E5234B3"
        shareKeyCoder = DappMQShareKeyCoder()
    }
    
    func testEncrypt() throws {
        let bytes = Data(hex: privateKeyHexString)
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: bytes)
        let encrypted = try shareKeyCoder.encryptData("aaa".bytes, peerPublicKeyHexString: peerPublicKeyHexString, privateKey: privateKey)
        XCTAssertEqual(encrypted, "nfg3+s9cni++B3TQwnwMamD5fw==")
    }
    
    func testDecrypt() throws {
        let bytes = Data(hex: privateKeyHexString)
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: bytes)
    
        let decodedData = try shareKeyCoder.decodeToData(content: "nfg3+s9cni++B3TQwnwMamD5fw==", peerPublicKeyHexString: peerPublicKeyHexString, privateKey: privateKey)

        let decoded = String(data: decodedData, encoding: .utf8)
        XCTAssertEqual(decoded, "aaa")
    }

}
