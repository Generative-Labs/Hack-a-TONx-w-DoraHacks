//
//  Web3MQHTTPClient.swift
//  
//
//  Created by X Tommy on 2023/3/1.
//

import Foundation
import Alamofire
import CryptoKit

///
public struct Web3MQHTTPClient: HTTPClient {
    
    ///
    public var session: Web3MQChatSession? {
        didSet {
            Web3MQParameterSigner.shared.userId = session?.userId
            Web3MQParameterSigner.shared.privateKey = session?.privateKey
        }
    }
    
    ///
    public func send<T>(request: T) async throws -> Web3MQResponse<T.Response> where T : Web3MQRequest {
        let decodedResponse = await AF.request(request).serializingDecodable(Web3MQResponse<T.Response>.self).response
#if DEBUG
        Log.print(decodedResponse.debugDescription)
#endif
        
        if let value = decodedResponse.value {
            if value.code != 0 {
                throw Web3MQNetworkingError.responseFailed(reason: .invalidHTTPStatusAPIError(value.code, value.msg))
            }
            return value
        } else {
            throw Web3MQNetworkingError.responseFailed(reason: .jsonEncodingFailed)
        }
    }
    
    public init(session: HTTPSession? = nil) {
        self.session = session
        Web3MQParameterSigner.shared.userId = session?.userId
        Web3MQParameterSigner.shared.privateKey = session?.privateKey
    }
    
}
