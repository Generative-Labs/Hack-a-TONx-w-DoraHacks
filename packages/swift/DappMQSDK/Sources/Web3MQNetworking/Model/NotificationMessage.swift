//
//  Message.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation

public struct NotificationPayload: Codable, Hashable {
    public let title: String
    public let content: String
    public let type: String
    public let version: Int
    public let timestamp: Int
}

public struct SearchedNotificationMessage: Codable, Hashable {

    public let cipherSuite: String
    public let from: String
    public let fromSign: String
    public let messageId: String
    public let payload: NotificationPayload
    public let payloadType: String
    public var status: String
    public let topic: String
    public let version: Int

    enum CodingKeys: String, CodingKey {
        case cipherSuite = "cipher_suite"
        case from = "from"
        case fromSign = "from_sign"
        case messageId = "messageid"
        case payload = "payload"
        case payloadType = "payload_type"
        case status = "status"
        case topic = "topic"
        case version = "version"
    }

}

/// The notification message
public struct NotificationMessage: Codable, Hashable {

    public var messageID: String = String()

    public var version: UInt32 = 0

    public var payload: Data = Data()

    public var payloadType: String = String()

    public var comeFrom: String = String()

    public var fromSign: String = String()

    public var contentTopic: String = String()

    public var cipherSuite: String = String()

    public var timestamp: UInt64 = 0

    public var read: Bool = false

    public var readTimestamp: UInt64 = 0

    public var payloadContent: NotificationPayload?

    public init() {}

    init(messageItem: Pb_NotificationItem) {
        messageID = messageItem.messageID
        version = messageItem.version
        payload = messageItem.payload
        payloadType = messageItem.payloadType
        comeFrom = messageItem.comeFrom
        fromSign = messageItem.fromSign
        contentTopic = messageItem.contentTopic
        cipherSuite = messageItem.cipherSuite
        timestamp = messageItem.timestamp
        read = messageItem.read
        readTimestamp = messageItem.readTimestamp
        payloadContent = try? JSONDecoder().decode(NotificationPayload.self, from: payload)
    }

    func toPbMessageItem() -> Pb_NotificationItem {
        var messageItem = Pb_NotificationItem()
        messageItem.messageID = messageID
        messageItem.version = version
        messageItem.payload = payload
        messageItem.payloadType = payloadType
        messageItem.comeFrom = comeFrom
        messageItem.fromSign = fromSign
        messageItem.contentTopic = contentTopic
        messageItem.cipherSuite = cipherSuite
        messageItem.timestamp = timestamp
        messageItem.read = read
        messageItem.readTimestamp = readTimestamp
        return messageItem
    }

}

public struct BridgeMessagePayload: Codable {
    public let didType: String
    public let didValue: String
    public let device: String
    public let action: String
    public var signature: String?

    public func toDictionary() -> [String: String] {
        var temp = [
            "did_type": didType,
            "did_type": didValue,
            "device": device,
            "action": action,
        ]
        temp["signature"] = signature
        return temp
    }

    public func toData() -> Data? {
        return try? JSONSerialization.data(withJSONObject: toDictionary())
    }

}

/// Message
public struct Web3MQMessage: Codable {

    public var payload: Data = Data()

    public var contentTopic: String = String()

    public var version: UInt32 = 0

    public var comeFrom: String = String()

    public var fromSign: String = String()

    public var payloadType: String = String()

    public var cipherSuite: String = String()

    public var needStore: Bool = false

    public var timestamp: UInt64 = 0

    public var messageID: String = String()

    public var messageType: String = String()

    public var nodeID: String = String()

    public var payloadText: String?
    
    public var validatePubKey: String = String()

    public init() {}

    init(messageItem: Pb_Web3MQMessage) {
        payload = messageItem.payload
        contentTopic = messageItem.contentTopic
        version = messageItem.version
        comeFrom = messageItem.comeFrom
        fromSign = messageItem.fromSign
        payloadType = messageItem.payloadType
        cipherSuite = messageItem.cipherSuite
        needStore = messageItem.needStore
        timestamp = messageItem.timestamp
        messageID = messageItem.messageID
        messageType = messageItem.messageType
        nodeID = messageItem.nodeID
        validatePubKey = messageItem.validatePubKey
        payloadText = String(
            data: messageItem.payload,
            encoding: .utf8)
    }

    func toPbRequestMessage() -> Pb_Web3MQMessage {
        var messageItem = Pb_Web3MQMessage()
        messageItem.payload = payload
        messageItem.contentTopic = contentTopic
        messageItem.version = version
        messageItem.comeFrom = comeFrom
        messageItem.fromSign = fromSign
        messageItem.payloadType = payloadType
        messageItem.cipherSuite = cipherSuite
        messageItem.needStore = needStore
        messageItem.timestamp = timestamp
        messageItem.messageID = messageID
        messageItem.messageType = messageType
        messageItem.nodeID = nodeID
        messageItem.validatePubKey = validatePubKey
        return messageItem
    }

    public func decodePayload<T: Decodable>() -> T? {
        guard let value = try? JSONDecoder().decode(T.self,
                                                      from: payload) else {
            return nil
        }
        return value
    }
    
}

///
public enum MessageStatus: String, Codable {
    ///
    case idle = ""
    ///
    case received
    ///
    case delivered
    ///
    case read
    ///
    case invalidSignature
    ///
    case userNotFound
}

///
public struct Web3MQMessageStatusItem: Codable {

    public var messageID: String = String()

    public var contentTopic: String = String()

    /// received delivered read
    public var messageStatus: MessageStatus = .idle

    public var version: String = String()

    public var comeFrom: String = String()

    public var fromSign: String = String()

    public var timestamp: UInt64 = 0

    init(item: Pb_Web3MQMessageStatus) {
        messageID = item.messageID
        contentTopic = item.contentTopic
        messageStatus = MessageStatus(rawValue: item.messageStatus) ?? .idle
        version = item.version
        comeFrom = item.comeFrom
        fromSign = item.fromSign
        timestamp = item.timestamp
    }

}

public enum Web3MQMessageType: String {
    case chat = ""
    case walletBridge = "wallet_bridge"
    case dAppBridge = "dapp_bridge"
    
    /// bridge message 
    case bridge = "Web3MQ/bridge"
}
