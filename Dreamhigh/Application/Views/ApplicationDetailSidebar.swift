import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import CoreData

struct ApplicationDetailSidebar: View {
    let item: ApplyHistory
    @ObservedObject var store: ApplyHistoryStore
    let context: NSManagedObjectContext
    @StateObject private var resumeStore: ResumeVersionStore
    
    @State private var companyName: String
    @State private var appliedAt: Date
    @State private var selectedCategory: CompanyCategory?
    @State private var documentStatus: InterviewStatus?
    @State private var techInterviewStatus: InterviewStatus?
    @State private var cultureInterviewStatus: InterviewStatus?
    @State private var resumeId: String
    @State private var selectedResumeVersionId: UUID?
    @State private var content: String
    @State private var isEditingContent: Bool = false
    
    init(item: ApplyHistory, store: ApplyHistoryStore, context: NSManagedObjectContext) {
        self.item = item
        self.store = store
        self.context = context
        _resumeStore = StateObject(wrappedValue: ResumeVersionStore(context: context))
        _companyName = State(initialValue: item.companyName)
        _appliedAt = State(initialValue: item.appliedAt)
        _selectedCategory = State(initialValue: CompanyCategory.allCases.first { $0.rawValue == item.category })
        _documentStatus = State(initialValue: InterviewStatus.allCases.first { $0.rawValue == item.documentStatus })
        _techInterviewStatus = State(initialValue: InterviewStatus.allCases.first { $0.rawValue == item.techInterviewStatus })
        _cultureInterviewStatus = State(initialValue: InterviewStatus.allCases.first { $0.rawValue == item.cultureInterviewStatus })
        _resumeId = State(initialValue: item.resumeId)
        _selectedResumeVersionId = State(initialValue: item.resumeVersionId)
        _content = State(initialValue: item.content)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                VStack(alignment: .leading, spacing: 12) {
                    TextField("회사명", text: $companyName)
                        .font(.title)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                        .onChange(of: companyName) { oldValue, newValue in
                            saveChanges()
                        }
                    
                    Picker("분류", selection: $selectedCategory) {
                        Text("선택 안함").tag(nil as CompanyCategory?)
                        ForEach(CompanyCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as CompanyCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedCategory) { oldValue, newValue in
                        saveChanges()
                    }
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // 속성 섹션
                VStack(alignment: .leading, spacing: 16) {
                    Text("속성")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        EditablePropertyRow(label: "지원일자") {
                            DatePicker("", selection: $appliedAt, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: appliedAt) { oldValue, newValue in
                                    saveChanges()
                                }
                        }
                        
                        EditablePropertyRow(label: "서류") {
                            Picker("", selection: $documentStatus) {
                                Text("선택 안함").tag(nil as InterviewStatus?)
                                ForEach(InterviewStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status as InterviewStatus?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: documentStatus) { oldValue, newValue in
                                saveChanges()
                            }
                        }
                        
                        EditablePropertyRow(label: "기술면접") {
                            Picker("", selection: $techInterviewStatus) {
                                Text("선택 안함").tag(nil as InterviewStatus?)
                                ForEach(InterviewStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status as InterviewStatus?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: techInterviewStatus) { oldValue, newValue in
                                saveChanges()
                            }
                        }
                        
                        EditablePropertyRow(label: "인적성") {
                            Picker("", selection: $cultureInterviewStatus) {
                                Text("선택 안함").tag(nil as InterviewStatus?)
                                ForEach(InterviewStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status as InterviewStatus?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: cultureInterviewStatus) { oldValue, newValue in
                                saveChanges()
                            }
                        }
                        
                        EditablePropertyRow(label: "이력서 버전") {
                            Picker("", selection: $selectedResumeVersionId) {
                                Text("선택 안함").tag(nil as UUID?)
                                ForEach(resumeStore.getAllVersions(), id: \.id) { version in
                                    Text(version.name).tag(version.id as UUID?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .onChange(of: selectedResumeVersionId) { oldValue, newValue in
                                store.updateResumeVersion(id: item.id, resumeVersionId: newValue)
                            }
                        }
                        
                        // 선택한 이력서 버전 정보 표시
                        if let resumeVersionId = selectedResumeVersionId,
                           let resumeVersion = resumeStore.getVersion(by: resumeVersionId) {
                            EditablePropertyRow(label: "") {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(resumeVersion.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        HStack(spacing: 8) {
                                            Text("\(resumeVersion.pageCount)페이지")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            
                                            Text(formatFileSize(resumeVersion.fileSize))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button {
                                        openPDF(url: URL(fileURLWithPath: resumeVersion.filePath))
                                    } label: {
                                        Label("열기", systemImage: "doc.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // 마크다운 에디터 & 뷰어 (노션 스타일 인라인 편집)
                VStack(alignment: .leading, spacing: 12) {
                    Text("내용")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                            ScrollView {
                                if content.isEmpty {
                                    Text("내용을 추가하세요")
                                        .foregroundStyle(.tertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .onTapGesture {
                                            // 빈 상태에서 클릭하면 새 단락 추가
                                            content = ""
                                            store.updateContent(id: item.id, content: "")
                                        }
                                } else {
                                    EditableMarkdownView(content: $content) { newContent in
                                        // 이미지 경로가 붙여넣어진 경우 자동으로 처리
                                        processImagePaths(in: newContent, oldContent: content)
                                        store.updateContent(id: item.id, content: content)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                }
                            }
                            .frame(minHeight: 400)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                            .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in
                                handleImageDrop(providers: providers)
                            }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .onChange(of: item.id) { oldValue, newValue in
            // item이 변경되면 상태 업데이트
            companyName = item.companyName
            appliedAt = item.appliedAt
            selectedCategory = CompanyCategory.allCases.first { $0.rawValue == item.category }
            documentStatus = InterviewStatus.allCases.first { $0.rawValue == item.documentStatus }
            techInterviewStatus = InterviewStatus.allCases.first { $0.rawValue == item.techInterviewStatus }
            cultureInterviewStatus = InterviewStatus.allCases.first { $0.rawValue == item.cultureInterviewStatus }
            resumeId = item.resumeId
            selectedResumeVersionId = item.resumeVersionId
            content = item.content
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func openPDF(url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    private func saveChanges() {
        store.update(
            id: item.id,
            companyName: companyName,
            appliedAt: appliedAt,
            category: selectedCategory?.rawValue ?? "",
            documentStatus: documentStatus?.rawValue ?? "",
            techInterviewStatus: techInterviewStatus?.rawValue ?? "",
            cultureInterviewStatus: cultureInterviewStatus?.rawValue ?? "",
            resumeId: resumeId,
            resumeVersionId: selectedResumeVersionId
        )
    }
    
    private func handleImageDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        
        for provider in providers {
            // 사용 가능한 타입 확인
            let imageTypes = ["public.image", "public.png", "public.jpeg", "public.tiff"]
            var foundType: String? = nil
            for imageType in imageTypes {
                if provider.hasItemConformingToTypeIdentifier(imageType) {
                    foundType = imageType
                    break
                }
            }
            
            if let imageType = foundType {
                provider.loadItem(forTypeIdentifier: imageType, options: nil) { item, error in
                    guard error == nil else { return }
                    
                    if let url = item as? URL {
                        // 보안 스코프 리소스 시작
                        let _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        DispatchQueue.main.async {
                            if let image = NSImage(contentsOf: url) {
                                insertImage(image: image)
                            } else {
                                insertImage(from: url)
                            }
                        }
                    } else if let image = item as? NSImage {
                        DispatchQueue.main.async {
                            insertImage(image: image)
                        }
                    } else if let data = item as? Data,
                              let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            insertImage(image: image)
                        }
                    }
                }
                handled = true
            }
            // 파일 URL 처리
            else if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard error == nil else { return }
                    
                    if let url = item as? URL {
                        // 보안 스코프 리소스 시작
                        let _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        DispatchQueue.main.async {
                            if let image = NSImage(contentsOf: url) {
                                insertImage(image: image)
                            } else {
                                insertImage(from: url)
                            }
                        }
                    } else if let urlString = item as? String,
                              let url = URL(string: urlString) {
                        // 보안 스코프 리소스 시작
                        let _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        DispatchQueue.main.async {
                            if let image = NSImage(contentsOf: url) {
                                insertImage(image: image)
                            } else {
                                insertImage(from: url)
                            }
                        }
                    }
                }
                handled = true
            }
        }
        
        return handled
    }
    
    private func insertImage(from url: URL) {
        // 보안 스코프 리소스로 접근 시도
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // 이미지를 먼저 로드해서 앱의 Documents 폴더로 복사
        if let image = NSImage(contentsOf: url) {
            insertImage(image: image)
        } else {
            // 원본 경로를 그대로 사용 (권한 문제로 실패할 수 있음)
            guard let imagePath = ImageManager.shared.saveImage(from: url, for: item.id) else {
                return
            }
            
            let markdownImage = "![\(url.lastPathComponent)](\(imagePath))"
            let newContent = content.isEmpty ? markdownImage : content + "\n\n" + markdownImage
            content = newContent
            store.updateContent(id: item.id, content: newContent)
        }
    }
    
    private func insertImage(image: NSImage) {
        guard let imagePath = ImageManager.shared.saveImage(image, for: item.id) else {
            return
        }
        
        let markdownImage = "![이미지](\(imagePath))"
        let newContent = content.isEmpty ? markdownImage : content + "\n\n" + markdownImage
        content = newContent
        store.updateContent(id: item.id, content: newContent)
    }
    
    private func processImagePaths(in newContent: String, oldContent: String) {
        // 새로 추가된 텍스트 찾기
        let newLines = newContent.components(separatedBy: .newlines)
        let oldLines = oldContent.components(separatedBy: .newlines)
        
        // 이미지 파일 확장자
        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tiff", ".webp"]
        
        var updatedContent = newContent
        
        for (index, line) in newLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 이전 내용에 없던 새 라인인지 확인
            if index >= oldLines.count || oldLines[index] != line {
                // 이미지 파일 경로인지 확인
                if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
                    let lowercased = trimmed.lowercased()
                    if imageExtensions.contains(where: { lowercased.hasSuffix($0) }) {
                        // 이미지 경로를 앱 폴더로 복사
                        let url: URL
                        if trimmed.hasPrefix("~") {
                            url = URL(fileURLWithPath: (trimmed as NSString).expandingTildeInPath)
                        } else if trimmed.hasPrefix("/") {
                            url = URL(fileURLWithPath: trimmed)
                        } else if let parsedURL = URL(string: trimmed), parsedURL.isFileURL {
                            url = parsedURL
                        } else {
                            continue
                        }
                        
                        if url.isFileURL {
                            // 보안 스코프 리소스로 접근 시도
                            let hasAccess = url.startAccessingSecurityScopedResource()
                            defer {
                                if hasAccess {
                                    url.stopAccessingSecurityScopedResource()
                                }
                            }
                            
                            if let image = NSImage(contentsOf: url) {
                                if let imagePath = ImageManager.shared.saveImage(image, for: item.id) {
                                    // 원본 경로를 마크다운 이미지 문법으로 교체
                                    let markdownImage = "![\(url.lastPathComponent)](\(imagePath))"
                                    updatedContent = updatedContent.replacingOccurrences(of: trimmed, with: markdownImage)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if updatedContent != newContent {
            content = updatedContent
        }
    }
}

struct EditablePropertyRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

