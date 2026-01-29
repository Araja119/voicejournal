import SwiftUI

struct SignupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, password, confirmPassword
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Create Account")
                                .font(AppTypography.headlineLarge)
                                .foregroundColor(colors.textPrimary)

                            Text("Start preserving memories")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Form
                        VStack(spacing: Theme.Spacing.md) {
                            // Display Name
                            InputField(
                                title: "Your Name",
                                text: $viewModel.signupDisplayName,
                                placeholder: "How should we call you?",
                                textContentType: .name,
                                colors: colors
                            )
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }

                            // Email
                            InputField(
                                title: "Email",
                                text: $viewModel.signupEmail,
                                placeholder: "your@email.com",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                colors: colors
                            )
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                            // Password
                            InputField(
                                title: "Password",
                                text: $viewModel.signupPassword,
                                placeholder: "At least 8 characters",
                                isSecure: true,
                                textContentType: .newPassword,
                                colors: colors,
                                error: viewModel.signupPasswordError
                            )
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .confirmPassword }

                            // Confirm Password
                            InputField(
                                title: "Confirm Password",
                                text: $viewModel.signupConfirmPassword,
                                placeholder: "Repeat your password",
                                isSecure: true,
                                textContentType: .newPassword,
                                colors: colors
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit {
                                Task { await viewModel.signup(appState: appState) }
                            }
                        }

                        // Error
                        if let error = viewModel.signupError {
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Signup Button
                        PrimaryButton(
                            title: "Create Account",
                            isLoading: viewModel.isSigningUp,
                            isDisabled: !viewModel.isSignupValid,
                            colors: colors
                        ) {
                            Task { await viewModel.signup(appState: appState) }
                        }

                        // Terms
                        Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
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
    SignupView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
