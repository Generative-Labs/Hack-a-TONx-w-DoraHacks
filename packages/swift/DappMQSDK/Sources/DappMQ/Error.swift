//
//  DappMQError.swift
//  
//
//  Created by X Tommy on 2023/1/9.
//

import Foundation

///
public enum DappMQError: Error {
    
    ///
    case invalidSession
    
    /// client hasn't setup proposer
    case invalidProposer
    
    /// didn't setup wallet yet
    case invalidWallet
    
    /// `appId` should not be empty
    case invalidAppId
    
    ///
    case cannotOpenURL
    
    ///
    case sessionProposalCannotFind
 
    ///
    case invalidProposal
}

///Create QRCode and make temp connection,
///but not receive `ConnectResponse` in time. Should close websocket and clean cache.
public struct TimeoutError: Error { }
