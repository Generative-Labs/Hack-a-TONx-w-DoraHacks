//
//  RPCRecordStorage.swift
//  
//
//  Created by X Tommy on 2023/2/23.
//

import Foundation
import Cache

public struct Record: Codable {
    public let id: String
    public let topic: String
    
    public let request: Request
    public var response: Response?
    
    init(request: Request) {
        self.id = request.id
        self.topic = request.topic
        self.request = request
    }
    
}

class RecordStorage {
    
    static let shared = RecordStorage()
    private init() { }
        
    private let diskConfig = DiskConfig(name: "com.web3mq.dappmq.cachekey.rpcrecords")
    private let memoryConfig = MemoryConfig(expiry: .never)

    lazy var storage = try? Storage<String, Record>(
      diskConfig: diskConfig,
      memoryConfig: memoryConfig,
      transformer: TransformerFactory.forCodable(ofType: Record.self)
    )
    
    lazy var requestIdStorage = try? Storage<String, Set<String>>(
      diskConfig: DiskConfig(name: "com.web3mq.dappmq.cachekey.request.id"),
      memoryConfig: MemoryConfig(expiry: .never),
      transformer: TransformerFactory.forCodable(ofType: Set<String>.self))
    
    func setRecord(_ record: Record) {
        try? storage?.setObject(record, forKey: record.id)
        try? insertRequestId(record.id)
    }
    
    func getRecord(forId id: String) -> Record? {
        try? storage?.object(forKey: id)
    }
    
    func setRequest(_ request: Request) {
        setRecord(Record(request: request))
    }
    
    func setResponse(_ response: Response) {
        guard var record = getRecord(forId: response.id) else {
           return
        }
        record.response = response
        setRecord(record)
    }
    
    func remove(id: String) {
        try? storage?.removeObject(forKey: id)
        try? removeRequestIdCache(id)
    }
    
    func removeAll(withTopic topic: String) {
        getRequestIds()
            .filter({ id in
                guard let record = getRecord(forId: id) else {
                    return true
                }
                return record.topic == topic
            })
            .forEach { remove(id: $0) }
    }
    
    func removeAll() {
        try? storage?.removeAll()
        try? requestIdStorage?.removeAll()
    }
    
    func getAll() -> [Record] {
        getRequestIds().compactMap { getRecord(forId: $0 )}
    }
    
    func getAll(withTopic topic: String) -> [Record] {
        getAll()
            .filter({ $0.topic == topic })
    }
    
    func getAllPendingRequests() -> [Request] {
        getRequestIds()
            .compactMap { getRecord(forId: $0) }
            .filter { $0.response == nil }
            .map { $0.request }
    }
    
    // topics
    private let requestIdsKey = "requestIds"

    private func insertRequestId(_ id: String) throws {
        var ids = getRequestIds()
        ids.insert(id)
        try? updateRequestIds(ids)
    }
    
    private func removeRequestIdCache(_ id: String) throws {
        var ids = getRequestIds()
        ids.remove(id)
        try? updateRequestIds(ids)
    }
    
    private func getRequestIds() -> Set<String> {
        (try? requestIdStorage?.object(forKey: requestIdsKey)) ?? Set()
    }
    
    private func updateRequestIds(_ ids: Set<String>) throws {
        try requestIdStorage?.setObject(ids, forKey: requestIdsKey)
    }
    
}
