import Foundation

// MARK: - Auth Manager
actor AuthManager {
    static let shared = AuthManager()

    private let keychain = KeychainManager.shared
    private var isRefreshing = false
    private var pendingRequests: [CheckedContinuation<String, Error>] = []

    private init() {}

    // MARK: - Token Access
    var accessToken: String? {
        get async {
            await keychain.getAccessToken()
        }
    }

    var refreshToken: String? {
        get async {
            await keychain.getRefreshToken()
        }
    }

    var hasValidTokens: Bool {
        get async {
            await keychain.getAccessToken() != nil && await keychain.getRefreshToken() != nil
        }
    }

    // MARK: - Token Management
    func storeTokens(access: String, refresh: String) async {
        await keychain.setAccessToken(access)
        await keychain.setRefreshToken(refresh)
    }

    func clearTokens() async {
        await keychain.clearAll()
    }

    // MARK: - Token Refresh
    func getValidAccessToken() async throws -> String {
        // Check if we have a valid token
        if let token = await keychain.getAccessToken() {
            return token
        }

        // Need to refresh
        return try await refreshAccessToken()
    }

    func refreshAccessToken() async throws -> String {
        // If already refreshing, wait for result
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests.append(continuation)
            }
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            guard let refreshToken = await keychain.getRefreshToken() else {
                throw NetworkError.unauthorized
            }

            // Make refresh request
            let newToken = try await performRefresh(refreshToken: refreshToken)

            // Store new token
            await keychain.setAccessToken(newToken)

            // Resume pending requests
            for continuation in pendingRequests {
                continuation.resume(returning: newToken)
            }
            pendingRequests.removeAll()

            return newToken
        } catch {
            // Fail all pending requests
            for continuation in pendingRequests {
                continuation.resume(throwing: error)
            }
            pendingRequests.removeAll()

            // Clear tokens on auth failure
            if case NetworkError.unauthorized = error {
                await clearTokens()
            }

            throw error
        }
    }

    private func performRefresh(refreshToken: String) async throws -> String {
        guard let url = APIEndpoint.refresh.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: 0))
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.from(statusCode: httpResponse.statusCode, data: data)
        }

        struct RefreshResponse: Codable {
            let accessToken: String

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
            }
        }

        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
        return refreshResponse.accessToken
    }
}
