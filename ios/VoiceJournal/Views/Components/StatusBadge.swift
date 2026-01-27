import SwiftUI

struct StatusBadge: View {
    let status: AssignmentStatus
    let colors: AppColors

    private var badgeColor: Color {
        switch status {
        case .pending:
            return colors.textSecondary
        case .sent:
            return colors.accentPrimary
        case .viewed:
            return Color(hex: "6366F1") // Indigo
        case .answered:
            return colors.accentSecondary
        }
    }

    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .sent:
            return "Sent"
        case .viewed:
            return "Viewed"
        case .answered:
            return "Answered"
        }
    }

    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock"
        case .sent:
            return "paperplane.fill"
        case .viewed:
            return "eye.fill"
        case .answered:
            return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))

            Text(statusText)
                .font(AppTypography.caption)
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(Theme.Radius.full)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        StatusBadge(status: .pending, colors: AppColors(.dark))
        StatusBadge(status: .sent, colors: AppColors(.dark))
        StatusBadge(status: .viewed, colors: AppColors(.dark))
        StatusBadge(status: .answered, colors: AppColors(.dark))
    }
    .padding()
    .background(Color.Dark.background)
}
