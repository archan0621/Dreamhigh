//
//  PDFManager.swift
//  Dreamhigh
//
//  Created by 박종하 on 1/2/26.
//

import Foundation

final class PDFManager {
    static let shared = PDFManager()
    
    private let pdfsDirectory: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        pdfsDirectory = documentsPath.appendingPathComponent("DreamhighPDFs", isDirectory: true)
        
        // 디렉토리 생성
        if !FileManager.default.fileExists(atPath: pdfsDirectory.path) {
            try? FileManager.default.createDirectory(at: pdfsDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// PDF 파일을 앱의 Documents 폴더로 복사하고 경로를 반환
    func savePDF(from sourceURL: URL, for versionId: UUID) -> String? {
        let fileName = "\(versionId.uuidString).pdf"
        let destinationURL = pdfsDirectory.appendingPathComponent(fileName)
        
        // 보안 스코프 리소스 접근
        let hasAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // 기존 파일이 있으면 삭제
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // 파일 복사
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            return destinationURL.path
        } catch {
            return nil
        }
    }
    
    /// PDF 파일 로드
    func loadPDF(from path: String) -> URL? {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        return nil
    }
    
    /// PDF 파일 삭제
    func deletePDF(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }
}

