//
//  SettingsStore.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @Published var isSettingsWindowPresented = false
    @Published var selectedAIProvider: AIProvider? = nil {
        didSet {
            if let provider = selectedAIProvider {
                loadToken(for: provider)
                // 제공자 변경 시 해당 제공자의 기본 모델 설정
                if let defaultModel = AIModel.models(for: provider).first {
                    selectedAIModel = defaultModel
                }
            } else {
                apiToken = ""
                selectedAIModel = nil
            }
            saveProvider()
        }
    }
    @Published var apiToken: String = "" {
        didSet {
            if let provider = selectedAIProvider {
                saveToken(for: provider)
            }
        }
    }
    @Published var selectedAIModel: AIModel? = nil {
        didSet {
            saveModel()
        }
    }
    
    private let keychain = KeychainManager.shared
    private let userDefaults = UserDefaults.standard
    private let providerKey = "selectedAIProvider"
    private let modelKey = "selectedAIModel"
    
    private init() {
        loadProvider()
        loadModel()
    }
    
    private func loadProvider() {
        if let providerRawValue = userDefaults.string(forKey: providerKey),
           let provider = AIProvider(rawValue: providerRawValue) {
            selectedAIProvider = provider
        }
    }
    
    private func saveProvider() {
        if let provider = selectedAIProvider {
            userDefaults.set(provider.rawValue, forKey: providerKey)
        } else {
            userDefaults.removeObject(forKey: providerKey)
        }
    }
    
    private func loadModel() {
        if let modelRawValue = userDefaults.string(forKey: modelKey),
           let model = AIModel(rawValue: modelRawValue) {
            selectedAIModel = model
        } else if let provider = selectedAIProvider,
                  let defaultModel = AIModel.models(for: provider).first {
            // 기본 모델 설정 (첫 번째 모델)
            selectedAIModel = defaultModel
        }
    }
    
    private func saveModel() {
        if let model = selectedAIModel {
            userDefaults.set(model.rawValue, forKey: modelKey)
        } else {
            userDefaults.removeObject(forKey: modelKey)
        }
    }
    
    private func loadToken(for provider: AIProvider) {
        let key = "apiToken_\(provider.rawValue)"
        apiToken = keychain.load(key: key) ?? ""
    }
    
    private func saveToken(for provider: AIProvider) {
        let key = "apiToken_\(provider.rawValue)"
        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedToken.isEmpty {
            keychain.delete(key: key)
        } else {
            _ = keychain.save(key: key, value: trimmedToken)
        }
    }
    
    var hasValidToken: Bool {
        !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isAIConfigured: Bool {
        selectedAIProvider != nil && hasValidToken
    }
}
