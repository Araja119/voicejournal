import SwiftUI
import Combine

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
                    // Try to fetch current user to validate session
                    let user = try await AuthService.shared.getCurrentUser()
                    self.currentUser = user
                    self.isAuthenticated = true
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
    }

    func logout() async {
        do {
            try await AuthService.shared.logout()
        } catch {
            // Logout locally even if server fails
            print("Logout error: \(error)")
        }
        await authManager.clearTokens()
        self.currentUser = nil
        self.isAuthenticated = false
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
