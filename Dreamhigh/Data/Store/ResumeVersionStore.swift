//
//  ResumeVersionStore.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/2/26.
//

import Foundation
import CoreData
import Combine

@MainActor
final class ResumeVersionStore: ObservableObject {
    @Published private(set) var versions: [ResumeVersion] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetch()
    }
    
    func fetch() {
        let request = ResumeVersionEntity.fetchRequest()
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        do {
            let entities = try context.fetch(request)
            
            self.versions = entities.map { entity in
                ResumeVersion(
                    id: entity.id!,
                    name: entity.name ?? "",
                    createdAt: entity.createdAt ?? Date(),
                    note: entity.note ?? "",
                    filePath: entity.filePath ?? "",
                    pageCount: Int(entity.pageCount),
                    fileSize: entity.fileSize
                )
            }
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func create(
        id: UUID,
        name: String,
        createdAt: Date,
        note: String,
        filePath: String,
        pageCount: Int,
        fileSize: Int64
    ) {
        let entity = ResumeVersionEntity(context: context)
        entity.id = id
        entity.name = name
        entity.createdAt = createdAt
        entity.note = note
        entity.filePath = filePath
        entity.pageCount = Int16(pageCount)
        entity.fileSize = fileSize
        
        do {
            try context.save()
            fetch()
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func update(
        id: UUID,
        name: String,
        note: String
    ) {
        let request = ResumeVersionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                entity.name = name
                entity.note = note
                
                try context.save()
                fetch()
            }
        } catch {
            // 에러 처리 (필요시 로깅 시스템으로 대체)
        }
    }
    
    func delete(ids: Set<UUID>) {
        let request = ResumeVersionEntity.fetchRequest()
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
    
    func getVersion(by id: UUID) -> ResumeVersion? {
        return versions.first { $0.id == id }
    }
    
    func getAllVersions() -> [ResumeVersion] {
        return versions
    }
}

