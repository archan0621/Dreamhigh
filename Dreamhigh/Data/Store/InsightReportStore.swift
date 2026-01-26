//
//  InsightReportStore.swift
//  Dreamhigh
//
//  Created by AI on 1/26/26.
//

import Foundation
import CoreData
import Combine

@MainActor
final class InsightReportStore: ObservableObject {
    @Published private(set) var reports: [InsightReportHistory] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetch() {
        let request = InsightReportEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "generatedAt", ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            
            self.reports = entities.compactMap { entity in
                guard let id = entity.id,
                      let generatedAt = entity.generatedAt,
                      let reportData = entity.reportData?.data(using: .utf8),
                      let report = try? JSONDecoder().decode(InsightReport.self, from: reportData) else {
                    return nil
                }
                
                return InsightReportHistory(
                    id: id,
                    generatedAt: generatedAt,
                    report: report,
                    totalApplications: Int(entity.totalApplications),
                    acceptedCount: Int(entity.acceptedCount),
                    acceptanceRate: entity.acceptanceRate
                )
            }
        } catch {
            print("Failed to fetch insight reports: \(error)")
        }
    }
    
    func save(report: InsightReport) throws {
        _ = try saveAndReturn(report: report)
    }
    
    func saveAndReturn(report: InsightReport) throws -> InsightReportHistory {
        let entity = InsightReportEntity(context: context)
        let id = UUID()
        entity.id = id
        entity.generatedAt = report.generatedAt
        entity.totalApplications = Int32(report.overallPerformance.totalCount)
        entity.acceptedCount = Int32(report.overallPerformance.acceptedCount)
        entity.acceptanceRate = report.overallPerformance.acceptanceRate
        
        let encoder = JSONEncoder()
        let reportData = try encoder.encode(report)
        entity.reportData = String(data: reportData, encoding: .utf8)
        
        try context.save()
        fetch()
        
        return InsightReportHistory(
            id: id,
            generatedAt: report.generatedAt,
            report: report,
            totalApplications: report.overallPerformance.totalCount,
            acceptedCount: report.overallPerformance.acceptedCount,
            acceptanceRate: report.overallPerformance.acceptanceRate
        )
    }
    
    func delete(id: UUID) throws {
        let request = InsightReportEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        
        try context.save()
        fetch()
    }
    
    func deleteAll() throws {
        let request = InsightReportEntity.fetchRequest()
        let entities = try context.fetch(request)
        
        for entity in entities {
            context.delete(entity)
        }
        
        try context.save()
        fetch()
    }
}

// 히스토리 뷰를 위한 래퍼 모델
struct InsightReportHistory: Identifiable {
    let id: UUID
    let generatedAt: Date
    let report: InsightReport
    let totalApplications: Int
    let acceptedCount: Int
    let acceptanceRate: Double
}
