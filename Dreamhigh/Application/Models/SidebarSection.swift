import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
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

