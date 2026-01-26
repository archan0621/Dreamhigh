//
//  SettingsView.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var settingsStore = SettingsStore.shared
    let context: NSManagedObjectContext
    
    init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    var body: some View {
        TabView {
            AISettingsView(context: context)
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
        }
        .frame(width: 700, height: 550)
    }
}

struct AISettingsView: View {
    let context: NSManagedObjectContext
    @ObservedObject var settingsStore: SettingsStore
    @StateObject private var tokenUsageStore: TokenUsageStore
    @State private var isTokenVisible = false
    @FocusState private var isTokenFieldFocused: Bool
    
    init(context: NSManagedObjectContext) {
        self.context = context
        _settingsStore = ObservedObject(wrappedValue: SettingsStore.shared)
        _tokenUsageStore = StateObject(wrappedValue: TokenUsageStore(context: context))
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
            
            // 토큰 사용량 통계
            if settingsStore.isAIConfigured {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("총 토큰 사용량")
                                    .font(.headline)
                                Text("\(formatNumber(tokenUsageStore.totalTokens)) tokens")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.accentColor)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("예상 비용")
                                    .font(.headline)
                                Text("$\(String(format: "%.4f", tokenUsageStore.totalEstimatedCost))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Input")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(formatNumber(tokenUsageStore.totalInputTokens)) tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Output")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(formatNumber(tokenUsageStore.totalOutputTokens)) tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Divider()
                        
                        Text("서비스별 사용량")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            serviceUsageRow(service: "채용공고 분석")
                            serviceUsageRow(service: "이력서 피드백")
                            serviceUsageRow(service: "인사이트 리포트")
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("토큰 사용 통계")
                } footer: {
                    Text("Claude Sonnet 4.5 기준 (Input: $3/M tokens, Output: $15/M tokens)")
                        .font(.caption2)
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
        .onAppear {
            tokenUsageStore.fetch()
        }
    }
    
    private func serviceUsageRow(service: String) -> some View {
        let stats = tokenUsageStore.serviceStats(for: service)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service)
                    .font(.subheadline)
                Text("\(stats.count)회 호출")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatNumber(stats.inputTokens + stats.outputTokens)) tokens")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("$\(String(format: "%.4f", stats.cost))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
