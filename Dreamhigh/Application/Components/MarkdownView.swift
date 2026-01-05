import SwiftUI

struct MarkdownView: View {
    let content: String
    var onImageWidthChange: ((String, String?, CGFloat) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(parseMarkdown(content).enumerated()), id: \.offset) { index, block in
                if case .image(let url, let alt, let width) = block {
                    ResizableImageBlockView(
                        url: url,
                        alt: alt,
                        initialWidth: width ?? 600,
                        onWidthChange: { newWidth in
                            onImageWidthChange?(url, alt, newWidth)
                        }
                    )
                } else {
                    block.view
                }
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var currentParagraph: [String] = []
        var inCodeBlock = false
        var codeBlockLines: [String] = []
        
        // 이미지 패턴: ![alt](url)
        let imagePattern = #"!\[([^\]]*)\]\(([^\)]+)\)"#
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // 코드 블록 종료
                    blocks.append(.codeBlock(codeBlockLines.joined(separator: "\n")))
                    codeBlockLines = []
                    inCodeBlock = false
                } else {
                    // 코드 블록 시작
                    if !currentParagraph.isEmpty {
                        blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                        currentParagraph = []
                    }
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                codeBlockLines.append(line)
                continue
            }
            
            // 이미지가 단독으로 있는 경우 (라인 전체가 이미지 마크다운인 경우)
            if trimmed.matches(pattern: imagePattern) {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                // 이미지 파싱
                if let regex = try? NSRegularExpression(pattern: imagePattern),
                   let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)),
                   let altRange = Range(match.range(at: 1), in: trimmed),
                   let urlRange = Range(match.range(at: 2), in: trimmed) {
                                let alt = String(trimmed[altRange])
                                let url = String(trimmed[urlRange])
                                let width = parseImageWidth(from: trimmed)
                                blocks.append(.image(url, alt: alt.isEmpty ? nil : alt, width: width))
                            }
                continue
            }
            
            if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                continue
            }
            
                        // 이미지 파일 경로 감지 (단독 라인에 이미지 확장자가 있는 경우)
                        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tiff", ".webp"]
                        if imageExtensions.contains(where: { trimmed.lowercased().hasSuffix($0) }) {
                            // 파일 경로인지 확인 (공백이 없고 / 또는 ~로 시작하거나 dreamhigh://로 시작)
                            if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") || trimmed.hasPrefix("dreamhigh://") {
                                if !currentParagraph.isEmpty {
                                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                                    currentParagraph = []
                                }
                                let width = parseImageWidth(from: trimmed)
                                blocks.append(.image(trimmed, alt: nil, width: width))
                                continue
                            }
                        }
            
            if trimmed.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading(String(trimmed.dropFirst(2)), level: 1))
            } else if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading(String(trimmed.dropFirst(3)), level: 2))
            } else if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.heading(String(trimmed.dropFirst(4)), level: 3))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    blocks.append(.paragraph(currentParagraph.joined(separator: " ")))
                    currentParagraph = []
                }
                blocks.append(.bullet(String(trimmed.dropFirst(2))))
            } else {
                currentParagraph.append(line)
            }
        }
        
        if inCodeBlock && !codeBlockLines.isEmpty {
            blocks.append(.codeBlock(codeBlockLines.joined(separator: "\n")))
        }
        
        if !currentParagraph.isEmpty {
            blocks.append(.paragraph(currentParagraph.joined(separator: "\n")))
        }
        
        return blocks.isEmpty ? [.paragraph(text)] : blocks
    }
    
    private func parseImageWidth(from text: String) -> CGFloat? {
        // {width=600} 형식 파싱
        let widthPattern = #"\{width=(\d+)\}"#
        if let regex = try? NSRegularExpression(pattern: widthPattern),
           let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
           let widthRange = Range(match.range(at: 1), in: text),
           let width = Double(String(text[widthRange])) {
            return CGFloat(width)
        }
        return nil
    }
}

extension String {
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: utf16.count)
        return regex.firstMatch(in: self, range: range) != nil
    }
}

enum MarkdownBlock: Identifiable {
    case heading(String, level: Int)
    case paragraph(String)
    case bullet(String)
    case codeBlock(String)
    case image(String, alt: String?, width: CGFloat?)
    
    var id: String {
        switch self {
        case .heading(let text, let level):
            return "h\(level)-\(text.prefix(10))"
        case .paragraph(let text):
            return "p-\(text.prefix(10))"
        case .bullet(let text):
            return "b-\(text.prefix(10))"
        case .codeBlock(let text):
            return "c-\(text.prefix(10))"
            case .image(let url, let alt, let width):
                return "img-\(url.prefix(10))-\(alt?.prefix(5) ?? "")-\(width ?? 0)"
        }
    }
    
