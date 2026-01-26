//
//  TokenUsage.swift
//  Dreamhigh
//
//  Created by AI on 1/26/26.
//

import Foundation

struct TokenUsage: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let service: String // "채용공고 분석", "이력서 피드백", "인사이트 리포트"
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    
    var totalInputTokens: Int {
        inputTokens + cacheCreationTokens + cacheReadTokens
    }
    
    var totalTokens: Int {
        totalInputTokens + outputTokens
    }
    
    // 대략적인 비용 계산 (Claude Sonnet 4.5 기준)
    // Input: $3 per million tokens
    // Output: $15 per million tokens
    var estimatedCost: Double {
        let inputCost = Double(totalInputTokens) / 1_000_000.0 * 3.0
        let outputCost = Double(outputTokens) / 1_000_000.0 * 15.0
        return inputCost + outputCost
    }
}
