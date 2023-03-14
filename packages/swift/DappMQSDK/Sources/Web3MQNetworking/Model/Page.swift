//
//  Page.swift
//  
//
//  Created by X Tommy on 2023/1/17.
//

import Foundation

///
public struct Page<T: Decodable>: Decodable {
    
    ///
    public var total: Int? = 0
    
    ///
    public var result: [T] = []
    
    ///
    public init(total: Int = 0, result: [T] = []) {
        self.total = total
        self.result = result
    }
    
    ///
    public static func empty() -> Self {
        return Page()
    }
    
    enum CodingKeys: String, CodingKey {
        case total = "total_count"
        case result = "data_list"
    }

}