    var view: some View {
        Group {
            switch self {
            case .heading(let text, let level):
                Text(parseMarkdown(text))
                    .font(level == 1 ? .title : level == 2 ? .title2 : .title3)
                    .fontWeight(.bold)
                    .padding(.vertical, 4)
            case .paragraph(let text):
                parseParagraphWithImages(text)
            case .bullet(let text):
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    parseParagraphWithImages(text)
                }
                .padding(.vertical, 2)
            case .codeBlock(let text):
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            case .image(let url, let alt, let width):
                ResizableImageBlockView(
                    url: url,
                    alt: alt,
                    initialWidth: width ?? 600,
                    onWidthChange: { newWidth in
                        // 크기 변경 시 마크다운 업데이트는 EditableMarkdownView에서 처리
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder
    private func parseParagraphWithImages(_ text: String) -> some View {
        let parts = splitTextAndImages(text)
        if parts.count == 1, case .text(let t) = parts[0] {
            Text(parseMarkdown(t))
                .font(.body)
                .lineSpacing(4)
                .padding(.vertical, 2)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    switch part {
                    case .text(let t):
                        Text(parseMarkdown(t))
                            .font(.body)
                            .lineSpacing(4)
                    case .image(let url, let alt):
                        Group {
                            if let image = ImageManager.shared.loadImage(from: url) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 600)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            } else {
                                HStack {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(alt ?? "이미지")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(url)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding()
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private enum TextPart {
        case text(String)
        case image(String, alt: String?)
    }
    
    private func splitTextAndImages(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        let imagePattern = #"!\[([^\]]*)\]\(([^\)]+)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: imagePattern) else {
            return [.text(text)]
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        var lastIndex = 0
        for match in matches {
            // 이미지 앞의 텍스트
            if match.range.location > lastIndex {
                let textRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                let textPart = nsString.substring(with: textRange)
                if !textPart.isEmpty {
                    parts.append(.text(textPart))
                }
            }
            
            // 이미지
            if let altRange = Range(match.range(at: 1), in: text),
               let urlRange = Range(match.range(at: 2), in: text) {
                let alt = String(text[altRange])
                let url = String(text[urlRange])
                parts.append(.image(url, alt: alt.isEmpty ? nil : alt))
            }
            
            lastIndex = match.range.location + match.range.length
        }
        
        // 마지막 텍스트
        if lastIndex < nsString.length {
            let textPart = nsString.substring(from: lastIndex)
            if !textPart.isEmpty {
                parts.append(.text(textPart))
            }
        }
        
        return parts.isEmpty ? [.text(text)] : parts
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        if let attributedString = try? AttributedString(markdown: text) {
            return attributedString
        }
        return AttributedString(text)
    }
    
    private func parseImageWidth(from text: String) -> CGFloat? {
        // {width=600} 형식 파싱
        let widthPattern = #"\{width=(\d+)\}"#
        if let regex = try? NSRegularExpression(pattern: widthPattern),
           let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
           let widthRange = Range(match.range(at: 1), in: text),
           let width = Double(String(text[widthRange])) {
            return CGFloat(width)
        }
        return nil
    }
}

struct ResizableImageBlockView: View {
    let url: String
    let alt: String?
    let initialWidth: CGFloat
    let onWidthChange: ((CGFloat) -> Void)?
    
    @State private var width: CGFloat
    @State private var dragStartWidth: CGFloat = 0
    
    init(url: String, alt: String?, initialWidth: CGFloat, onWidthChange: ((CGFloat) -> Void)? = nil) {
        self.url = url
        self.alt = alt
        self.initialWidth = initialWidth
        self.onWidthChange = onWidthChange
        _width = State(initialValue: initialWidth)
    }
    
    var body: some View {
        Group {
            if let image = ImageManager.shared.loadImage(from: url) {
                HStack(spacing: 0) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // 리사이즈 핸들
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(width: 8)
                        .frame(height: min(80, max(60, width * 0.2)))
                        .cornerRadius(4)
                        .padding(.leading, 4)
                        .allowsHitTesting(true)
                        .cursor(.resizeLeftRight)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if dragStartWidth == 0 {
                                        dragStartWidth = width
                                    }
                                    
                                    let delta = value.translation.width
                                    let newWidth = max(100, min(1200, dragStartWidth + delta))
                                    width = newWidth
                                }
                                .onEnded { _ in
                                    dragStartWidth = 0
                                    onWidthChange?(width)
                                }
                        )
                }
            } else {
                HStack {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alt ?? "이미지")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(url)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

