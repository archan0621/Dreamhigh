import SwiftUI
import CoreData

struct ApplicationsPage: View {
    @StateObject private var store: ApplyHistoryStore
    let context: NSManagedObjectContext
    
    @State private var isPresentingAdd = false
    @State private var editingItem: ApplyHistory?
    @State private var selectedItem: ApplyHistory? = nil
    @State private var tableSelection = Set<UUID>()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        _store = StateObject(
            wrappedValue: ApplyHistoryStore(context: context)
        )
    }
    
    private var tableView: some View {
        VStack(spacing: 0) {
            if store.items.isEmpty {
                emptyStateView
            } else {
                Table(store.items, selection: $tableSelection) {
                    TableColumn("회사명") { item in
                        HStack(spacing: 10) {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.companyName)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                if !item.category.isEmpty {
                                    Text(item.category)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 150, ideal: 180)

                    TableColumn("지원일자") { item in
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                                .font(.caption2)
                            Text(item.appliedAt.formatted(date: .numeric, time: .omitted))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn("서류") { item in
                        Pill(text: item.documentStatus)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 80, ideal: 90)

                    TableColumn("기술면접") { item in
                        Pill(text: item.techInterviewStatus)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 90, ideal: 100)

                    TableColumn("인적성") { item in
                        Pill(text: item.cultureInterviewStatus)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 90, ideal: 100)

                    TableColumn("이력서 ID") { item in
                        Group {
                            if !item.resumeId.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.secondary)
                                        .font(.caption2)
                                    Text(item.resumeId)
                                        .foregroundStyle(.secondary)
                                        .monospaced()
                                        .font(.caption)
                                }
                            } else {
                                Text("—")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 100, ideal: 120)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
                .padding()
                .onChange(of: tableSelection) { oldValue, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let selectedId = newValue.first,
                           let item = store.items.first(where: { $0.id == selectedId }) {
                            selectedItem = item
                        } else {
                            selectedItem = nil
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // 테이블 (항상 표시)
                tableView
                    .frame(width: geometry.size.width)
                
                // 사이드 패널 (슬라이딩)
                if let selectedItem = selectedItem {
                    ApplicationDetailSidebar(item: selectedItem, store: store, context: context)
                        .frame(width: geometry.size.width * 0.5)
                        .background(.regularMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: -5)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedItem?.id)
        .navigationTitle("지원 내역")
        .onAppear {
            store.fetch()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    if !tableSelection.isEmpty {
                        if tableSelection.count == 1,
                           let id = tableSelection.first,
                           let item = store.items.first(where: { $0.id == id }) {
                            Button {
                                editingItem = item
                            } label: {
                                Label("수정", systemImage: "pencil")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        Button {
                            self.store.delete(ids: tableSelection)
                            tableSelection.removeAll()
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Label("새로 만들기", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddApplicationSheet { companyName, appliedAt, category, documentStatus, techInterviewStatus, cultureInterviewStatus, resumeId in
                self.store.create(
                    companyName: companyName,
                    appliedAt: appliedAt,
                    category: category,
                    documentStatus: documentStatus,
                    techInterviewStatus: techInterviewStatus,
                    cultureInterviewStatus: cultureInterviewStatus,
                    resumeId: resumeId
                )
            }
        }
        .sheet(item: $editingItem) { item in
            AddApplicationSheet(item: item) { companyName, appliedAt, category, documentStatus, techInterviewStatus, cultureInterviewStatus, resumeId in
                self.store.update(
                    id: item.id,
                    companyName: companyName,
                    appliedAt: appliedAt,
                    category: category,
                    documentStatus: documentStatus,
                    techInterviewStatus: techInterviewStatus,
                    cultureInterviewStatus: cultureInterviewStatus,
                    resumeId: resumeId
                )
                tableSelection.removeAll()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text("지원 내역이 없습니다")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("새로운 지원 내역을 추가해보세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                isPresentingAdd = true
            } label: {
                Label("새 지원 추가", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

