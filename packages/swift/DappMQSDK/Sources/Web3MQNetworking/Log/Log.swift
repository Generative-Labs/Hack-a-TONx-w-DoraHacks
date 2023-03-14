//
//  Log.swift
//
//
//  Created by X Tommy on 2022/11/30.
//

import Foundation

enum Log {

    static func assertionFailure(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        Swift.assertionFailure("[Networking] \(message())", file: file, line: line)
    }

    static func fatalError(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Never {
        Swift.fatalError("[Networking] \(message())", file: file, line: line)
    }

    static func precondition(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        Swift.precondition(condition(), "[Networking] \(message())", file: file, line: line)
    }

    static func print(_ items: Any...) {
        let s = items.reduce("") { result, next in
            return result + String(describing: next)
        }
        Swift.print("[Networking] \(s)")
    }
}
