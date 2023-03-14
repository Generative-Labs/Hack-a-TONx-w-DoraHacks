//
//  Participant.swift
//  
//
//  Created by X Tommy on 2023/2/16.
//

import Foundation

/// 
public struct Participant: Codable, Hashable {
    
    /// In hex format
    public let publicKey: String
    
    /// App metadata, if in Wallet side, meta could be nil
    public let appMetadata: AppMetadata
    
    ///
    public init(publicKey: String, appMetadata: AppMetadata) {
        self.publicKey = publicKey
        self.appMetadata = appMetadata
    }
    
}
