import Foundation

// MARK: - Auth Service
class AuthService {
    static let shared = AuthService()
    private let client = APIClient.shared
    private let authManager = AuthManager.shared

    private init() {}

    // MARK: - Signup
    func signup(email: String, password: String, displayName: String, phoneNumber: String? = nil) async throws -> AuthResponse {
        struct SignupRequest: Codable {
            let email: String
            let password: String
            let displayName: String
            let phoneNumber: String?
        }

        let request = SignupRequest(
            email: email,
            password: password,
            displayName: displayName,
            phoneNumber: phoneNumber
        )

        return try await client.request(.signup, body: request)
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> AuthResponse {
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }

        let request = LoginRequest(email: email, password: password)
        return try await client.request(.login, body: request)
    }

    // MARK: - Logout
    func logout() async throws {
        try await client.requestNoContent(.logout)
        await authManager.clearTokens()
    }

    // MARK: - Forgot Password
    func forgotPassword(email: String) async throws -> MessageResponse {
        struct ForgotPasswordRequest: Codable {
            let email: String
        }

        let request = ForgotPasswordRequest(email: email)
        return try await client.request(.forgotPassword, body: request)
    }

    // MARK: - Reset Password
    func resetPassword(token: String, newPassword: String) async throws -> MessageResponse {
        struct ResetPasswordRequest: Codable {
            let token: String
            let newPassword: String
        }

        let request = ResetPasswordRequest(token: token, newPassword: newPassword)
        return try await client.request(.resetPassword, body: request)
    }

    // MARK: - Apple Sign In
    func appleSignIn(identityToken: String, authorizationCode: String,
                     appleUserId: String, email: String?,
                     fullName: String?) async throws -> AuthResponse {
        struct AppleSignInRequest: Codable {
            let identityToken: String
            let authorizationCode: String
            let appleUserId: String
            let email: String?
            let fullName: String?
        }

        let request = AppleSignInRequest(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            appleUserId: appleUserId,
            email: email,
            fullName: fullName
        )

        return try await client.request(.appleSignIn, body: request)
    }

    // MARK: - Get Current User
    func getCurrentUser() async throws -> User {
        return try await client.request(.currentUser)
    }

    // MARK: - Update User
    func updateUser(_ request: UpdateUserRequest) async throws -> User {
        return try await client.request(.updateUser, body: request)
    }

    // MARK: - Upload Profile Photo
    func uploadProfilePhoto(imageData: Data, mimeType: String) async throws -> ProfilePhotoResponse {
        let fileName = "profile.\(mimeType == "image/png" ? "png" : "jpg")"
        return try await client.upload(
            .uploadProfilePhoto,
            fileData: imageData,
            fileName: fileName,
            mimeType: mimeType,
            fieldName: "photo"
        )
    }

    // MARK: - Register Push Token
    func registerPushToken(token: String, platform: String = "ios") async throws -> MessageResponse {
        let request = PushTokenRequest(token: token, platform: platform)
        return try await client.request(.registerPushToken, body: request)
    }
}
