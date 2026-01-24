//
//  AIPrompts.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

enum AIPrompts {
    /// 채용공고 구조화 프롬프트
    static func structureJobPosting(_ jobPostingText: String) -> String {
        """
        다음 채용공고 텍스트를 구조화된 JSON 형식으로 변환해주세요.
        다음 필드들을 추출해주세요:
        - companyName: 회사명
        - position: 포지션/직무명
        - requirements: 필수 요구사항 (배열)
        - preferredQualifications: 우대사항 (배열)
        - location: 근무지
        - description: 상세 설명
        - employmentType: 채용 형태 (정규직, 계약직, 인턴, 파트타임 등)
        - experienceLevel: 경력 요구사항 (신입, 경력, 경력 무관, N년차 이상 등)
        - techStack: 기술 스택 (배열, 예: ["Swift", "SwiftUI", "iOS"] 등)
        - workType: 근무 형태 (재택근무, 출근근무, 하이브리드 등)
        - deadline: 마감일 (있는 경우)
        
        각 필드는 해당 정보가 없으면 null로 설정하세요.
        JSON 형식으로만 응답해주세요. 다른 설명은 포함하지 마세요.
        
        채용공고 텍스트:
        \(jobPostingText)
        """
    }
}
