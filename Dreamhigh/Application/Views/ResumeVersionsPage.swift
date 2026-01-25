import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import CoreData

struct ResumeVersionsPage: View {
    @StateObject private var store: ResumeVersionStore
    @State private var selectedVersion: ResumeVersion?
    @State private var isPresentingUpload = false
    
    init(context: NSManagedObjectContext) {
        _store = StateObject(wrappedValue: ResumeVersionStore(context: context))
    }
    
    var body: some View {
        NavigationStack {
            // 목록 화면
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
                ], spacing: 16) {
                    ForEach(store.getAllVersions()) { version in
                        ResumeVersionCard(version: version)
                            .onTapGesture {
                                self.selectedVersion = version
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("이력서 버전")
            .navigationDestination(item: $selectedVersion) { version in
                ResumeVersionDetailView(version: version, store: store)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingUpload = true
                    } label: {
                        Label("새 버전 추가", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .sheet(isPresented: $isPresentingUpload) {
            UploadResumeSheet(store: store) { newVersion in
                selectedVersion = newVersion
            }
        }
    }
}

struct ResumeVersionCard: View {
    let version: ResumeVersion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 썸네일 (PDF 첫 페이지) - 간소화
            if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: version.filePath)),
               let firstPage = pdfDocument.page(at: 0) {
                PDFThumbnailView(page: firstPage)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .allowsHitTesting(false)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.tertiary)
                }
            }
            
            // 버전 정보 - 간소화
            VStack(alignment: .leading, spacing: 4) {
                Text(version.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(version.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
        )
        .contentShape(Rectangle())
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct PDFThumbnailView: NSViewRepresentable {
    let page: PDFPage
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument()
        pdfView.document?.insert(page, at: 0)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        // 상호작용은 SwiftUI 레벨에서 allowsHitTesting(false)로 제어
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // 업데이트 불필요
    }
}

struct ResumeVersionDetailView: View {
    let version: ResumeVersion
    @ObservedObject var store: ResumeVersionStore
    
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var aiFeedback: ResumeFeedback?
    
    var body: some View {
        HSplitView {
            // 왼쪽: 정보 및 피드백
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 헤더 (제목과 날짜)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(version.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(version.createdAt.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // 파일 정보
                    VStack(alignment: .leading, spacing: 16) {
                        Text("파일 정보")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 24) {
                            InfoItem(label: "페이지 수", value: "\(version.pageCount)페이지")
                            InfoItem(label: "파일 크기", value: formatFileSize(version.fileSize))
                            InfoItem(label: "형식", value: "PDF")
                        }
                    }
                    
                    Divider()
                    
                    // 메모
                    if !version.note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("메모")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text(version.note)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Divider()
                    
                    // AI 피드백 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI 피드백")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button(action: { analyzeResume() }) {
                                if isAnalyzing {
                                    ProgressView()
                                        .controlSize(.small)
                                        .padding(.trailing, 8)
                                } else {
                                    Text("피드백 받기")
                                }
                            }
                            .disabled(!SettingsStore.shared.isAIConfigured || isAnalyzing || aiFeedback != nil)
                        }
                        
                        if let error = analysisError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        if let feedback = aiFeedback {
                            ResumeFeedbackView(feedback: feedback)
                        } else if !isAnalyzing && analysisError == nil {
                            Text("이력서 분석을 시작하려면 '피드백 받기' 버튼을 눌러주세요.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 0)
                .padding(.bottom)
            }
            .frame(minWidth: 400, idealWidth: 500)
            
            // 오른쪽: PDF 미리보기
            VStack(alignment: .leading, spacing: 12) {
                Text("미리보기")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 0)
                
                if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: version.filePath)) {
                    PDFPreviewView(document: pdfDocument)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                } else {
                    Text("PDF를 불러올 수 없습니다")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 500, idealWidth: 600)
        }
        .navigationTitle(version.name)
        .onAppear {
            // 기존 피드백 로드
            aiFeedback = version.aiFeedback
        }
        .onChange(of: version.id) { _, _ in
            // 버전 변경 시 피드백 초기화
            aiFeedback = version.aiFeedback
            analysisError = nil
        }
    }
    
