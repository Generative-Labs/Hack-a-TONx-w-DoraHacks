//
//  ClientTests.swift
//  
//
//  Created by X Tommy on 2023/2/6.
//

import XCTest
@testable import DappMQ
@testable import Web3MQNetworking

final class ClientTests: XCTestCase {
    
    var appMetadata: AppMetadata!
    
    var requiredNamespaces: [String: ProposalNamespace]!
    
    var sessionNamespaces: [String: SessionNamespace]!
    
    var fakeRequestIdGenerator: IdGenerator!
    
    var websocket: MockWebSocket!
    
    var connector: DappMQConnector!
    
    var client: MockDappMQClient!
    
    var staticRequestId = "test_request_id"
    
    override func setUpWithError() throws {
        
        fakeRequestIdGenerator = FakeRequestIdGenerator(staticRequestId: staticRequestId)
        
        requiredNamespaces = ["eip155": ProposalNamespace(chains: [Blockchain(namespace: "eip155",
                                                                              reference: "1")!],
                                                          methods: Set(["personal_sign"]),
                                                          events: Set(["changed"]))]
        
        sessionNamespaces = ["eip155": SessionNamespace(accounts: [.init(blockchain: Blockchain(namespace: "eip155",
                                                                                                reference: "1")!, address: "0xTest")!], methods: ["personal_sign"], events: [])]
        
        appMetadata = AppMetadata(name: "Web3MQ_demo_iOS", description: "for iOS demo app testing", url: "web3mq.com", icons: ["https://pbs.twimg.com/profile_images/1536658141210890242/hHPGxrGL_400x400.jpg"])
        
        let appId = "SwapChat:im"
        
        websocket = MockWebSocket()
        
        connector = DappMQConnector(appId: appId, metadata: appMetadata, websocket: websocket)
        
        client = MockDappMQClient(appId: appId, metadata: appMetadata, connector: connector)
        client.requestIdGenerator = fakeRequestIdGenerator
        
        DappMQConfiguration.timeoutInterval = 6
        DappMQConfiguration.sessionLifeTimeInterval = 60
        
        self.websocket.connectionStatusSubject.send(.connected(nodeId: "nodeId"))
        
    }
    
    func testConnectWalletApprove() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let session = try await self.client.connectWallet(requiredNamespaces: self.requiredNamespaces)
                XCTAssertNotNil(session)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let message = try await self.client.messageForApproveSessionProposal(proposalId: self.staticRequestId,
                                                                                     sessionNamespace: self.sessionNamespaces)
                try await self.websocket.makeReceiveMessage(message)
            }
            try await group.waitForAll()
        }
    }
    
    func testConnectWalletNotApprove() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let _ = try await self.client.connectWallet(requiredNamespaces: self.requiredNamespaces)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let message = try await self.client.messageForRejectSessionProposal(proposalId: self.staticRequestId)
                try await self.websocket.makeReceiveMessage(message)
            }
            try await group.waitForAll()
        }
    }
    
    func testConnectWalletTimeout() async throws {
        
        DappMQConfiguration.timeoutInterval = 2
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            
            group.addTask {
                do {
                    _ = try await self.client.connectWallet(requiredNamespaces: self.requiredNamespaces)
                    XCTAssert(true)
                } catch {
                    XCTAssertNotNil(error)
                }
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
            
            try await group.waitForAll()
            
        }
    }
    
    func testSendingSignResponse() async throws {
        
        DappMQConfiguration.timeoutInterval = 4
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let session = try await self.client.connectWallet(requiredNamespaces: self.requiredNamespaces)
                XCTAssertNotNil(session)
                let signResponse = try await self.client.personalSign(message: "test_message", address: "0x1", password: nil, topic: session.topic)
                print("debug:signature:\(signResponse)")
                XCTAssertNotNil(signResponse)
            }
            
            group.addTask {
                let signature = "test_signature"
                try await Task.sleep(nanoseconds: 500_000_000)
                let message = try await self.client.messageForApproveSessionProposal(proposalId: self.staticRequestId,
                                                                                     sessionNamespace: self.sessionNamespaces)
                try await self.websocket.makeReceiveMessage(message)
                try await Task.sleep(nanoseconds: 500_000_000)
                let signMessage = try await self.client.messageForPersonalSign(requestId: self.staticRequestId, signature: signature)
                try await self.websocket.makeReceiveMessage(signMessage)
            }
            
            try await group.waitForAll()
        }
    }
    
    func testCleanup() async throws {
        await withThrowingTaskGroup(of: Void.self, body: { group in
            group.addTask {
                let session = try await self.client.connectWallet(requiredNamespaces: self.requiredNamespaces)
                XCTAssertNotNil(session)
            }
            
            group.addTask {
                let message = try await self.client.messageForApproveSessionProposal(proposalId: self.staticRequestId,
                                                                                     sessionNamespace: self.sessionNamespaces)
                try await self.websocket.makeReceiveMessage(message)
            }
        })
        
        XCTAssertGreaterThan(client.sessions.count, 0)
        client.cleanup()
        XCTAssertEqual(client.sessions.count, 0)
        XCTAssertNil(client.connector.currentURL)
    }
    
}
