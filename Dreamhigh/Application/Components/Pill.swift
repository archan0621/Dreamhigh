import SwiftUI

struct Pill: View {
    let text: String
    
    private var statusColor: Color {
        switch text {
        case "합격":
            return .green
        case "불합격":
            return .red
        case "대기":
            return .orange
        default:
            return .secondary
        }
    }
    
    var body: some View {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                }
        }
    }
}

