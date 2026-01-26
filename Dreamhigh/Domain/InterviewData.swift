//
//  InterviewData.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/25/26.
//

import Foundation

/// 면접 전형별 데이터
struct InterviewData: Codable, Equatable {
    /// 코딩테스트/과제 전형 데이터
    let codingOrAssignment: InterviewTypeData?
    
    /// 기술 면접 데이터
    let technical: InterviewTypeData?
    
    /// 인성 면접 데이터
    let personality: InterviewTypeData?
}

/// 특정 면접 전형의 데이터
struct InterviewTypeData: Codable, Equatable {
    /// 회고 텍스트
    let reflection: String?
    
    /// 질문 목록
    let questions: [InterviewQuestion]
}

/// 면접 질문
struct InterviewQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    let question: String
    let answer: String?
    let interviewType: String // "codingOrAssignment", "technical", "personality"
    let tags: [String]
    let notes: String?
    let createdAt: Date
}
