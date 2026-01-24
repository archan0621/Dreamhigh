//
//  AIServiceProtocol.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

/// AI 서비스의 공통 인터페이스 프로토콜
protocol AIServiceProtocol {
    /// 채용공고 원문을 구조화된 데이터로 변환
    /// - Parameter jobPostingText: 크롤링된 채용공고 원문
    /// - Returns: 구조화된 채용공고 정보
    func structureJobPosting(_ jobPostingText: String) async throws -> StructuredJobPosting
}

/// 구조화된 채용공고 정보
struct StructuredJobPosting: Codable {
    let companyName: String?
    let position: String?
    let requirements: [String]?
    let preferredQualifications: [String]?
    let location: String?
    let description: String?
    let employmentType: String? // 채용 형태 (정규직, 계약직, 인턴 등)
    let experienceLevel: String? // 경력 요구사항 (신입, 경력, 경력 무관 등)
    let techStack: [String]? // 기술 스택
    let workType: String? // 근무 형태 (재택, 출근, 하이브리드 등)
    let deadline: String? // 마감일
}
