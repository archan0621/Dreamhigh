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
    let jobPostingURL: String? // 채용공고 링크
    let content: String
    let structuredJobPosting: StructuredJobPosting? // 분석된 채용공고 정보
}
