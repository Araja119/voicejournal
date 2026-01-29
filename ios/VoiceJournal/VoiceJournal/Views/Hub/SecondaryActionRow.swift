import SwiftUI

struct SecondaryActionRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let colors: AppColors
    var badge: Int? = nil
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var cardOpacity: Double {
        colorScheme == .dark ? 0.88 : 0.95
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon - lower contrast for secondary actions
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(colors.textSecondary.opacity(0.8))
                    .frame(width: 24)

                // Title and optional subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary.opacity(0.7))
                    }
                }

                Spacer()

                // Badge (optional)
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(colors.accentPrimary)
                        .cornerRadius(Theme.Radius.full)
                }

                // Arrow - subtle
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colors.textSecondary.opacity(0.5))
            }
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.md)
            .background(colors.surface.opacity(cardOpacity))
            .cornerRadius(Theme.Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.Dark.background.ignoresSafeArea()

        VStack(spacing: 12) {
            SecondaryActionRow(
                title: "My People",
                subtitle: "The voices that matter",
                icon: "person.2.fill",
                colors: AppColors(.dark),
                badge: 3
            ) {}

            SecondaryActionRow(
                title: "Latest Recordings",
                subtitle: "Listen back",
                icon: "waveform",
                colors: AppColors(.dark)
            ) {}
        }
        .padding()
    }
}
