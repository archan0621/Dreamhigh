//
//  ClaudeAIService.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

final class ClaudeAIService: AIServiceProtocol {
    private let apiKey: String
    private let model: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }
    
    func structureJobPosting(_ jobPostingText: String) async throws -> StructuredJobPosting {
        let prompt = AIPrompts.structureJobPosting(jobPostingText)
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version") // API 버전 (2026년 기준 최신)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIServiceError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw AIServiceError.invalidAPIKey
            }
            throw AIServiceError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ClaudeAPIResponse.self, from: data)
        
        guard let content = apiResponse.content.first?.text else {
            throw AIServiceError.invalidResponse
        }
        
        // JSON 추출 (마크다운 코드 블록 제거)
        let jsonString = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        
        let structuredPosting = try decoder.decode(StructuredJobPosting.self, from: jsonData)
        return structuredPosting
    }
}

// MARK: - Claude API Response Models

private struct ClaudeAPIResponse: Codable {
    let content: [ClaudeContent]
}

private struct ClaudeContent: Codable {
    let text: String
}

enum AIServiceError: Error {
    case notImplemented
    case invalidAPIKey
    case networkError
    case invalidResponse
}
