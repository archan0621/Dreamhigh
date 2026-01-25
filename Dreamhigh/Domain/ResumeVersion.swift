import Foundation

struct ResumeVersion: Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date
    let note: String // 메모
    let filePath: String // PDF 파일 경로
    let pageCount: Int
    let fileSize: Int64 // bytes
    let aiFeedback: ResumeFeedback? // AI 피드백
}

