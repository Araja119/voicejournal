import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    let colors: AppColors

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(colors.textSecondary.opacity(0.5))

            // Text
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(colors.textPrimary)

                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(colors.accentPrimary)
                        .cornerRadius(Theme.Radius.full)
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.Dark.background
            .ignoresSafeArea()

        EmptyStateView(
            icon: "person.2",
            title: "No People Yet",
            message: "Add your first person to start sending them questions",
            actionTitle: "Add Person",
            action: {},
            colors: AppColors(.dark)
        )
    }
}
