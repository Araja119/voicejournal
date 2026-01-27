import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let colors: AppColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(AppTypography.buttonPrimary)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(isDisabled ? colors.accentPrimary.opacity(0.5) : colors.accentPrimary)
            .cornerRadius(Theme.Radius.md)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let colors: AppColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colors.textPrimary))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(AppTypography.buttonSecondary)
            .foregroundColor(colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(colors.surface)
            .cornerRadius(Theme.Radius.md)
        }
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.Dark.background.ignoresSafeArea()

        VStack(spacing: 16) {
            PrimaryButton(
                title: "Continue",
                colors: AppColors(.dark)
            ) {}

            PrimaryButton(
                title: "Loading...",
                isLoading: true,
                colors: AppColors(.dark)
            ) {}

            PrimaryButton(
                title: "Disabled",
                isDisabled: true,
                colors: AppColors(.dark)
            ) {}

            SecondaryButton(
                title: "Cancel",
                colors: AppColors(.dark)
            ) {}
        }
        .padding()
    }
}
