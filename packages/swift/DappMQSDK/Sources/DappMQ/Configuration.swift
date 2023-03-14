//
//  DappMQConfiguration.swift
//  
//
//  Created by X Tommy on 2023/2/18.
//

import Foundation

///
public enum DappMQConfiguration {
   
    /// Timeout interval for `Request`
    static var timeoutInterval: TimeInterval = 3 * 60
    
    /// Time interval for `Session` expire
    static var sessionLifeTimeInterval: TimeInterval = 7 * 24 * 60 * 60
    
}
