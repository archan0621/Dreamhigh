import SwiftUI

struct EditableMarkdownView: View {
    @Binding var content: String
    let onContentChange: (String) -> Void
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isEditing {
                // 편집 모드: 전체 마크다운을 TextEditor로 표시
                VStack(spacing: 0) {
                    TextEditor(text: $content)
                        .font(.system(.body))
                        .frame(minHeight: 400)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isFocused)
                        .onChange(of: content) { oldValue, newValue in
                            // 실시간 저장은 하지 않고, 보기 모드로 전환할 때만 저장
                        }
                        .onAppear {
                            isFocused = true
                        }
                }
                .background(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    // TextEditor 외부 여백 클릭 시 보기 모드로 전환
                    onContentChange(content)
                    isEditing = false
                }
                .onChange(of: isFocused) { oldValue, newValue in
                    // 포커스를 잃으면 보기 모드로 전환
                    if !newValue && isEditing {
                        onContentChange(content)
                        isEditing = false
                    }
                }
            } else {
                // 보기 모드: MarkdownView로 표시 (이미지 사이즈 조절 포함)
                MarkdownView(content: content) { url, alt, newWidth in
                    updateImageWidthInContent(url: url, alt: alt, newWidth: newWidth)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .contentShape(Rectangle())
                .onTapGesture {
                    // 보기 모드에서 클릭하면 편집 모드로 전환
                    isEditing = true
                }
            }
            
            // 편집/보기 모드 전환 버튼
            Button {
                if isEditing {
                    // 편집 모드 종료 시 저장
                    onContentChange(content)
                }
                isEditing.toggle()
            } label: {
                Label(isEditing ? "보기" : "편집", systemImage: isEditing ? "eye" : "pencil")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(8)
        }
    }
    
    private func updateImageWidthInContent(url: String, alt: String?, newWidth: CGFloat) {
        // 마크다운에서 해당 이미지를 찾아서 width 정보 업데이트
        let lines = content.components(separatedBy: .newlines)
        var updatedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            var updatedLine = line
            
            // 이미지 마크다운 패턴: ![alt](url) 또는 ![alt](url){width=600}
            if trimmed.contains(url) && (trimmed.hasPrefix("![") || trimmed.contains("![") && trimmed.contains("](")) {
                // 기존 width 정보 제거
                updatedLine = updatedLine.replacingOccurrences(of: #"\{width=\d+\}"#, with: "", options: .regularExpression)
                
                // 새 width 정보 추가
                if updatedLine.hasSuffix(")") {
                    updatedLine += "{width=\(Int(newWidth))}"
                } else {
                    updatedLine = updatedLine.trimmingCharacters(in: .whitespaces)
                    if !updatedLine.hasSuffix(")") {
                        updatedLine += ")"
                    }
                    updatedLine += "{width=\(Int(newWidth))}"
                }
            }
            
            updatedLines.append(updatedLine)
        }
        
        let newContent = updatedLines.joined(separator: "\n")
        content = newContent
        onContentChange(newContent)
    }
}
