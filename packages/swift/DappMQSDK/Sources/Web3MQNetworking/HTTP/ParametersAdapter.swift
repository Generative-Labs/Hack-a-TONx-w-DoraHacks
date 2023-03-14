//
//  ParametersAdapter.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation

struct URLQueryEncoder: RequestAdapter {
    let parameters: [String: Any]

    func adapted(_ request: URLRequest) throws -> URLRequest {

        guard let url = request.url else {
            throw Web3MQNetworkingError.requestFailed(reason: .missingURL)
        }

        var request = request
        let finalURL = encoded(for: url)
        request.url = finalURL

        return request
    }

    func encoded(for url: URL) -> URL {
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            !parameters.isEmpty
        {

            var allowedCharacterSet = CharacterSet.urlQueryAllowed
            allowedCharacterSet.remove(charactersIn: "!*'();:@&=+$,/?%#[]")

            let percentEncodedQuery =
                (components.percentEncodedQuery.map { $0 + "&" } ?? "")
                + query(parameters, allowed: allowedCharacterSet)
            components.percentEncodedQuery = percentEncodedQuery
            return components.url ?? url
        }
        return url
    }
}

struct JSONParameterEncoder: RequestAdapter {
    let parameters: [String: Any]

    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = data
        } catch {
            throw Web3MQNetworkingError.requestFailed(reason: .jsonEncodingFailed(error))
        }
        return request
    }
}

struct FormUrlEncodedParameterEncoder: RequestAdapter {
    let parameters: [String: Any]
    func adapted(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
        return request
    }
}

private func query(_ parameters: [String: Any], allowed: CharacterSet = .urlQueryAllowed) -> String
{
    return
        parameters
        .reduce([]) {
            (result, kvp) in
            result + queryComponents(fromKey: kvp.key, value: kvp.value, allowed: allowed)
        }
        .map { "\($0)=\($1)" }
        .joined(separator: "&")
}

private func queryComponents(
    fromKey key: String,
    value: Any,
    allowed: CharacterSet = .urlQueryAllowed
) -> [(String, String)] {
    var components: [(String, String)] = []

    if let dictionary = value as? [String: Any] {
        for (nestedKey, value) in dictionary {
            components += queryComponents(
                fromKey: "\(key)[\(nestedKey)]", value: value, allowed: allowed)
        }
    } else if let array = value as? [Any] {
        for value in array {
            components += queryComponents(fromKey: "\(key)[]", value: value, allowed: allowed)
        }
    } else if let value = value as? NSNumber {
        if value.isBool {
            components.append((escape(key), escape(value.boolValue ? "true" : "false")))
        } else {
            components.append((escape(key), escape("\(value)")))
        }
    } else if let bool = value as? Bool {
        components.append((escape(key), escape(bool ? "true" : "false")))
    } else {
        components.append((escape(key), escape("\(value)", allowed: allowed)))
    }

    return components
}

// Reserved characters defined by RFC 3986
// Reference: https://www.ietf.org/rfc/rfc3986.txt
private func escape(_ string: String, allowed: CharacterSet = .urlQueryAllowed) -> String {
    let generalDelimitersToEncode = ":#[]@"
    let subDelimitersToEncode = "!$&'()*+,;="

    var allowedCharacterSet = allowed
    allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

    return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
}

extension NSNumber {
    var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}
