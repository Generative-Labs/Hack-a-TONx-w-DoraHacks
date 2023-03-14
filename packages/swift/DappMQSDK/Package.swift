// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DappMQSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "DappMQ",
            targets: ["DappMQ"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
        .package(url: "git@github.com:apple/swift-protobuf.git", from: "1.6.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.6.0")),
        .package(url: "git@github.com:Batxent/swift-sodium.git", branch: "master"),
        .package(url: "git@github.com:hyperoslo/Cache.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "git@github.com:vapor/url-encoded-form.git",  branch: "master")
    ],
    targets: [
        .target(
            name: "Web3MQNetworking",
            dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf"),
                           .product(name: "Alamofire", package: "Alamofire"),
                           .product(name: "Starscream", package: "Starscream"),
                           .product(name: "CryptoSwift", package: "CryptoSwift"),
                           .product(name: "Sodium", package: "swift-sodium")]),
        
        .target(name: "DappMQ", dependencies: ["Web3MQNetworking", "Cache",
                                                   .product(name: "URLEncodedForm", package: "url-encoded-form")]),
        .testTarget(
            name: "DappMQSDKTests",
            dependencies: ["DappMQ"]),
    ]
)
