import Foundation

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(statusCode: Int, message: String?)
    case unauthorized
    case forbidden
    case notFound
    case validationError(message: String, field: String?)
    case conflict(message: String)
    case rateLimited
    case serverError(message: String?)
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return message ?? "HTTP error \(statusCode)"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .validationError(let message, _):
            return message
        case .conflict(let message):
            return message
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let message):
            return message ?? "Server error. Please try again."
        case .networkUnavailable:
            return "No internet connection"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - API Error Response
struct APIErrorResponse: Codable {
    let error: APIError

    struct APIError: Codable {
        let code: String
        let message: String
        let details: APIErrorDetails?
    }

    struct APIErrorDetails: Codable {
        let field: String?
        let issues: [ValidationIssue]?
    }

    struct ValidationIssue: Codable {
        let code: String?
        let message: String?
        let path: [String]?
    }
}

// MARK: - Parse API Error
extension NetworkError {
    static func from(statusCode: Int, data: Data?) -> NetworkError {
        // Try to parse API error response
        if let data = data,
           let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            let error = errorResponse.error

            switch error.code {
            case "VALIDATION_ERROR":
                return .validationError(message: error.message, field: error.details?.field)
            case "UNAUTHORIZED":
                return .unauthorized
            case "FORBIDDEN":
                return .forbidden
            case "NOT_FOUND":
                return .notFound
            case "CONFLICT":
                return .conflict(message: error.message)
            case "RATE_LIMITED":
                return .rateLimited
            case "INTERNAL_ERROR":
                return .serverError(message: error.message)
            default:
                return .httpError(statusCode: statusCode, message: error.message)
            }
        }

        // Fallback based on status code
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(message: "Resource already exists")
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError(message: nil)
        default:
            return .httpError(statusCode: statusCode, message: nil)
        }
    }
}
