import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var showingForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Welcome back")
                                .font(AppTypography.headlineLarge)
                                .foregroundColor(colors.textPrimary)

                            Text("Log in to continue")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.xl)

                        // Form
                        VStack(spacing: Theme.Spacing.md) {
                            // Email
                            InputField(
                                title: "Email",
                                text: $viewModel.loginEmail,
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
                                text: $viewModel.loginPassword,
                                placeholder: "Enter password",
                                isSecure: true,
                                textContentType: .password,
                                colors: colors
                            )
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                Task { await viewModel.login(appState: appState) }
                            }

                            // Forgot Password
                            HStack {
                                Spacer()
                                Button(action: { showingForgotPassword = true }) {
                                    Text("Forgot password?")
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(colors.accentPrimary)
                                }
                            }
                        }

                        // Error
                        if let error = viewModel.loginError {
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Login Button
                        PrimaryButton(
                            title: "Log In",
                            isLoading: viewModel.isLoggingIn,
                            isDisabled: !viewModel.isLoginValid,
                            colors: colors
                        ) {
                            Task { await viewModel.login(appState: appState) }
                        }

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
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
