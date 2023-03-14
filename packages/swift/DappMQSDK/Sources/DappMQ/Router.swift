//
//  Router.swift
//  
//
//  Created by X Tommy on 2023/2/27.
//

import UIKit

@objc private protocol RouterSelectors: NSObjectProtocol {
    var destinations: [NSNumber] { get }
    func sendResponseForDestination(_ destination: NSNumber)
}

enum Router {
    
    @MainActor
    static func openURLIfCould(_ URL: URL) {
        guard UIApplication.shared.canOpenURL(URL) else {
            return
        }
        UIApplication.shared.open(URL)
    }
    
    @MainActor
    static func backToDapp(redirectUrl: String?) {
        Router.jumpBackToPreviousApp()
    }
    
    @MainActor
    static func routeToWallet(url: String? = nil) {
        let deepLinkUrl = url ?? "web3mq://?"
        guard let deepLinkURL = URL(string: deepLinkUrl) else {
            return
        }
        if UIApplication.shared.canOpenURL(deepLinkURL) {
            UIApplication.shared.open(deepLinkURL)
        }
    }
    
    @discardableResult
    static func jumpBackToPreviousApp() -> Bool {
        guard
            let sysNavIvar = class_getInstanceVariable(UIApplication.self, "_systemNavigationAction"),
            let action = object_getIvar(UIApplication.shared, sysNavIvar) as? NSObject,
            let destinations = action.perform(#selector(getter: RouterSelectors.destinations)).takeUnretainedValue() as? [NSNumber],
            let firstDestination = destinations.first
        else {
            return false
        }
        action.perform(#selector(RouterSelectors.sendResponseForDestination), with: firstDestination)
        return true
    }
}
