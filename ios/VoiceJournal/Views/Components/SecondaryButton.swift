import SwiftUI

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let colors: AppColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(AppTypography.labelLarge)
            }
            .foregroundColor(colors.accentPrimary)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(colors.accentPrimary, lineWidth: 1.5)
            )
        }
    }
}

// Text-only variant
struct SecondaryTextButton: View {
    let title: String
    let colors: AppColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(colors.accentPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SecondaryButton(
            title: "Re-record",
            icon: "arrow.counterclockwise",
            colors: AppColors(.dark)
        ) {}

        SecondaryButton(
            title: "Cancel",
            colors: AppColors(.dark)
        ) {}

        SecondaryTextButton(
            title: "Skip for now",
            colors: AppColors(.dark)
        ) {}
    }
    .padding()
    .background(Color.Dark.background)
}
