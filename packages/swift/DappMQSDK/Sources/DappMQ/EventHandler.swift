//
//  EventHandler.swift
//  
//
//  Created by X Tommy on 2023/1/29.
//

import Foundation

///
public protocol EventHandler {
    
    /// If returns true, then ``handle(event:)`` will be called.
    func shouldHandle(event: DappMQMessagePayload) async -> Bool
    
    /// Handles the event, and returns a Data which will be send to the same topic
    /// - Parameter event: Web3MQMessage
    /// - Returns: a receipt which will be sent to the same topic
    func handle(event: DappMQMessagePayload) async -> RPCResponse?
    
}

public struct AnyEventHandler: EventHandler {
    
    public let shouldHandle: (DappMQMessagePayload) async -> Bool
    
    public let handle: (DappMQMessagePayload) async -> RPCResponse?
    
    public init(shouldHandle: @escaping (DappMQMessagePayload) -> Bool,
                handle: @escaping (DappMQMessagePayload) -> RPCResponse?) {
        self.shouldHandle = shouldHandle
        self.handle = handle
    }
    
    public func shouldHandle(event: DappMQMessagePayload) async -> Bool {
        await shouldHandle(event)
    }
    
    public func handle(event: DappMQMessagePayload) async -> RPCResponse? {
        await handle(event)
    }
}
