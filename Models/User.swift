import Foundation

// MARK: - User
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let subscriptionTier: String
    let createdAt: Date

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

// MARK: - Update User Request
struct UpdateUserRequest: Codable {
    var displayName: String?
    var phoneNumber: String?
}

// MARK: - Profile Photo Response
struct ProfilePhotoResponse: Codable {
    let profilePhotoUrl: String
}

// MARK: - Push Token Request
struct PushTokenRequest: Codable {
    let token: String
    let platform: String
}
