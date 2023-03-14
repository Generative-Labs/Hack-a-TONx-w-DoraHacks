//
//  Endpoint.swift
//
//
//  Created by X Tommy on 2022/10/12.
//

import Foundation

///
public enum Endpoint: String, CaseIterable {
    case devUsWest2 = "dev-us-west-2.web3mq.com"
    case devJp1 = "dev-ap-jp-1.web3mq.com"
    case devSg1 = "dev-ap-singapore-1.web3mq.com"
    case testUsWest1 = "testnet-us-west-1-1.web3mq.com"
    case testUsWest2 = "testnet-us-west-1-2.web3mq.com"
    case testJp1 = "testnet-ap-jp-1.web3mq.com"
    case testJp2 = "testnet-ap-jp-2.web3mq.com"
    case testSg1 = "testnet-ap-singapore-1.web3mq.com"
    case testSg2 = "testnet-ap-singapore-2.web3mq.com"
}

///
public extension Endpoint {
    
    ///
    var websocketUrl: String {
        "wss://\(rawValue)/messages"
    }
    
    ///
    var websocketURL: URL {
        URL(string: websocketUrl)!
    }
    
    ///
    var httpUrl: String {
        "https://\(rawValue)"
    }

    ///
    var name: String {
        get { return String(describing: self) }
    }
}
