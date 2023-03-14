//
//  Response.swift
//  
//
//  Created by X Tommy on 2023/2/16.
//

import Foundation

///
public struct RPCResponse: Codable {
    
    public let id: String
    
    public let jsonrpc: String
    
    public let method: String?
        
    public var result: AnyCodable? {
        if case .response(let value) = outcome { return value }
        return nil
    }

    public var error: RPCError? {
        if case .error(let error) = outcome { return error }
        return nil
    }

    public let outcome: RPCResult

    public init(id: String, method: String, outcome: RPCResult) {
        self.jsonrpc = "2.0"
        self.id = id
        self.outcome = outcome
        self.method = method
    }
    
    enum CodingKeys: CodingKey {
        case jsonrpc
        case result
        case error
        case id
        case method
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decode(String.self, forKey: .jsonrpc)
        method = try? container.decode(String.self, forKey: .method)
        guard jsonrpc == "2.0" else {
            throw DecodingError.dataCorruptedError(
                forKey: .jsonrpc,
                in: container,
                debugDescription: "The JSON-RPC protocol version must be exactly \"2.0\".")
        }
        id = try container.decode(String.self, forKey: .id)
        let result = try? container.decode(AnyCodable.self, forKey: .result)
        let error = try? container.decode(RPCError.self, forKey: .error)
        if let result = result {
            guard error == nil else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [CodingKeys.result, CodingKeys.error],
                    debugDescription: "Response is ambiguous: Both result and error members exists simultaneously."))
            }
            outcome = .response(result)
        } else if let error = error {
            outcome = .error(error)
        } else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: [CodingKeys.result, CodingKeys.error],
                debugDescription: "Couldn't find neither a result nor an error in the response."))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        switch outcome {
        case .response(let anyCodable):
            try container.encode(anyCodable, forKey: .result)
        case .error(let rpcError):
            try container.encode(rpcError, forKey: .error)
        }
    }

}

///
public struct Response: Codable {
    
    public let id: String
    
    public let jsonrpc: String
            
    public let result: RPCResult

    /// sender's topic
    public let topic: String
     
    /// sender's public key
    public let publicKey: String

    init(rpcResponse: RPCResponse, topic: String, publicKey: String) {
        id = rpcResponse.id
        jsonrpc = rpcResponse.jsonrpc
        result = rpcResponse.outcome
        self.topic = topic
        self.publicKey = publicKey
    }
}

struct SessionProperties: Codable {
    
    /// Date string
    let expiry: String
}

struct SessionNamespacesResult: Codable {
    
    let sessionNamespaces: [String: SessionNamespace]
    
    var sessionProperties: SessionProperties = SessionProperties(expiry: Date().advanced(by: DappMQConfiguration.sessionLifeTimeInterval).string)
    
    let metadata: AppMetadata
    
}


extension Date {
 
    var string: String {
        if #available(iOS 16.0, *) {
            return self.ISO8601Format(.iso8601WithTimeZone())
        } else {
            return ""
        }
    }
    
}
