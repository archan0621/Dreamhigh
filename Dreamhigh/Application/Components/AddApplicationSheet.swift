import SwiftUI
import CoreData

enum CompanyCategory: String, CaseIterable {
    case foreign = "외국계"
    case naekara = "네카라"
    case kubedangto = "쿠배당토"
    case preUnicorn = "예비 유니콘"
    case traditionalLarge = "전통 대기업"
    case traditionalMid = "전통 중견기업"
    case earlyStartup = "초기 스타트업"
}

enum InterviewStatus: String, CaseIterable {
    case pass = "합격"
    case fail = "불합격"
    case pending = "대기"
}

struct AddApplicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var companyName = ""
    @State private var appliedAt = Date()
    @State private var selectedCategory: CompanyCategory?
    @State private var documentStatus: InterviewStatus? = .pending
    @State private var techInterviewStatus: InterviewStatus? = .pending
    @State private var cultureInterviewStatus: InterviewStatus? = .pending
    @State private var selectedResumeVersionId: UUID?
    @State private var jobPostingURL = ""
    @StateObject private var resumeStore: ResumeVersionStore
    
    let item: ApplyHistory?
    let onSave: (String, Date, String, String, String, String, UUID?, String?) -> Void
    
    init(item: ApplyHistory? = nil, context: NSManagedObjectContext, onSave: @escaping (String, Date, String, String, String, String, UUID?, String?) -> Void) {
        self.item = item
        self.onSave = onSave
        _resumeStore = StateObject(wrappedValue: ResumeVersionStore(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("기본 정보", systemImage: "building.2")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 16) {
                            FormField(label: "회사명", icon: "building.2.fill", isRequired: true) {
                                TextField("회사명을 입력하세요", text: $companyName)
                                    .textFieldStyle(.plain)
                            }
                            
                            FormField(label: "지원일자", icon: "calendar", isRequired: true) {
                                DatePicker("", selection: $appliedAt, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            FormField(label: "분류", icon: "tag.fill") {
                                Picker("", selection: $selectedCategory) {
                                    Text("선택 안함").tag(nil as CompanyCategory?)
                                    ForEach(CompanyCategory.allCases, id: \.self) { category in
                                        Text(category.rawValue).tag(category as CompanyCategory?)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("면접 상태", systemImage: "person.badge.shield.checkmark")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 16) {
                            FormField(label: "서류", icon: "doc.text.fill") {
                                Picker("", selection: $documentStatus) {
                                    Text("선택 안함").tag(nil as InterviewStatus?)
                                    ForEach(InterviewStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status as InterviewStatus?)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                            
                            FormField(label: "기술면접", icon: "laptopcomputer") {
                                Picker("", selection: $techInterviewStatus) {
                                    Text("선택 안함").tag(nil as InterviewStatus?)
                                    ForEach(InterviewStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status as InterviewStatus?)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                            
                            FormField(label: "인적성", icon: "person.fill.checkmark") {
                                Picker("", selection: $cultureInterviewStatus) {
                                    Text("선택 안함").tag(nil as InterviewStatus?)
                                    ForEach(InterviewStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status as InterviewStatus?)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("이력서", systemImage: "doc.on.doc")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        FormField(label: "이력서 버전", icon: "doc.on.doc") {
                            Picker("", selection: $selectedResumeVersionId) {
                                Text("선택 안함").tag(nil as UUID?)
                                ForEach(resumeStore.getAllVersions(), id: \.id) { version in
                                    Text(version.name).tag(version.id as UUID?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("채용공고", systemImage: "link")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        FormField(label: "채용공고 링크", icon: "link") {
                            TextField("https://...", text: $jobPostingURL)
                                .textFieldStyle(.plain)
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle(item == nil ? "새 지원 추가" : "지원 내역 수정")
            .onAppear {
                if let item = item {
                    companyName = item.companyName
                    appliedAt = item.appliedAt
                    selectedCategory = CompanyCategory.allCases.first { $0.rawValue == item.category }
                    documentStatus = InterviewStatus.allCases.first { $0.rawValue == item.documentStatus }
                    techInterviewStatus = InterviewStatus.allCases.first { $0.rawValue == item.techInterviewStatus }
                    cultureInterviewStatus = InterviewStatus.allCases.first { $0.rawValue == item.cultureInterviewStatus }
                    selectedResumeVersionId = item.resumeVersionId
                    jobPostingURL = item.jobPostingURL ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .buttonStyle(.bordered)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave(
                            companyName.trimmingCharacters(in: .whitespacesAndNewlines),
                            appliedAt,
                            selectedCategory?.rawValue ?? "",
                            documentStatus?.rawValue ?? "",
                            techInterviewStatus?.rawValue ?? "",
                            cultureInterviewStatus?.rawValue ?? "",
                            selectedResumeVersionId,
                            jobPostingURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : jobPostingURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    } label: {
                        Label(item == nil ? "추가" : "저장", systemImage: item == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }
}

struct FormField<Content: View>: View {
    let label: String
    let icon: String
    let isRequired: Bool
    @ViewBuilder let content: Content
    
    init(label: String, icon: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.label = label
        self.icon = icon
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Label {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if isRequired {
                        Text("*")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            .frame(width: 100, alignment: .leading)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


