import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    var message: String? = nil

    var body: some View {
        let colors = AppColors(colorScheme)

        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: colors.accentPrimary))
                .scaleEffect(1.2)

            if let message = message {
                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    let colors: AppColors

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(colors.textSecondary.opacity(0.5))

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(AppTypography.headlineSmall)
                    .foregroundColor(colors.textPrimary)

                Text(message)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.buttonSecondary)
                        .foregroundColor(colors.accentPrimary)
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

struct AvatarView: View {
    let name: String
    var imageURL: String? = nil
    var size: CGFloat = 48
    let colors: AppColors

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        if let imageURL = imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    initialsView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        Circle()
            .fill(colors.surface)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(colors.textSecondary)
            )
    }
}

struct StatusBadge: View {
    let status: AssignmentStatus
    let colors: AppColors

    var body: some View {
        Text(status.displayName)
            .font(AppTypography.labelSmall)
            .foregroundColor(badgeColor)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background(badgeColor.opacity(0.15))
            .cornerRadius(Theme.Radius.sm)
    }

    private var badgeColor: Color {
        switch status {
        case .pending: return colors.textSecondary
        case .sent: return colors.accentPrimary
        case .viewed: return .blue
        case .answered: return colors.accentSecondary
        }
    }
}

// MARK: - Previews
#Preview("Loading") {
    LoadingView(message: "Loading...")
        .preferredColorScheme(.dark)
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "book.closed",
        title: "No Journals Yet",
        message: "Create your first journal to start collecting stories",
        actionTitle: "Create Journal",
        action: {},
        colors: AppColors(.dark)
    )
    .background(Color.Dark.background)
}

#Preview("Avatar") {
    HStack(spacing: 16) {
        AvatarView(name: "John Doe", size: 48, colors: AppColors(.dark))
        AvatarView(name: "Mom", size: 48, colors: AppColors(.dark))
        AvatarView(name: "A", size: 48, colors: AppColors(.dark))
    }
    .padding()
    .background(Color.Dark.background)
}
