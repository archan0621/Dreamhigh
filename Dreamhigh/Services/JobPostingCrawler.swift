//
//  JobPostingCrawler.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/24/26.
//

import Foundation

enum CrawlerError: Error {
    case invalidURL
    case unsupportedSite
    case networkError
    case parsingError
    case notImplemented
}

final class JobPostingCrawler {
    static let shared = JobPostingCrawler()
    
    private init() {}
    
    /// 채용공고 URL에서 텍스트 내용을 크롤링
    func crawl(_ urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw CrawlerError.invalidURL
        }
        
        // HTTP 요청으로 HTML 가져오기
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            // DNS 조회 실패 등 네트워크 에러 처리
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotFindHost, .cannotConnectToHost:
                    throw CrawlerError.networkError
                case .timedOut:
                    throw CrawlerError.networkError
                default:
                    throw CrawlerError.networkError
                }
            }
            throw CrawlerError.networkError
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CrawlerError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CrawlerError.networkError
        }
        
        // HTML을 문자열로 변환
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw CrawlerError.parsingError
        }
        
        // 기본적인 텍스트 추출 (script, style 태그 제거)
        let cleanedText = cleanHTML(htmlString)
        
        return cleanedText
    }
    
    /// HTML에서 텍스트만 추출 (기본 버전)
    private func cleanHTML(_ html: String) -> String {
        var text = html
        
        // script 태그 제거
        text = text.replacingOccurrences(
            of: #"<script[^>]*>.*?</script>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // style 태그 제거
        text = text.replacingOccurrences(
            of: #"<style[^>]*>.*?</style>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // HTML 태그 제거
        text = text.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: " ",
            options: .regularExpression
        )
        
        // HTML 엔티티 디코딩
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        
        // 연속된 공백 정리
        text = text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 지원 사이트인지 확인
    func isSupportedSite(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return false
        }
        
        // 지원하는 사이트 목록
        let supportedDomains = [
            "jobkorea.co.kr",
            "saramin.co.kr",
            "wanted.co.kr",
            "programmers.co.kr",
            "rocketpunch.com",
            "jobplanet.co.kr"
        ]
        
        return supportedDomains.contains { host.contains($0) }
    }
}
