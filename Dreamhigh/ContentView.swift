import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarSection? = .applications
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SidebarSection.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Dreamhigh")
        } detail: {
            switch selection {
            case .applications:
                ApplicationsPage(context: context)
            case .resumes:
                ResumeVersionsPage(context: context)
            case .none:
                Text("메뉴를 선택하세요")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 1100, minHeight: 620)
    }
}

#Preview {
    ContentView()
}
