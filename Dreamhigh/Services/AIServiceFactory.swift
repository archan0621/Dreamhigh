//
//  AIServiceFactory.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

final class AIServiceFactory {
    static func createService(provider: AIProvider, apiKey: String, model: String) -> AIServiceProtocol? {
        switch provider {
        case .claude:
            return ClaudeAIService(apiKey: apiKey, model: model)
        // case .chatgpt:
        //     // TODO: ChatGPT 구현체 추가
        //     return nil
        // case .gemini:
        //     // TODO: Gemini 구현체 추가
        //     return nil
        }
    }
    
    static func createServiceFromSettings() -> AIServiceProtocol? {
        let settingsStore = SettingsStore.shared
        
        guard let provider = settingsStore.selectedAIProvider,
              let model = settingsStore.selectedAIModel,
              settingsStore.hasValidToken else {
            return nil
        }
        
        return createService(provider: provider, apiKey: settingsStore.apiToken, model: model.rawValue)
    }
}
