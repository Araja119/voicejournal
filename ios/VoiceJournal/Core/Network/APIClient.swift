import Foundation

// MARK: - API Client
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let authManager = AuthManager.shared
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.timeoutIntervalForResource = APIConfig.uploadTimeout
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Request Methods

    /// Perform a request with JSON body
    func request<T: Decodable, B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B? = nil as Empty?,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try await buildRequest(endpoint, body: body, queryItems: queryItems)
        return try await perform(request, endpoint: endpoint)
    }

    /// Perform a request without body
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try await buildRequest(endpoint, body: nil as Empty?, queryItems: queryItems)
        return try await perform(request, endpoint: endpoint)
    }

    /// Perform a request that returns no content
    func requestNoContent<B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B? = nil as Empty?
    ) async throws {
        let request = try await buildRequest(endpoint, body: body, queryItems: nil)
        try await performNoContent(request, endpoint: endpoint)
    }

    /// Perform a request that returns no content (no body)
    func requestNoContent(_ endpoint: APIEndpoint) async throws {
        let request = try await buildRequest(endpoint, body: nil as Empty?, queryItems: nil)
        try await performNoContent(request, endpoint: endpoint)
    }

    // MARK: - Multipart Upload

    /// Upload a file with multipart form data
    func upload<T: Decodable>(
        _ endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fieldName: String,
        additionalFields: [String: String]? = nil
    ) async throws -> T {
        let boundary = UUID().uuidString

        var request = try await buildBaseRequest(endpoint)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Add additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await perform(request, endpoint: endpoint)
    }

    // MARK: - Private Methods

    private func buildBaseRequest(_ endpoint: APIEndpoint) async throws -> URLRequest {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // Add auth header if required
        if endpoint.requiresAuth {
            let token = try await authManager.getValidAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func buildRequest<B: Encodable>(
        _ endpoint: APIEndpoint,
        body: B?,
        queryItems: [URLQueryItem]?
    ) async throws -> URLRequest {
        guard var components = URLComponents(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header if required
        if endpoint.requiresAuth {
            let token = try await authManager.getValidAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest, endpoint: APIEndpoint, isRetry: Bool = false) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: 0))
        }

        // Handle 401 with token refresh
        if httpResponse.statusCode == 401 && endpoint.requiresAuth && !isRetry {
            do {
                _ = try await authManager.refreshAccessToken()
                // Retry with new token
                var newRequest = request
                let newToken = try await authManager.getValidAccessToken()
                newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                return try await perform(newRequest, endpoint: endpoint, isRetry: true)
            } catch {
                throw NetworkError.unauthorized
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.from(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func performNoContent(_ request: URLRequest, endpoint: APIEndpoint, isRetry: Bool = false) async throws {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: 0))
        }

        // Handle 401 with token refresh
        if httpResponse.statusCode == 401 && endpoint.requiresAuth && !isRetry {
            do {
                _ = try await authManager.refreshAccessToken()
                var newRequest = request
                let newToken = try await authManager.getValidAccessToken()
                newRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                try await performNoContent(newRequest, endpoint: endpoint, isRetry: true)
                return
            } catch {
                throw NetworkError.unauthorized
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.from(statusCode: httpResponse.statusCode, data: data)
        }
    }
}

// MARK: - Empty Type for No Body
struct Empty: Codable {}
