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

// MARK: - Preview
#Preview {
    LoadingView(message: "Loading...")
        .preferredColorScheme(.dark)
}
