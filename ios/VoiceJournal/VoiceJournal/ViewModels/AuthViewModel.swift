import SwiftUI
import Combine
import AuthenticationServices

// MARK: - Auth View Model
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Login State
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var loginError: String?
    @Published var isLoggingIn = false

    // MARK: - Signup State
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var signupConfirmPassword = ""
    @Published var signupDisplayName = ""
    @Published var signupError: String?
    @Published var isSigningUp = false

    // MARK: - Apple Sign In State
    @Published var isAppleSigningIn = false
    @Published var appleSignInError: String?

    // MARK: - Forgot Password State
    @Published var forgotEmail = ""
    @Published var forgotError: String?
    @Published var forgotSuccess = false
    @Published var isSendingReset = false

    // MARK: - Validation
    var isLoginValid: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty && loginPassword.count >= 8
    }

    var isSignupValid: Bool {
        !signupEmail.isEmpty &&
        !signupPassword.isEmpty &&
        !signupDisplayName.isEmpty &&
        signupPassword.count >= 8 &&
        signupPassword == signupConfirmPassword
    }

    var isForgotValid: Bool {
        !forgotEmail.isEmpty && forgotEmail.contains("@")
    }

    var signupPasswordError: String? {
        if signupPassword.isEmpty { return nil }
        if signupPassword.count < 8 { return "Password must be at least 8 characters" }
        if !signupConfirmPassword.isEmpty && signupPassword != signupConfirmPassword {
            return "Passwords don't match"
        }
        return nil
    }

    // MARK: - Actions
    func login(appState: AppState) async {
        guard isLoginValid else {
            loginError = "Please enter valid email and password"
            return
        }

        isLoggingIn = true
        loginError = nil

        do {
            try await appState.login(email: loginEmail, password: loginPassword)
            clearLoginForm()
        } catch let error as NetworkError {
            loginError = error.localizedDescription
        } catch {
            loginError = "Login failed. Please try again."
        }

        isLoggingIn = false
    }

    func signup(appState: AppState) async {
        guard isSignupValid else {
            signupError = "Please fill in all fields correctly"
            return
        }

        isSigningUp = true
        signupError = nil

        do {
            try await appState.signup(
                email: signupEmail,
                password: signupPassword,
                displayName: signupDisplayName
            )
            clearSignupForm()
        } catch let error as NetworkError {
            signupError = error.localizedDescription
        } catch {
            signupError = "Signup failed. Please try again."
        }

        isSigningUp = false
    }

    func sendPasswordReset() async {
        guard isForgotValid else {
            forgotError = "Please enter a valid email"
            return
        }

        isSendingReset = true
        forgotError = nil
        forgotSuccess = false

        do {
            _ = try await AuthService.shared.forgotPassword(email: forgotEmail)
            forgotSuccess = true
        } catch let error as NetworkError {
            forgotError = error.localizedDescription
        } catch {
            forgotError = "Failed to send reset email. Please try again."
        }

        isSendingReset = false
    }

    // MARK: - Apple Sign In
    func signInWithApple(appState: AppState) async {
        isAppleSigningIn = true
        appleSignInError = nil

        do {
            let manager = AppleSignInManager()
            let result = try await manager.signIn()

            // Build full name from components
            var fullName: String? = nil
            if let nameComponents = result.fullName {
                let formatter = PersonNameComponentsFormatter()
                let name = formatter.string(from: nameComponents)
                if !name.isEmpty {
                    fullName = name
                }
            }

            try await appState.signInWithApple(
                identityToken: result.identityToken,
                authorizationCode: result.authorizationCode,
                appleUserId: result.userId,
                email: result.email,
                fullName: fullName
            )
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User cancelled — do nothing
        } catch let error as NetworkError {
            appleSignInError = error.localizedDescription
        } catch {
            appleSignInError = "Apple Sign In failed. Please try again."
        }

        isAppleSigningIn = false
    }

    // MARK: - Clear Forms
    private func clearLoginForm() {
        loginEmail = ""
        loginPassword = ""
        loginError = nil
    }

    private func clearSignupForm() {
        signupEmail = ""
        signupPassword = ""
        signupConfirmPassword = ""
        signupDisplayName = ""
        signupError = nil
    }

    func clearForgotForm() {
        forgotEmail = ""
        forgotError = nil
        forgotSuccess = false
    }
}
