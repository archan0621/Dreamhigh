import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarSection? = .applications
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // 사이드바
            List(selection: $selection) {
                ForEach(SidebarSection.allCases) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.title2)
                            .frame(width: 24)
                        Text(item.rawValue)
                            .font(.body)
                    }
                    .tag(item)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Dreamhigh")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            switch selection {
            case .applications:
                ApplicationsPage(context: context)
            case .resumes:
                ResumeVersionsPage(context: context)
            case .insights:
                InsightsPage(context: context)
            case .none:
                Text("메뉴를 선택하세요")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1100, minHeight: 620)
    }
}

#Preview {
    ContentView()
}
