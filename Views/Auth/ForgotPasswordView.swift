import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(colors.accentPrimary)

                        Text("Reset Password")
                            .font(AppTypography.headlineLarge)
                            .foregroundColor(colors.textPrimary)

                        Text("Enter your email and we'll send you a link to reset your password")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    if viewModel.forgotSuccess {
                        // Success State
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(colors.accentSecondary)

                            Text("Check your email")
                                .font(AppTypography.headlineSmall)
                                .foregroundColor(colors.textPrimary)

                            Text("If an account exists for \(viewModel.forgotEmail), you'll receive a password reset link shortly.")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        Spacer()

                        PrimaryButton(
                            title: "Done",
                            colors: colors
                        ) {
                            dismiss()
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                    } else {
                        // Form State
                        VStack(spacing: Theme.Spacing.md) {
                            InputField(
                                title: "Email",
                                text: $viewModel.forgotEmail,
                                placeholder: "your@email.com",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                colors: colors
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Error
                        if let error = viewModel.forgotError {
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.lg)
                        }

                        Spacer()

                        PrimaryButton(
                            title: "Send Reset Link",
                            isLoading: viewModel.isSendingReset,
                            isDisabled: !viewModel.isForgotValid,
                            colors: colors
                        ) {
                            Task { await viewModel.sendPasswordReset() }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }

                    Spacer().frame(height: Theme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ForgotPasswordView()
        .preferredColorScheme(.dark)
}
