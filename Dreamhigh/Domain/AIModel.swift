//
//  AIModel.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

enum AIModel: String, CaseIterable, Identifiable {
    // Claude 4.5 시리즈 (2025년 최신)
    case claudeSonnet45 = "claude-sonnet-4-5-20250929"
    case claudeOpus45 = "claude-opus-4-5-20251101"
    case claudeHaiku45 = "claude-haiku-4-5-20251001"
    
    // Claude 3.5 시리즈 (이전 버전, 호환성 유지)
    case claudeSonnet35 = "claude-3-5-sonnet-20241022"
    case claudeOpus3 = "claude-3-opus-20240229"
    case claudeHaiku3 = "claude-3-haiku-20240307"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .claudeSonnet45:
            return "Claude Sonnet 4.5"
        case .claudeOpus45:
            return "Claude Opus 4.5"
        case .claudeHaiku45:
            return "Claude Haiku 4.5"
        case .claudeSonnet35:
            return "Claude Sonnet 3.5"
        case .claudeOpus3:
            return "Claude Opus 3"
        case .claudeHaiku3:
            return "Claude Haiku 3"
        }
    }
    
    var provider: AIProvider {
        switch self {
        case .claudeSonnet45, .claudeOpus45, .claudeHaiku45,
             .claudeSonnet35, .claudeOpus3, .claudeHaiku3:
            return .claude
        }
    }
    
    static func models(for provider: AIProvider) -> [AIModel] {
        switch provider {
        case .claude:
            // 최신 모델을 먼저 표시
            return [
                .claudeSonnet45,
                .claudeOpus45,
                .claudeHaiku45,
                .claudeSonnet35,
                .claudeOpus3,
                .claudeHaiku3
            ]
//        case .chatgpt:
//            return [] // TODO: ChatGPT 모델 추가
//        case .gemini:
//            return [] // TODO: Gemini 모델 추가
        }
    }
}
