//
//  DappMQURI.swift
//  
//
//  Created by X Tommy on 2023/1/7.
//

import Foundation
import URLEncodedForm

///
public struct DappMQURI: Codable {
        
    public let topic: String
    
    public let proposer: Participant
    
    public let request: SessionProposalRPCRequest
    
//    public let origin: String? = "https://"
    
    enum DappMQURIError: Error {
        case urlStringInvalid
    }
    
    public var absoluteString: String {
        guard let data = try? URLEncodedFormEncoder().encode(self),
        let uriString = String(data: data, encoding: .utf8) else {
            return ""
        }
        return uriString
    }
    
    public var deepLinkURL: URL {
        URL(string: "web3mq://?\(absoluteString)")!
    }
    
    public init?(string: String) {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        if let uri = try? URLEncodedFormDecoder(omitEmptyValues: true).decode(DappMQURI.self, from: data) {
            self = uri
        } else {
            return nil
        }
    }
    
    public init(topic: String, proposer: Participant, request: SessionProposalRPCRequest) {
        self.topic = topic
        self.proposer = proposer
        self.request = request
    }
    
    private static func trimURI(from string: String) -> String {
        return URL(string: string)?.query ?? ""
    }
    
}
