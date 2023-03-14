//
//  Blockchain.swift
//  
//
//  Created by X Tommy on 2023/2/16.
//

import Foundation

/**
 A value that identifies a blockchain.
 [CAIP-2]:https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md
 */
public struct Blockchain: Equatable, Hashable {
    
    /// A blockchain namespace. Usually describes an ecosystem or standard.
    public let namespace: String
    
    /// A reference string that identifies a blockchain within a given namespace.
    public let reference: String
    
    /// The CAIP-2 blockchain identifier string.
    public var absoluteString: String {
        "\(namespace):\(reference)"
    }
    
    /**
     Creates an instance of a blockchain reference from a string.
     
     This initializer returns nil if the string doesn't represent a valid chain id in conformance with
     [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md)
     */
    public init?(_ string: String) {
        guard String.conformsToCAIP2(string) else { return nil }
        let splits = string.split(separator: ":")
        self.namespace = String(splits[0])
        self.reference = String(splits[1])
    }
    
    /**
     Creates an instance of a blockchain reference from a namespace and a reference string.
     
     This initializer returns nil if the `namespace` or `reference` strings formats are invalid, according to
     [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md)
     */
    public init?(namespace: String, reference: String) {
        self.init("\(namespace):\(reference)")
    }
    
}

extension Blockchain: LosslessStringConvertible {
    public var description: String {
        return absoluteString
    }
}

extension Blockchain: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let absoluteString = try container.decode(String.self)
        guard let blockchain = Blockchain(absoluteString) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Malformed CAIP-2 chain identifier.")
        }
        self = blockchain
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(absoluteString)
    }
}
