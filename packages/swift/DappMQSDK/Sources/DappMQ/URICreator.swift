//
//  URICreator.swift
//  
//
//  Created by X Tommy on 2023/2/7.
//

import Foundation


/// Utils for creating a `DappMQURI`

public enum URICreator {
    
    ///
    public static func create(topic: String, method: String, proposer: Participant, requireNamespaces: [String: ProposalNamespace]) -> DappMQURI {
        let requestId = RequestIdGenerator().nextId()
        let proposal = Session.Proposal(requiredNamespaces: requireNamespaces, sessionProperties: nil)
        let request = SessionProposalRPCRequest(id: requestId,
                                                method: method,
                                                params: proposal)
        return DappMQURI(topic: topic, proposer: proposer, request: request)
    }
    
}
