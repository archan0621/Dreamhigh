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
    @State private var jobPostingURL: String
    @State private var content: String
    @State private var isEditingContent: Bool = false
    @State private var isCrawling = false
    @State private var crawlError: String?
    @State private var structuredJobPosting: StructuredJobPosting?
    
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
        _jobPostingURL = State(initialValue: item.jobPostingURL ?? "")
        _content = State(initialValue: item.content)
        _structuredJobPosting = State(initialValue: item.structuredJobPosting)
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
                        
                        EditablePropertyRow(label: "채용공고 링크") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    TextField("https://...", text: $jobPostingURL)
                                        .textFieldStyle(.plain)
                                        .onChange(of: jobPostingURL) { oldValue, newValue in
                                            saveChanges()
                                            crawlError = nil
                                        }
                                    
                                    if !jobPostingURL.isEmpty {
                                        if let url = URL(string: jobPostingURL) {
                                            Button {
                                                NSWorkspace.shared.open(url)
                                            } label: {
                                                Image(systemName: "arrow.up.right.square")
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundStyle(.blue)
                                            
                                            if !isCrawling {
                                                Button {
                                                    Task {
                                                        await crawlAndStructureJobPosting()
                                                    }
                                                } label: {
                                                    Label("분석", systemImage: "sparkles")
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                                .disabled(!SettingsStore.shared.isAIConfigured || structuredJobPosting != nil)
                                            } else {
                                                ProgressView()
                                                    .controlSize(.small)
                                            }
                                        }
                                    }
                                }
                                
                                if let error = crawlError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else if structuredJobPosting != nil {
                                    Text("분석이 완료되었습니다")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if jobPostingURL.isEmpty {
                                    Text("채용공고 링크를 입력하면 자동으로 정보를 추출할 수 있습니다")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // 채용공고 정리 (항상 표시)
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("채용공고 정리")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    if let structured = structuredJobPosting {
                        VStack(alignment: .leading, spacing: 12) {
                            if let position = structured.position, !position.isEmpty {
                                InfoRow(label: "포지션", value: position)
                            }
                            
                            if let location = structured.location, !location.isEmpty {
                                InfoRow(label: "근무지", value: location)
                            }
                            
                            if let employmentType = structured.employmentType, !employmentType.isEmpty {
                                InfoRow(label: "채용 형태", value: employmentType)
                            }
                            
                            if let experienceLevel = structured.experienceLevel, !experienceLevel.isEmpty {
                                InfoRow(label: "경력", value: experienceLevel)
                            }
                            
                            if let workType = structured.workType, !workType.isEmpty {
                                InfoRow(label: "근무 형태", value: workType)
                            }
                            
                            if let deadline = structured.deadline, !deadline.isEmpty {
                                InfoRow(label: "마감일", value: deadline)
                            }
                            
                            if let techStack = structured.techStack, !techStack.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("기술 스택")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    FlowLayout(spacing: 6) {
                                        ForEach(techStack, id: \.self) { tech in
                                            Text(tech)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.1))
                                                .foregroundStyle(.primary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            
                            if let requirements = structured.requirements, !requirements.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("필수 요구사항")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    ForEach(requirements, id: \.self) { req in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text(req)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            
                            if let preferred = structured.preferredQualifications, !preferred.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("우대사항")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    ForEach(preferred, id: \.self) { pref in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text(pref)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            
                            if let description = structured.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("상세 설명")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text("분석 버튼을 눌러 채용공고를 분석하세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Divider()
                
                // 마크다운 에디터 & 뷰어 (노션 스타일 인라인 편집)
                // TODO: 다른 기능 구현 후 다시 활성화
                /*
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("내용")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        // 편집/보기 모드 전환 버튼
                        Button {
                            isEditingContent.toggle()
                        } label: {
                            Label(isEditingContent ? "보기" : "편집", systemImage: isEditingContent ? "eye" : "pencil")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    ScrollView {
                        if content.isEmpty && !isEditingContent {
                            Text("내용을 추가하세요")
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .onTapGesture {
                                    // 빈 상태에서 클릭하면 편집 모드로 전환
                                    isEditingContent = true
                                }
                        } else {
                            EditableMarkdownView(
                                content: $content,
                                isEditing: $isEditingContent
                            ) { newContent in
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
                */
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
            jobPostingURL = item.jobPostingURL ?? ""
            content = item.content
            structuredJobPosting = item.structuredJobPosting
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
    
    private func crawlAndStructureJobPosting() async {
        guard !jobPostingURL.isEmpty else { return }
        
        // AI 설정 확인
        guard SettingsStore.shared.isAIConfigured else {
            await MainActor.run {
                crawlError = "AI 설정이 필요합니다. Settings에서 AI 제공자와 토큰을 설정해주세요."
            }
            return
        }
        
        isCrawling = true
        crawlError = nil
        
        defer {
            isCrawling = false
        }
        
        do {
            // 1. 크롤링
            let crawledText = try await JobPostingCrawler.shared.crawl(jobPostingURL)
            
            // 2. AI 구조화
            guard let aiService = AIServiceFactory.createServiceFromSettings() else {
                await MainActor.run {
                    crawlError = "AI 서비스를 초기화할 수 없습니다."
                }
                return
            }
            
            let structuredPosting = try await aiService.structureJobPosting(crawledText)
            
            // 3. 결과를 UI에 반영 및 저장
            await MainActor.run {
                // 구조화된 정보 저장
                self.structuredJobPosting = structuredPosting
                
                // CoreData에 저장
                store.updateStructuredJobPosting(id: item.id, structuredJobPosting: structuredPosting)
                
                // 회사명이 있으면 자동으로 채우기
                if let companyName = structuredPosting.companyName, !companyName.isEmpty {
                    self.companyName = companyName
                }
                
                // 성공 메시지 표시 (에러 메시지 초기화)
                crawlError = nil
                
                saveChanges()
            }
            
        } catch {
            await MainActor.run {
                if let crawlerError = error as? CrawlerError {
                    switch crawlerError {
                    case .invalidURL:
                        crawlError = "유효하지 않은 URL입니다."
                    case .unsupportedSite:
                        crawlError = "지원하지 않는 사이트입니다. 모든 URL에 대해 시도하지만 실패할 수 있습니다."
                    case .networkError:
                        crawlError = "네트워크 오류가 발생했습니다."
                    case .parsingError, .notImplemented:
                        crawlError = "크롤링 중 오류가 발생했습니다."
                    }
                } else if let aiError = error as? AIServiceError {
                    switch aiError {
                    case .invalidAPIKey:
                        crawlError = "AI API 키가 유효하지 않습니다."
                    case .networkError:
                        crawlError = "AI 서비스 네트워크 오류가 발생했습니다."
                    case .invalidResponse:
                        crawlError = "AI 응답을 처리할 수 없습니다."
                    case .notImplemented:
                        crawlError = "AI 기능이 아직 구현되지 않았습니다."
                    }
                } else {
                    // 일반적인 에러 메시지 처리
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("hostname") || errorMessage.contains("could not be found") {
                        crawlError = "서버를 찾을 수 없습니다. URL을 확인해주세요."
                    } else {
                        crawlError = "오류가 발생했습니다: \(errorMessage)"
                    }
                }
            }
        }
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
            resumeVersionId: selectedResumeVersionId,
            jobPostingURL: jobPostingURL.isEmpty ? nil : jobPostingURL
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

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

