//
//  KeyManager.swift
//  
//
//  Created by X Tommy on 2023/2/17.
//

import Foundation
import Combine
import CryptoKit

public protocol KeyManagerProtocol {

    var privateKey: Curve25519.Signing.PrivateKey { get }
    
    func savePrivateKey(data: Data)
    
    func remove()
}

public final class KeyManager: KeyManagerProtocol {

    lazy var keychain = UserDefaults.standard

    private let key = "ed255.data"

    private var subscriptions: Set<AnyCancellable> = []

    public static let shared = KeyManager()
    private init() {
        //
        privateKeyCreateSubject.sink { [weak self] privateKey in
            self?.savePrivateKey(data: privateKey.rawRepresentation)
        }.store(in: &subscriptions)
    }

    let privateKeyCreateSubject = PassthroughSubject<Curve25519.Signing.PrivateKey, Never>()

    /// Once you create a new privateKey, that will clean all data on session.
    public func savePrivateKey(data: Data) {
        // keychain[data: key] = data
        keychain.set(data, forKey: key)

        DappMQSessionStorage.shared.removeAll()
        DappMQSessionProposalStorage.shared.removeAll()
        RecordStorage.shared.removeAll()
    }

    private var _privateKey: Curve25519.Signing.PrivateKey?

    public var privateKey: Curve25519.Signing.PrivateKey {
        if let _privateKey {
            return _privateKey
        }

        if let data = keychain.data(forKey: key),
           let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: data) {
            _privateKey = key
            return key
        } else {
            let key = generatePrivateKey()
            _privateKey = key
            return key
        }
    }

    public func remove() {
        _privateKey = nil
        keychain.removeObject(forKey: key)
    }

    private func generatePrivateKey() -> Curve25519.Signing.PrivateKey {
        let key = Curve25519.Signing.PrivateKey()
        defer { privateKeyCreateSubject.send(key) }
        return key
    }
}