    private func analyzeResume() {
        guard !isAnalyzing else { return }
        guard SettingsStore.shared.isAIConfigured else { return }
        
        isAnalyzing = true
        analysisError = nil
        
        Task {
            do {
                guard let aiService = AIServiceFactory.createServiceFromSettings() else {
                    await MainActor.run {
                        self.isAnalyzing = false
                        self.analysisError = "AI 설정을 확인해주세요"
                    }
                    return
                }
                
                let feedback = try await aiService.analyzeResume(pdfPath: version.filePath)
                
                await MainActor.run {
                    self.aiFeedback = feedback
                    self.isAnalyzing = false
                    
                    // CoreData에 저장
                    store.updateAIFeedback(id: version.id, feedback: feedback)
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    self.analysisError = "분석 실패: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ResumeFeedbackView: View {
    let feedback: ResumeFeedback
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 전체 점수
            HStack(spacing: 12) {
                Text("종합 점수")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(feedback.overallScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(scoreColor(feedback.overallScore))
                    Text("/ 100")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(scoreColor(feedback.overallScore).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 첫인상
            VStack(alignment: .leading, spacing: 8) {
                Text("첫인상")
                    .font(.headline)
                Text(feedback.firstImpression)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 강점
            VStack(alignment: .leading, spacing: 8) {
                Label("강점", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                
                ForEach(feedback.strengths, id: \.self) { strength in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.green)
                        Text(strength)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 개선점
            VStack(alignment: .leading, spacing: 8) {
                Label("개선점 및 약점", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                
                ForEach(feedback.improvements, id: \.self) { improvement in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.orange)
                        Text(improvement)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 면접 예상 질문
            VStack(alignment: .leading, spacing: 8) {
                Label("면접 예상 질문", systemImage: "questionmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                
                ForEach(Array(feedback.interviewQuestions.enumerated()), id: \.offset) { index, question in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                        Text(question)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 섹션별 피드백
            if !feedback.sectionFeedback.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("섹션별 평가")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(feedback.sectionFeedback, id: \.sectionName) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(section.sectionName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("\(section.score)점")
                                    .font(.caption)
                                    .foregroundStyle(scoreColor(section.score))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(scoreColor(section.score).opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Text(section.feedback)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            // 총평
            VStack(alignment: .leading, spacing: 8) {
                Text("총평")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(feedback.summary)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 생성 일시
            Text("분석 일시: \(feedback.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}

struct PDFPreviewView: NSViewRepresentable {
    let document: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}

struct UploadResumeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ResumeVersionStore
    @State private var versionName = ""
    @State private var note = ""
    @State private var selectedFile: URL?
    
    let onUpload: (ResumeVersion) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 파일 선택
                VStack(spacing: 12) {
                    if let file = selectedFile {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(file.lastPathComponent)
                                .lineLimit(1)
                            Spacer()
                            Button("변경") {
                                selectFile()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Button {
                            selectFile()
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.accentColor)
                                Text("PDF 파일 선택")
                                    .font(.headline)
                                Text("또는 드래그 앤 드롭")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                            handleFileDrop(providers: providers)
                        }
                    }
                }
                
                // 버전 정보 입력
                VStack(alignment: .leading, spacing: 16) {
                    FormField(label: "버전명", icon: "tag.fill") {
                        TextField("예: 2024년 상반기", text: $versionName)
                            .textFieldStyle(.plain)
                    }
                    
                    FormField(label: "메모", icon: "note.text") {
                        TextField("버전별 특징이나 변경사항을 기록하세요", text: $note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...6)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
            .navigationTitle("새 이력서 버전")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.bordered)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        uploadResume()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(versionName.isEmpty || selectedFile == nil)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            selectedFile = panel.url
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard error == nil,
                          let url = item as? URL,
                          url.pathExtension.lowercased() == "pdf" else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        selectedFile = url
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func uploadResume() {
        guard let file = selectedFile else { return }
        
        // 파일 정보 가져오기
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
        
        var pageCount = 0
        if let pdfDocument = PDFDocument(url: file) {
            pageCount = pdfDocument.pageCount
        }
        
        // 새 버전 ID 생성
        let versionId = UUID()
        
        // PDF 파일을 앱의 Documents 폴더로 복사
        guard let savedFilePath = PDFManager.shared.savePDF(from: file, for: versionId) else {
            return
        }
        
        // CoreData에 저장
        store.create(
            id: versionId,
            name: versionName,
            createdAt: Date(),
            note: note,
            filePath: savedFilePath,
            pageCount: pageCount,
            fileSize: fileSize
        )
        
        // 새로 생성된 버전을 찾아서 콜백 호출
        if let newVersion = store.getVersion(by: versionId) {
            onUpload(newVersion)
        }
        
        dismiss()
    }
}

