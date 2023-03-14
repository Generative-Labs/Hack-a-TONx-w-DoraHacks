//
//  SessionStorage.swift
//  
//
//  Created by X Tommy on 2023/2/17.
//

import Foundation
import Cache

protocol SessionStorage {
    
    func setSession(_ session: Session)

    func getSession(forTopic topicId: String) -> Session?

    func getAll() -> [Session]
    
    func remove(topic: String)
    
    func removeAll()
    
}

class DappMQSessionStorage: SessionStorage {
    
    private let diskConfig = DiskConfig(name: "com.web3mq.dappmq.cachekey.session")
    private let memoryConfig = MemoryConfig(expiry: .never, countLimit: 1)

    lazy var storage = try? Storage<String, Session>(
      diskConfig: diskConfig,
      memoryConfig: memoryConfig,
      transformer: TransformerFactory.forCodable(ofType: Session.self)
    )
    
    // for get all sessions
    lazy var topicsStorage = try? Storage<String, Set<String>>(
        diskConfig: DiskConfig(name: "com.web3mq.dappmq.cachekey.session.keys", expiry: .seconds(7*24*60*60)),
      memoryConfig: MemoryConfig(expiry: .seconds(7*24*60*60)),
      transformer: TransformerFactory.forCodable(ofType: Set<String>.self)
    )
    
    static let shared = DappMQSessionStorage()
    private init() { }
    
    func setSession(_ session: Session) {
        try? storage?.setObject(session, forKey: session.topic)
        try? insertTopic(session.topic)
    }
        
    func getSession(forTopic topic: String) -> Session? {
        try? storage?.object(forKey: topic)
    }
    
    func getAll() -> [Session] {
        getTopics().compactMap { getSession(forTopic: $0) }.sorted {
            $0.expiryDate > $1.expiryDate
        }
    }
    
    func remove(topic: String) {
        try? storage?.removeObject(forKey: topic)
        try? removeTopicCache(topic)
    }
    
    func removeAll() {
        try? storage?.removeAll()
        try? topicsStorage?.removeAll()
    }
    
    // topics
    private let topicsKey = "topics"
    
    private func insertTopic(_ topic: String) throws {
        var topics = getTopics()
        topics.insert(topic)
        try? updateTopics(topics)
    }
    
    private func removeTopicCache(_ topic: String) throws {
        var topics = getTopics()
        topics.remove(topic)
        try? updateTopics(topics)
    }
    
    private func getTopics() -> Set<String> {
        (try? topicsStorage?.object(forKey: topicsKey)) ?? Set()
    }
    
    private func updateTopics(_ topics: Set<String>) throws {
        try topicsStorage?.setObject(topics, forKey: topicsKey)
    }
    
}
