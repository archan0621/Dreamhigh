//
//  ApplyHistory.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/2/26.
//

import Foundation

struct ApplyHistory: Identifiable {
    let id: UUID
    let companyName: String
    let appliedAt: Date
    let category: String
    let documentStatus: String
    let techInterviewStatus: String
    let cultureInterviewStatus: String
    let resumeId: String
    let resumeVersionId: UUID? // 이력서 버전 참조
    let content: String
}
