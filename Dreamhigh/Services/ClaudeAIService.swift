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
    
    func analyzeResume(pdfPath: String) async throws -> ResumeFeedback {
        // PDF를 base64로 인코딩
        guard let pdfData = try? Data(contentsOf: URL(fileURLWithPath: pdfPath)) else {
            throw AIServiceError.invalidResponse
        }
        
        let base64PDF = pdfData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "document",
                            "source": [
                                "type": "base64",
                                "media_type": "application/pdf",
                                "data": base64PDF
                            ]
                        ],
                        [
                            "type": "text",
                            "text": AIPrompts.reviewResume
                        ]
                    ]
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
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 120 // 2분 타임아웃
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIServiceError.invalidResponse
        }
        
        // 타임아웃 설정이 있는 URLSession 사용
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 180
        let session = URLSession(configuration: configuration)
        
        let (data, response) = try await session.data(for: request)
        
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
        decoder.dateDecodingStrategy = .iso8601
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
        
        // ResumeFeedback 디코딩 (generatedAt 제외)
        var feedback = try decoder.decode(ResumeFeedbackResponse.self, from: jsonData)
        
        return ResumeFeedback(
            overallScore: feedback.overallScore,
            firstImpression: feedback.firstImpression,
            strengths: feedback.strengths,
            improvements: feedback.improvements,
            interviewQuestions: feedback.interviewQuestions,
            sectionFeedback: feedback.sectionFeedback,
            summary: feedback.summary,
            generatedAt: Date()
        )
    }
}

// MARK: - Response Models

/// AI 응답에서 받는 ResumeFeedback (generatedAt 제외)
private struct ResumeFeedbackResponse: Codable {
    let overallScore: Int
    let firstImpression: String
    let strengths: [String]
    let improvements: [String]
    let interviewQuestions: [String]
    let sectionFeedback: [SectionFeedback]
    let summary: String
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
