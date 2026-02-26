import SwiftUI
import Combine
import AuthenticationServices

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    // MARK: - Authentication State
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: User?

    // MARK: - Theme
    @Published var isDarkMode = true

    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }

    // MARK: - Tutorial
    @Published var hasSeenTutorial: Bool = UserDefaults.standard.bool(forKey: "hasSeenTutorial")

    // MARK: - Navigation
    @Published var showingMenu = false

    // MARK: - Services
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        setupBindings()
        checkAuthState()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Load theme preference
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        if !UserDefaults.standard.contains(key: "isDarkMode") {
            isDarkMode = true // Default to dark mode
        }
    }

    // MARK: - Auth State Check
    func checkAuthState() {
        Task {
            isLoading = true

            // Check if we have stored tokens
            if await authManager.hasValidTokens {
                do {
                    // Check Apple credential revocation if applicable
                    if let appleUserId = UserDefaults.standard.string(forKey: "appleUserId") {
                        let provider = ASAuthorizationAppleIDProvider()
                        let state = try await provider.credentialState(forUserID: appleUserId)
                        if state == .revoked {
                            await authManager.clearTokens()
                            UserDefaults.standard.removeObject(forKey: "appleUserId")
                            self.isAuthenticated = false
                            isLoading = false
                            return
                        }
                    }

                    // Try to fetch current user to validate session
                    let user = try await AuthService.shared.getCurrentUser()
                    self.currentUser = user
                    self.isAuthenticated = true
                    // Re-register push token for returning users
                    NotificationManager.shared.registerTokenWithBackend()
                } catch {
                    // Token invalid, clear and go to login
                    await authManager.clearTokens()
                    self.isAuthenticated = false
                }
            } else {
                self.isAuthenticated = false
            }

            // Short delay for splash screen
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }

    // MARK: - Auth Actions
    func login(email: String, password: String) async throws {
        let response = try await AuthService.shared.login(email: email, password: password)
        await authManager.storeTokens(access: response.accessToken, refresh: response.refreshToken)
        self.currentUser = response.user
        self.isAuthenticated = true
        await requestPushPermission()
    }

    func signup(email: String, password: String, displayName: String) async throws {
        let response = try await AuthService.shared.signup(
            email: email,
            password: password,
            displayName: displayName
        )
        await authManager.storeTokens(access: response.accessToken, refresh: response.refreshToken)
        self.currentUser = response.user
        self.isAuthenticated = true
        await requestPushPermission()
    }

    func signInWithApple(identityToken: String, authorizationCode: String,
                         appleUserId: String, email: String?,
                         fullName: String?) async throws {
        let response = try await AuthService.shared.appleSignIn(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            appleUserId: appleUserId,
            email: email,
            fullName: fullName
        )
        await authManager.storeTokens(access: response.accessToken, refresh: response.refreshToken)
        self.currentUser = response.user
        self.isAuthenticated = true
        // Store Apple user ID for credential revocation checks
        UserDefaults.standard.set(appleUserId, forKey: "appleUserId")
        await requestPushPermission()
    }

    func logout() async {
        do {
            try await AuthService.shared.logout()
        } catch {
            // Logout locally even if server fails
            print("Logout error: \(error)")
        }
        await authManager.clearTokens()
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        self.hasSeenTutorial = false
        UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
        self.currentUser = nil
        self.isAuthenticated = false
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        try await AuthService.shared.deleteAccount()
        await authManager.clearTokens()
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        self.hasSeenTutorial = false
        UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
        self.currentUser = nil
        self.isAuthenticated = false
    }

    // MARK: - Tutorial
    func completeTutorial() {
        hasSeenTutorial = true
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
    }

    // MARK: - Push Notifications
    private func requestPushPermission() async {
        let granted = await NotificationManager.shared.requestPermission()
        if granted {
            print("[Push] Permission granted")
        }
    }

    // MARK: - Theme
    func toggleTheme() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
