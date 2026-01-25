//
//  ResumeFeedback.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/25/26.
//

import Foundation

/// AI가 생성한 이력서 피드백
struct ResumeFeedback: Codable, Equatable, Hashable {
    /// 전반적인 평가 (0-100점)
    let overallScore: Int
    
    /// 첫인상 (3-5줄 요약)
    let firstImpression: String
    
    /// 강점 목록 (기술적 강점, 사고방식/태도 강점, 차별점)
    let strengths: [String]
    
    /// 개선점 및 약점 목록
    let improvements: [String]
    
    /// 면접 예상 질문 목록
    let interviewQuestions: [String]
    
    /// 섹션별 피드백
    let sectionFeedback: [SectionFeedback]
    
    /// 총평 (1-2줄, CTO가 내부 공유용으로 남길 법한 문장)
    let summary: String
    
    /// 생성 일시
    let generatedAt: Date
}

/// 섹션별 피드백
struct SectionFeedback: Codable, Equatable, Hashable {
    /// 섹션 이름 (예: "경력", "학력", "프로젝트", "기술 스택")
    let sectionName: String
    
    /// 점수 (0-100)
    let score: Int
    
    /// 피드백 내용
    let feedback: String
}
