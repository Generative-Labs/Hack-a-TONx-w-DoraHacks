//
//  AppMetadata.swift
//  
//
//  Created by X Tommy on 2023/2/16.
//

import Foundation

///
public struct AppMetadata: Codable, Equatable, Hashable {

    /// The name of the app.
    public let name: String?

    /// A brief textual description of the app that can be displayed to peers.
    public let description: String?

    /// The URL string that identifies the official domain of the app.
    public let url: String?

    /// An array of URL strings pointing to the icon assets on the web.
    public let icons: [String]?

    /// Redirect links which could be manually used on wallet side
    public let redirect: String?
    
    /**
     Creates a new metadata object with the specified information.
     
     - parameters:
        - name: The name of the app.
        - description: A brief textual description of the app that can be displayed to peers.
        - url: The URL string that identifies the official domain of the app.
        - icons: An array of URL strings pointing to the icon assets on the web.
     */
    public init(name: String, description: String, url: String, icons: [String], redirect: String? = nil) {
        self.name = name
        self.description = description
        self.url = url
        self.icons = icons
        self.redirect = redirect
    }
    
}
