import AuthenticationServices
import CryptoKit

@MainActor
class AppleSignInManager: NSObject {

    private var continuation: CheckedContinuation<ASAuthorization, Error>?

    struct AppleSignInResult {
        let identityToken: String
        let authorizationCode: String
        let userId: String
        let email: String?
        let fullName: PersonNameComponents?
    }

    func signIn() async throws -> AppleSignInResult {
        let nonce = randomNonceString()

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorization = try await performRequest(request)

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleSignInError.invalidCredential
        }

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AppleSignInError.missingIdentityToken
        }

        guard let authCodeData = credential.authorizationCode,
              let authorizationCode = String(data: authCodeData, encoding: .utf8) else {
            throw AppleSignInError.missingAuthorizationCode
        }

        return AppleSignInResult(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            userId: credential.user,
            email: credential.email,
            fullName: credential.fullName
        )
    }

    private func performRequest(_ request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            fatalError("Unable to generate nonce: \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            continuation?.resume(returning: authorization)
            continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

// MARK: - Error

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case missingIdentityToken
    case missingAuthorizationCode

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid Apple credential"
        case .missingIdentityToken: return "Missing identity token from Apple"
        case .missingAuthorizationCode: return "Missing authorization code from Apple"
        }
    }
}
