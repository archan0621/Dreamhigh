import SwiftUI

// MARK: - Sidebar Section
enum SidebarSection: String, CaseIterable, Identifiable {
    case applications = "지원 내역"
    case resumes = "이력서 버전"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .applications: return "tray.full"
        case .resumes: return "doc.on.doc"
        }
    }
}

// MARK: - Models (목업)
struct ApplicationItem: Identifiable {
    let id = UUID()
    var company: String
    var appliedAt: Date
    var category: String
    var docStatus: String
    var techInterview: String
    var cultureInterview: String
    var resumeId: String
}

// MARK: - Root
struct ContentView: View {
    @State private var selection: SidebarSection? = .applications

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .listStyle(.sidebar)
            .navigationTitle("Dreamhigh")
        } detail: {
            switch selection {
            case .applications:
                ApplicationsPage()
            case .resumes:
                ResumeVersionsPage()
            case .none:
                Text("메뉴를 선택하세요")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1100, minHeight: 620)
    }
}

// MARK: - Page: Applications (기존 Table 화면)
private struct ApplicationsPage: View {
    @State private var items: [ApplicationItem] = [
        .init(company: "네네치킨",
              appliedAt: Date(timeIntervalSinceNow: -60*60*24*8),
              category: "네카라",
              docStatus: "",
              techInterview: "",
              cultureInterview: "",
              resumeId: "R-001"),
    ]

    @State private var isPresentingAdd = false
    @State private var tableSelection = Set<UUID>()

    var body: some View {
        VStack(spacing: 0) {
            Table(items, selection: $tableSelection) {
                TableColumn("회사명") { item in
                    Text(item.company).lineLimit(1)
                }
                .width(min: 220, ideal: 360)

                TableColumn("지원일자") { item in
                    Text(item.appliedAt.formatted(date: .numeric, time: .omitted))
                        .monospacedDigit()
                }
                .width(min: 110, ideal: 120)

                TableColumn("분류") { item in
                    Pill(text: item.category)
                }
                .width(min: 90, ideal: 110)

                TableColumn("서류") { item in
                    Pill(text: item.docStatus)
                }
                .width(min: 70, ideal: 80)

                TableColumn("기술면접") { item in
                    Pill(text: item.techInterview)
                }
                .width(min: 90, ideal: 100)

                TableColumn("인적성") { item in
                    Pill(text: item.cultureInterview)
                }
                .width(min: 90, ideal: 100)

                TableColumn("이력서 ID") { item in
                    Text(item.resumeId).foregroundStyle(.secondary).monospaced()
                }
                .width(min: 90, ideal: 100)
            }
            .tableStyle(.inset)
        }
        .navigationTitle("지원 내역")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAdd = true
                } label: {
                    Label("새로 만들기", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddApplicationSheet { company in
                items.insert(
                    .init(company: company,
                          appliedAt: Date(),
                          category: "네카라",
                          docStatus: "",
                          techInterview: "",
                          cultureInterview: "",
                          resumeId: "R-001"),
                    at: 0
                )
            }
        }
    }
}

// MARK: - Page: Resume Versions (일단 빈 화면)
private struct ResumeVersionsPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이력서 버전")
                .font(.title2).bold()
            Text("여기에 이력서 버전 관리(파일 업로드/버전/태그)를 붙일 예정")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("이력서 버전")
    }
}

// MARK: - Components
private struct Pill: View {
    let text: String
    var body: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct AddApplicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var company = ""
    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("회사명", text: $company)
            }
            .navigationTitle("새 지원 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        onAdd(company.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 160)
    }
}

#Preview {
    ContentView()
}
