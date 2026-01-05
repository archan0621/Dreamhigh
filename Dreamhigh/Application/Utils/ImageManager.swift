import Foundation
import AppKit

final class ImageManager {
    static let shared = ImageManager()
    
    private let imagesDirectory: URL
    
    private init() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imagesDirectory = documentsPath.appendingPathComponent("DreamhighImages", isDirectory: true)
        
        // 디렉토리 생성
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// 이미지를 저장하고 상대 경로를 반환
    func saveImage(_ image: NSImage, for itemId: UUID) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let fileName = "\(itemId.uuidString)-\(UUID().uuidString).png"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        do {
            try pngData.write(to: fileURL)
            return "dreamhigh://images/\(fileName)"
        } catch {
            return nil
        }
    }
    
    /// URL에서 이미지 로드
    func loadImage(from path: String) -> NSImage? {
        // dreamhigh://images/ 형식의 경로 처리
        if path.hasPrefix("dreamhigh://images/") {
            let fileName = String(path.dropFirst("dreamhigh://images/".count))
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            return NSImage(contentsOf: fileURL)
        }
        
        // 직접 파일 경로인 경우
        if path.hasPrefix("/") {
            guard FileManager.default.fileExists(atPath: path) else {
                return nil
            }
            
            let fileURL = URL(fileURLWithPath: path)
            
            // Data를 통한 이미지 로드 시도
            if let imageData = try? Data(contentsOf: fileURL),
               let image = NSImage(data: imageData) {
                return image
            }
            
            // contentsOfFile 사용
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
            
            // URL을 통한 로드 시도
            return NSImage(contentsOf: fileURL)
        }
        
        // ~로 시작하는 홈 디렉토리 경로
        if path.hasPrefix("~") {
            let expandedPath = (path as NSString).expandingTildeInPath
            return NSImage(contentsOfFile: expandedPath)
        }
        
        // 일반 파일 URL 처리
        if let url = URL(string: path), url.isFileURL {
            return NSImage(contentsOf: url)
        }
        
        return nil
    }
    
    /// 파일 URL에서 이미지 저장
    func saveImage(from fileURL: URL, for itemId: UUID) -> String? {
        guard let image = NSImage(contentsOf: fileURL) else {
            return nil
        }
        return saveImage(image, for: itemId)
    }
}

