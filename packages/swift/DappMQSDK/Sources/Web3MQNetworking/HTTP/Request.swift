//
//  Request.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation
import CryptoKit
import Alamofire

/// HTTP methods specified in a `Request` object.
///
/// - get: The GET method.
/// - post: The POST method.
/// - put: The PUT method.
/// - delete: The DELETE method.
public enum HTTPMethod: String {
    /// The GET method.
    case get = "GET"
    /// The POST method.
    case post = "POST"
    /// The PUT method.
    case put = "PUT"
    /// The DELETE method.
    case delete = "DELETE"
    
    var adapter: AnyRequestAdapter {
        return .init { request in
            var request = request
            request.httpMethod = self.rawValue
            return request
        }
    }
}

public enum ContentType {
    case none
    case formUrlEncoded
    case json

    var headerValue: String {
        switch self {
        case .none: return ""
        case .formUrlEncoded: return "application/x-www-form-urlencoded; charset=utf-8"
        case .json: return "application/json"
        }
    }

    var adapter: AnyRequestAdapter? {
        if self == .none {
            return nil
        }

        return .init { request in
            var request = request
            request.setValue(self.headerValue, forHTTPHeaderField: "Content-Type")
            return request
        }
    }
}

public typealias Parameters = [String: Any]

public protocol Web3MQRequest: URLRequestConvertible {

    associatedtype Response: Decodable

    var method: HTTPMethod { get }

    var baseURL: URL { get }

    var path: String { get }

    var pathQueries: [URLQueryItem]? { get }

    var parameters: Parameters? { get }

    var contentType: ContentType { get }

    var adapters: [RequestAdapter] { get }

    var signer: ParameterSigner? { get }

    var signatureKey: String { get }
    
    var signContent: String? { get }
    
    var timeout: TimeInterval { get }

    var cachePolicy: NSURLRequest.CachePolicy { get }
    
}

extension Web3MQRequest {

    public var baseURL: URL {
        return URL(string: "https://\(Endpoint.devSg1.rawValue)")!
    }

    public var contentType: ContentType {
        return .json
    }

    public var adapters: [RequestAdapter] {

        var adapters: [RequestAdapter] = [
            HeaderAdapter.default,
            method.adapter
        ]
        
        let signedParameters = signer?.signed(parameters, signContent: signContent, signatureKey: signatureKey) ?? parameters

        if let signedParameters {
            switch (method, contentType) {
            case (.get, _):
                adapters.append(URLQueryEncoder(parameters: signedParameters))
            case (_, .formUrlEncoded):
                adapters.append(FormUrlEncodedParameterEncoder(parameters: signedParameters))
            case (_, .json):
                adapters.append(JSONParameterEncoder(parameters: signedParameters))
            case (_, .none):
                fatalError("You must specify a contentType to use POST request.")
            }
        }
        
        contentType.adapter.map { adapters.append($0) }

        return adapters
    }
    
    public var signer: ParameterSigner? { Web3MQParameterSigner.shared }
    public var signatureKey: String { "web3mq_signature" }
    public var signContent: String? { nil }
    public var pathQueries: [URLQueryItem]? { nil }
    public var parameters: Parameters? { nil }
    public var cachePolicy: NSURLRequest.CachePolicy { .reloadIgnoringLocalCacheData }
    public var timeout: TimeInterval { 30 }
    
}

extension Web3MQRequest {

     public func asURLRequest() throws -> URLRequest {

        let url = self.baseURL
            .appendingPathComponentIfNotEmpty(self)
            .appendingPathQueryItems(self)

        let urlRequest = URLRequest(
            url: url,
            cachePolicy: self.cachePolicy,
            timeoutInterval: self.timeout)

        let adapters = self.adapters

        let adaptedRequest = try adapters.reduce(urlRequest) { r, adapter in
            try adapter.adapted(r)
        }
        return adaptedRequest
    }

}

extension URL {
    
    func appendingPathComponentIfNotEmpty<R: Web3MQRequest>(_ request: R) -> URL {
        let path = request.path
        return path.isEmpty ? self : appendingPathComponent(path)
    }
    
    func appendingPathQueryItems<R: Web3MQRequest>(_ request: R) -> URL {
        guard request.method != .get else {
            return self
        }
        guard let items = request.pathQueries else {
            return self
        }
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = items
        return components.url ?? self
    }
}
