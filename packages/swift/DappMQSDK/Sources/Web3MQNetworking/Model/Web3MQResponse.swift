//
//  Web3MQResponse.swift
//  
//
//  Created by X Tommy on 2023/1/17.
//

import Foundation

///
public struct Web3MQResponse<T: Decodable>: Decodable {
   
    ///
    public var code: Int = 0
    
    ///
    public let msg: String?
    
    ///
    public let data: T?
    
    ///
    public var page: Page<T>?
    
    enum CodingKeys: String, CodingKey {
        case code
        case msg
        case data
        case page
    }
    
    public init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<Web3MQResponse<T>.CodingKeys> = try decoder.container(keyedBy: Web3MQResponse<T>.CodingKeys.self)
        
        self.code = try container.decode(Int.self, forKey: Web3MQResponse<T>.CodingKeys.code)
        self.msg = try container.decodeIfPresent(String.self, forKey: Web3MQResponse<T>.CodingKeys.msg)
        self.data = try? container.decodeIfPresent(T.self, forKey: Web3MQResponse<T>.CodingKeys.data)
        self.page = try? container.decodeIfPresent(Page<T>.self, forKey: Web3MQResponse<T>.CodingKeys.data)
    }
    
}
