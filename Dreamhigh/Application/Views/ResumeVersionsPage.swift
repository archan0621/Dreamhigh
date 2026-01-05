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
        HSplitView {
            // 왼쪽: 버전 목록
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.getAllVersions()) { version in
                        ResumeVersionCard(version: version)
                            .onTapGesture {
                                selectedVersion = version
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedVersion?.id == version.id ? Color.accentColor.opacity(0.1) : Color.clear)
                            )
                    }
                }
                .padding()
            }
            .frame(minWidth: 300, idealWidth: 350)
            .background(.regularMaterial)
            
            // 오른쪽: 상세 뷰
            if let selectedVersion = selectedVersion {
                ResumeVersionDetailView(version: selectedVersion)
                    .frame(minWidth: 500)
            }
        }
        .navigationTitle("이력서 버전")
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
        VStack(alignment: .leading, spacing: 12) {
            // 썸네일 (PDF 첫 페이지)
            if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: version.filePath)),
               let firstPage = pdfDocument.page(at: 0) {
                PDFThumbnailView(page: firstPage)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            } else {
                // 썸네일 없을 때 플레이스홀더
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("PDF 미리보기")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            // 버전 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(version.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Spacer()
                    
                    // 날짜
                    Text(version.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // 파일 정보
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(version.pageCount)페이지")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(formatFileSize(version.fileSize))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // 업데이트 불필요
    }
}

struct ResumeVersionDetailView: View {
    let version: ResumeVersion
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
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
                
                // PDF 미리보기
                VStack(alignment: .leading, spacing: 12) {
                    Text("미리보기")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    if let pdfDocument = PDFDocument(url: URL(fileURLWithPath: version.filePath)) {
                        PDFPreviewView(document: pdfDocument)
                            .frame(height: 600)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    } else {
                        Text("PDF를 불러올 수 없습니다")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
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

