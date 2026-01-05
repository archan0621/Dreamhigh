//
//  ApplyHistoryStore.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/2/26.
//

import Foundation
import CoreData
import Combine

@MainActor
final class ApplyHistoryStore : ObservableObject {
    @Published private(set) var items: [ApplyHistory] = []
    
    private let context : NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetch() {
        let request = ApplyHistoryEntity.fetchRequest()
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "appliedAt", ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            
            self.items = entities.map { entity in
                // resumeId를 UUID로 파싱 (없으면 nil)
                let resumeVersionId: UUID? = {
                    if let resumeIdString = entity.resumeId, !resumeIdString.isEmpty,
                       let uuid = UUID(uuidString: resumeIdString) {
                        return uuid
                    }
                    return nil
                }()
                
                return ApplyHistory(
                    id: entity.id!,
                    companyName: entity.company ?? "",
                    appliedAt: entity.appliedAt ?? Date(),
                    category: entity.category ?? "",
                    documentStatus: entity.docStatus ?? "",
                    techInterviewStatus: entity.techInterview ?? "",
                    cultureInterviewStatus: entity.cultureInterview ?? "",
                    resumeId: entity.resumeId ?? "",
                    resumeVersionId: resumeVersionId,
                    content: entity.content ?? ""
                )
            }
            
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func create(
        companyName: String,
        appliedAt: Date,
        category: String,
        documentStatus: String,
        techInterviewStatus: String,
        cultureInterviewStatus: String,
        resumeId: String
    ) {
        let entity = ApplyHistoryEntity(context: context)
        entity.id = UUID()
        entity.company = companyName
        entity.appliedAt = appliedAt
        entity.category = category
        entity.docStatus = documentStatus
        entity.techInterview = techInterviewStatus
        entity.cultureInterview = cultureInterviewStatus
        entity.resumeId = resumeId
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        do {
            try context.save()
            fetch()
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func update(
        id: UUID,
        companyName: String,
        appliedAt: Date,
        category: String,
        documentStatus: String,
        techInterviewStatus: String,
        cultureInterviewStatus: String,
        resumeId: String,
        resumeVersionId: UUID? = nil
    ) {
        let request = ApplyHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                entity.company = companyName
                entity.appliedAt = appliedAt
                entity.category = category
                entity.docStatus = documentStatus
                entity.techInterview = techInterviewStatus
                entity.cultureInterview = cultureInterviewStatus
                // resumeVersionId가 있으면 UUID 문자열로 저장, 없으면 기존 resumeId 사용
                entity.resumeId = resumeVersionId?.uuidString ?? resumeId
                entity.updatedAt = Date()
                
                try context.save()
                fetch()
            }
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func updateResumeVersion(id: UUID, resumeVersionId: UUID?) {
        let request = ApplyHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                entity.resumeId = resumeVersionId?.uuidString ?? ""
                entity.updatedAt = Date()
                
                try context.save()
                fetch()
            }
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func updateContent(id: UUID, content: String) {
        let request = ApplyHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                entity.content = content
                entity.updatedAt = Date()
                
                try context.save()
                fetch()
            }
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func delete(ids: Set<UUID>) {
        let request = ApplyHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        
        do {
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
            try context.save()
            fetch()
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
}
