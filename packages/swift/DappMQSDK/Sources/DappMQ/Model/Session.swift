//
//  Session.swift
//  
//
//  Created by X Tommy on 2023/1/11.
//

import Foundation
import CryptoKit

public struct Session: Codable, Equatable {

    /// participant topic
    public let topic: String
    
    /// Self topic
    public let pairingTopic: String
    
    public let selfParticipant: Participant
    
    public let peerParticipant: Participant
    
    /// 
    public let expiryDate: String

    public let namespaces: [String: SessionNamespace]
    
}

extension Session {
    
    public struct Event: Equatable, Hashable {
        public let name: String
        public let data: AnyCodable
    }
    
    public struct Properties: Codable, Equatable {
        
        /// Date string
        public let expiry: String

    }

    public struct Proposal: Codable, Equatable {
        
        public var requiredNamespaces: [String: ProposalNamespace] = [: ]
        
        public let sessionProperties: Properties?
    }
    
}

///
public struct SessionProposal: Codable {

    ///
    public let id: String

    ///  sender topicID
    public let pairingTopic: String
    
    ///
    public let proposer: Participant

    ///
    public let requiredNamespaces: [String: ProposalNamespace]?
    
    ///
    public let sessionProperties: Session.Properties?
    
    public init(id: String, pairingTopic: String, proposer: Participant, requiredNamespaces: [String : ProposalNamespace]?, sessionProperties: Session.Properties?) {
        self.id = id
        self.pairingTopic = pairingTopic
        self.proposer = proposer
        self.requiredNamespaces = requiredNamespaces
        self.sessionProperties = sessionProperties
    }
    
}
