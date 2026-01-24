//
//  AIProvider.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case claude = "Claude"
    // case chatgpt = "ChatGPT"
    // case gemini = "Gemini"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .claude:
            return "Claude (Anthropic)"
        // case .chatgpt:
        //     return "ChatGPT (OpenAI)"
        // case .gemini:
        //     return "Gemini (Google)"
        }
    }
    
    /// 현재 사용 가능한 AI 제공자 목록 (Claude만 활성화)
    static var availableProviders: [AIProvider] {
        [.claude]
    }
}
