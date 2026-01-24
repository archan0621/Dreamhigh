//
//  SettingsView.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsStore = SettingsStore.shared
    
    var body: some View {
        TabView {
            AISettingsView()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
        }
        .frame(width: 600, height: 400)
    }
}

struct AISettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var isTokenVisible = false
    @FocusState private var isTokenFieldFocused: Bool
    
    init() {
        _settingsStore = ObservedObject(wrappedValue: SettingsStore.shared)
    }
    
    var body: some View {
        Form {
            Section {
                Picker("AI Provider", selection: $settingsStore.selectedAIProvider) {
                    Text("선택 안함").tag(nil as AIProvider?)
                    ForEach(AIProvider.availableProviders) { provider in
                        Text(provider.displayName).tag(provider as AIProvider?)
                    }
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("AI 기능을 사용하려면 제공자를 선택하고 API 토큰을 입력하세요.")
            }
            
            if let selectedProvider = settingsStore.selectedAIProvider {
                Section {
                    Picker("Model", selection: $settingsStore.selectedAIModel) {
                        ForEach(AIModel.models(for: selectedProvider)) { model in
                            Text(model.displayName).tag(model as AIModel?)
                        }
                    }
                } header: {
                    Text("AI Model")
                } footer: {
                    Text("사용할 AI 모델을 선택하세요.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Group {
                                if isTokenVisible {
                                    TextField("API Token", text: $settingsStore.apiToken)
                                        .focused($isTokenFieldFocused)
                                } else {
                                    SecureField("API Token", text: $settingsStore.apiToken)
                                        .focused($isTokenFieldFocused)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            
                            Button {
                                isTokenVisible.toggle()
                            } label: {
                                Image(systemName: isTokenVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help(isTokenVisible ? "토큰 숨기기" : "토큰 보기")
                        }
                        
                        if settingsStore.hasValidToken {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text("토큰이 입력되었습니다")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("\(selectedProvider.displayName) API Token")
                } footer: {
                    if settingsStore.isAIConfigured {
                        Text("✅ AI 기능을 사용할 수 있습니다. 토큰은 Keychain에 안전하게 저장됩니다.")
                    } else {
                        Text("API 토큰을 입력하세요. 토큰은 Keychain에 안전하게 저장됩니다.")
                    }
                }
            } else {
                Section {
                    Text("AI 제공자를 선택하면 토큰 입력 필드가 표시됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            // 다른 여백 클릭 시 포커스 해제
            isTokenFieldFocused = false
        }
    }
}
