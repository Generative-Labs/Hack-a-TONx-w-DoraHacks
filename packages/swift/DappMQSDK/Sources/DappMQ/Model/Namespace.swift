//
//  Namespace.swift
//  
//
//  Created by X Tommy on 2023/2/16.
//

import Foundation

public struct ProposalNamespace: Equatable, Codable, Hashable {
    
    public let chains: Set<String>
    public let methods: Set<String>
    public let events: Set<String>?
    
    public init(chains: [Blockchain], methods: Set<String>, events: Set<String>) {
        self.chains = Set(chains.map({ $0.absoluteString }))
        self.methods = methods
        self.events = events
    }
    
}

public struct SessionNamespace: Equatable, Codable, Hashable {
    
    public let accounts: Set<Account>
    public let methods: Set<String>
    public let events: Set<String>?
    
    public init(accounts: Set<Account>, methods: Set<String>, events: Set<String>) {
        self.accounts = accounts
        self.methods = methods
        self.events = events
    }
    
    static func accountsAreCompliant(_ accounts: Set<Account>, toChains chains: Set<Blockchain>) -> Bool {
        for chain in chains {
            guard accounts.contains(where: { $0.blockchain == chain }) else {
                return false
            }
        }
        return true
    }
    
}
