//
//  SessionProposalStorage.swift
//  
//
//  Created by X Tommy on 2023/2/19.
//

import Foundation
import Cache

protocol SessionProposalStorage {
    
    func setSessionProposal(_ proposal: SessionProposal, proposalId: String)

    func getSessionProposal(forProposalId proposalId: String) -> SessionProposal?
    
    func remove(proposalId: String)
    
    func removeAll()
    
}

class DappMQSessionProposalStorage: SessionProposalStorage {

    static let shared = DappMQSessionProposalStorage()
    private init() { }
        
    private let diskConfig = DiskConfig(name: "com.web3mq.dappmq.cachekey.sessionproposal")
    private let memoryConfig = MemoryConfig(expiry: .never)

    lazy var storage = try? Storage<String, SessionProposal>(
      diskConfig: diskConfig,
      memoryConfig: memoryConfig,
      transformer: TransformerFactory.forCodable(ofType: SessionProposal.self)
    )
    
    func setSessionProposal(_ proposal: SessionProposal, proposalId: String) {
        try? storage?.setObject(proposal, forKey: proposalId)
    }
    
    func getSessionProposal(forProposalId proposalId: String) -> SessionProposal? {
        try? storage?.object(forKey: proposalId)
    }
    
    func remove(proposalId: String) {
        try? storage?.removeObject(forKey: proposalId)
    }
    
    func removeAll() {
        try? storage?.removeAll()
    }
    
}
