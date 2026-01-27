//
//  InsightReport.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/25/26.
//

import Foundation

/// AI 인사이트 리포트 분석 결과
struct InsightReport: Codable {
    /// 종합 성과 요약
    let overallPerformance: OverallPerformance
    /// 합격/불합격 패턴 분석
    let patterns: PatternAnalysis
    /// 이력서 버전 및 전략 분석
    let resumeStrategy: ResumeStrategyAnalysis
    /// 이력서 레벨 및 JD 적합도
    let resumeLevelAndJD: ResumeLevelAndJD
    /// 기술 스택 최적화 제안
    let techStackOptimization: TechStackOptimization
    /// 전략적 액션 아이템
    let actionPlan: ActionPlan
    /// 리포트 생성일
    let generatedAt: Date
}

struct OverallPerformance: Codable {
    /// 전체 합격률 (0-100)
    let acceptanceRate: Double
    /// 합격 건수
    let acceptedCount: Int
    /// 전체 지원 건수
    let totalCount: Int
    /// 전형 단계별 통계
    let stageStats: StageStats?
    /// 주요 성과 요약 (3-5개)
    let keyFindings: [String]
}

struct StageStats: Codable {
    let document: StageResult
    let techInterview: StageResult
    let cultureInterview: StageResult
}

struct StageResult: Codable {
    let passed: Int
    let rate: Double
}

struct PatternAnalysis: Codable {
    /// 합격 케이스의 공통점
    let acceptedPatterns: [PatternDetail]
    /// 불합격 케이스의 공통점
    let rejectedPatterns: [PatternDetail]
}

struct PatternDetail: Codable {
    let category: String // "회사 유형", "기술 스택", "포지션" 등
    let value: String
    let description: String
}

struct ResumeStrategyAnalysis: Codable {
    /// 버전별 성과 분석
    let versionPerformance: [VersionPerformance]
    /// 콘텐츠 스타일 유효성
    let styleEffectiveness: [StyleEffectiveness]
    /// 회사군별 이력서 적합도
    let companyGroupFit: [CompanyGroupFit]
}

struct VersionPerformance: Codable {
    let versionName: String
    let documentPassRate: Double // 서류 통과율 (0-100)
    let interviewEntryRate: Double // 면접 진입률 (0-100)
    let status: String // "BEST", "NORMAL", "NEEDS_IMPROVEMENT"
}

struct StyleEffectiveness: Codable {
    let style: String // "임팩트 중심", "기술 중심", "스토리 중심"
    let effectiveness: String // "매우 높음", "높음", "보통", "낮음"
    let description: String
}

struct CompanyGroupFit: Codable {
    let companyGroup: String // "대기업", "스타트업", "플랫폼", "커머스" 등
    let fitLevel: String // "높음", "보통", "낮음"
    let description: String
}

struct ResumeLevelAndJD: Codable {
    /// 페르소나 레벨 평가
    let personaLevel: PersonaLevel
    /// JD 정렬 상태
    let jdAlignment: [JDAlignmentItem]
}

struct PersonaLevel: Codable {
    let perceivedLevel: String // "시니어", "중급", "주니어" 등
    let targetPosition: String // "시니어 / 리드" 등
    let description: String
}

struct JDAlignmentItem: Codable {
    let type: String // "Overqualified", "Underqualified", "Misaligned"
    let count: Int
    let description: String
}

struct TechStackOptimization: Codable {
    /// 실제 평가에 도움 안 되는 기술
    let unhelpfulTechs: [String]
    /// 기술적 허영으로 오해될 요소
    let vanityTechs: [String]
    /// 빠졌을 때 더 좋아질 항목
    let shouldRemove: [String]
    /// 전문가 팁
    let expertTip: String
}

struct ActionPlan: Codable {
    let phases: [ActionPhase]
}

struct ActionPhase: Codable {
    let phase: String // "Phase 1", "Phase 2", "Phase 3"
    let title: String
    let tasks: [String]
}
