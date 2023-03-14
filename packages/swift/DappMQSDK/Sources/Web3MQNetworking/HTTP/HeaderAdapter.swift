//
//  HeaderAdapter.swift
//  
//
//  Created by X Tommy on 2023/1/4.
//

import UIKit

///
public protocol UserProvider {
    
    var publicKey: String? { get }
    
    var didType: String? { get }
    
    var didValue: String? { get }
    
}

///
public struct HeaderAdapter: RequestAdapter {

    ///
    public static var `default` = HeaderAdapter()
    
    ///
    public var userProvider: UserProvider?
    
    ///
    public func adapted(_ request: URLRequest) throws -> URLRequest {
        guard let userProvider,
              let publicKey = userProvider.publicKey,
              let didType = userProvider.didType,
              let didValue = userProvider.didValue else {
            return request
        }
        
        var request = request
        request.setValue(publicKey, forHTTPHeaderField: "web3mq-request-pubkey")
        request.setValue("2", forHTTPHeaderField: "api-version")
        //
        let didKey = didType + ":" + didValue
        request.setValue(didKey, forHTTPHeaderField: "didkey")
        return request
    }
}
