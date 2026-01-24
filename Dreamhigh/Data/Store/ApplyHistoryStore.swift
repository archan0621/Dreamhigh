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
                
                // 구조화된 채용공고 정보 파싱
                let structuredJobPosting: StructuredJobPosting? = {
                    guard let jsonData = entity.structuredJobPostingData?.data(using: .utf8) else {
                        return nil
                    }
                    return try? JSONDecoder().decode(StructuredJobPosting.self, from: jsonData)
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
                    jobPostingURL: entity.jobPostingURL,
                    content: entity.content ?? "",
                    structuredJobPosting: structuredJobPosting
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
        resumeVersionId: UUID? = nil,
        jobPostingURL: String? = nil
    ) {
        let entity = ApplyHistoryEntity(context: context)
        entity.id = UUID()
        entity.company = companyName
        entity.appliedAt = appliedAt
        entity.category = category
        entity.docStatus = documentStatus
        entity.techInterview = techInterviewStatus
        entity.cultureInterview = cultureInterviewStatus
        entity.resumeId = resumeVersionId?.uuidString ?? ""
        entity.jobPostingURL = jobPostingURL
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
        resumeVersionId: UUID? = nil,
        jobPostingURL: String? = nil
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
                entity.resumeId = resumeVersionId?.uuidString ?? ""
                entity.jobPostingURL = jobPostingURL
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
    
    func updateStructuredJobPosting(id: UUID, structuredJobPosting: StructuredJobPosting) {
        let request = ApplyHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                // StructuredJobPosting을 JSON으로 인코딩
                if let jsonData = try? JSONEncoder().encode(structuredJobPosting),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    entity.structuredJobPostingData = jsonString
                }
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
