//
//  TokenUsageStore.swift
//  Dreamhigh
//
//  Created by AI on 1/26/26.
//

import Foundation
import CoreData
import Combine

@MainActor
final class TokenUsageStore: ObservableObject {
    @Published private(set) var usages: [TokenUsage] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetch() {
        let request = TokenUsageEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "timestamp", ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            
            self.usages = entities.compactMap { entity in
                guard let id = entity.id,
                      let timestamp = entity.timestamp,
                      let service = entity.service else {
                    return nil
                }
                
                return TokenUsage(
                    id: id,
                    timestamp: timestamp,
                    service: service,
                    inputTokens: Int(entity.inputTokens),
                    outputTokens: Int(entity.outputTokens),
                    cacheCreationTokens: Int(entity.cacheCreationTokens),
                    cacheReadTokens: Int(entity.cacheReadTokens)
                )
            }
        } catch {
            print("Failed to fetch token usages: \(error)")
        }
    }
    
    func save(service: String, inputTokens: Int, outputTokens: Int, cacheCreationTokens: Int = 0, cacheReadTokens: Int = 0) throws {
        let entity = TokenUsageEntity(context: context)
        entity.id = UUID()
        entity.timestamp = Date()
        entity.service = service
        entity.inputTokens = Int32(inputTokens)
        entity.outputTokens = Int32(outputTokens)
        entity.cacheCreationTokens = Int32(cacheCreationTokens)
        entity.cacheReadTokens = Int32(cacheReadTokens)
        
        try context.save()
        fetch()
    }
    
    // 통계 계산
    var totalInputTokens: Int {
        usages.reduce(0) { $0 + $1.totalInputTokens }
    }
    
    var totalOutputTokens: Int {
        usages.reduce(0) { $0 + $1.outputTokens }
    }
    
    var totalTokens: Int {
        usages.reduce(0) { $0 + $1.totalTokens }
    }
    
    var totalEstimatedCost: Double {
        usages.reduce(0.0) { $0 + $1.estimatedCost }
    }
    
    func serviceStats(for service: String) -> (count: Int, inputTokens: Int, outputTokens: Int, cost: Double) {
        let filtered = usages.filter { $0.service == service }
        return (
            count: filtered.count,
            inputTokens: filtered.reduce(0) { $0 + $1.totalInputTokens },
            outputTokens: filtered.reduce(0) { $0 + $1.outputTokens },
            cost: filtered.reduce(0.0) { $0 + $1.estimatedCost }
        )
    }
}
