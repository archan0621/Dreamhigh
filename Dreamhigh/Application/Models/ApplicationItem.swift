import Foundation

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

