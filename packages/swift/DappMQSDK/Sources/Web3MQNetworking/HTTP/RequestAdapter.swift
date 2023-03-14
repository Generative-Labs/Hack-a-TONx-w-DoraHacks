//
//  RequestAdapter.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation
import UIKit

///
public protocol RequestAdapter {

    ///
    func adapted(_ request: URLRequest) throws -> URLRequest
}

///
public struct AnyRequestAdapter: RequestAdapter {

    var block: (URLRequest) throws -> URLRequest

    public init(_ block: @escaping (URLRequest) throws -> URLRequest) {
        self.block = block
    }

    public func adapted(_ request: URLRequest) throws -> URLRequest {
        return try block(request)
    }
}
