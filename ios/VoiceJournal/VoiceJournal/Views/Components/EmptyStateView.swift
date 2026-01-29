import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    let colors: AppColors

    @Environment(\.colorScheme) var colorScheme

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.25)
    }

    private var strongShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : Color.black.opacity(0.3)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(colors.textPrimary.opacity(0.5))
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)

            // Text
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(colors.textPrimary)
                    .shadow(color: strongShadow, radius: 3, x: 0, y: 1)
                    .shadow(color: strongShadow, radius: 6, x: 0, y: 2)

                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textPrimary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
                    .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
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
                        .shadow(color: colors.accentPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
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
