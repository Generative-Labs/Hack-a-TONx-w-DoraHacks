//
//  WebSocketMessageType.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation

public enum WebSocketMessageType: UInt8 {
    
    case chatReq = 1
    case message = 0b00010000
    
    /// message delivered
    /// Node received your message
    case messageSendingStatusUpdate = 0b00010101
    
    /// other client update the status
    case messageStatusUpdate = 0b00010110
    
    case notificationList = 0b00010100
    
    case ping = 0b10000000
    case pong = 0b10000001
    
    case connectRequest = 0b00000010
    case connectResponse = 0b00000011
    
    case bridgeConnectRequest = 100
    case bridgeConnectResponse = 101
    
}

extension Pb_BridgeConnectCommand {
    var commandType: WebSocketMessageType {
        WebSocketMessageType.bridgeConnectRequest
    }
}

extension Pb_ConnectCommand {
    var commandType: WebSocketMessageType {
        WebSocketMessageType.connectRequest
    }
}
