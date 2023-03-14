//
//  Web3MQSDKError.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation

public enum Web3MQNetworkingError: Error {

    /// The possible underlying reasons a `.requestFailed` error occurs.
    public enum RequestErrorReason {

        /// The `URL` object is missing while encoding a request.
        case missingURL

        /// The request requires a JSON body but the provided data cannot be encoded to valid JSON.
        case jsonEncodingFailed(Error)

        /// The request cannot be created due to the parameter does not match the precondition. Check the associated
        /// values for detail information.
        case invalidParameter([ParameterItem])

        /// The request requires a valid keyPair but the provided private key or public key cannot be generated to a
        /// Curve25519 Signing Key.
        case keyPairEmpty
        
        ///
        case invalidRequest
    }

    public typealias ErrorMessage = String
    
    public typealias ErrorCode = Int
    
    /// The possible underlying reasons an `.responseFailed` error occurs.
    public enum ResponseErrorReason {

        /// The received response contains an invalid HTTP status code.
        case invalidHTTPStatusAPIError(ErrorCode, ErrorMessage?)
        
        /// The request requires a JSON body but the provided data cannot be encoded to valid JSON.
        case jsonEncodingFailed
        
        /// The response.data is empty.
        case dataEmpty
    }

    /// The possible underlying reasons an `.sendMessageFailed` error occurs.
    public enum SendingMessageErrorReason {

        ///
        case messageInvalid

        /// Did not connect to the web3mq websocket
        case disconnected
        
    }

    ///
    public enum ConnectingErrorReason {
        
        ///
        case timeout
        
        ///
        case error(error: Error)
    }
    
    case requestFailed(reason: RequestErrorReason)

    case responseFailed(reason: ResponseErrorReason)

    case sendMessageFailed(reason: SendingMessageErrorReason)
    
    case connectFailed(reason: ConnectingErrorReason)
}

extension Web3MQNetworkingError.RequestErrorReason {
    public struct ParameterItem {
        public let name: String
        public let value: String
        public let description: String
    }
}
