import Foundation

// MARK: - Journal
struct Journal: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let coverImageUrl: String?
    let privacySetting: PrivacySetting
    let shareCode: String?
    let shareLink: String?
    let owner: JournalOwner
    let dedicatedToPerson: JournalPerson?
    let isOwner: Bool
    let questionCount: Int
    let answeredCount: Int
    let personCount: Int
    let people: [JournalPerson]?
    let questions: [Question]?
    let createdAt: Date

    static func == (lhs: Journal, rhs: Journal) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Privacy Setting
enum PrivacySetting: String, Codable, CaseIterable {
    case `private` = "private"
    case shared = "shared"
    case `public` = "public"

    var displayName: String {
        switch self {
        case .private: return "Private"
        case .shared: return "Shared"
        case .public: return "Public"
        }
    }
}

// MARK: - Journal Owner
struct JournalOwner: Codable, Equatable {
    let id: String
    let displayName: String
}

// MARK: - Journal Person (simplified)
struct JournalPerson: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let relationship: String
    let profilePhotoUrl: String?
    let linkedUserId: String?

    static func == (lhs: JournalPerson, rhs: JournalPerson) -> Bool {
        lhs.id == rhs.id
    }

    /// Returns true if this person has explicit "self" relationship
    var isSelf: Bool {
        relationship.lowercased() == "self"
    }

    /// Returns true if this person is linked to the given user ID
    func isLinkedTo(userId: String) -> Bool {
        linkedUserId == userId
    }
}

// MARK: - Create Journal Request
struct CreateJournalRequest: Codable {
    let title: String
    var description: String?
    var privacySetting: String = "private"
    var dedicatedToPersonId: String?
}

// MARK: - Update Journal Request
struct UpdateJournalRequest: Codable {
    var title: String?
    var description: String?
    var privacySetting: String?
}

// MARK: - Journals List Response
struct JournalsListResponse: Codable {
    let journals: [Journal]
}

// MARK: - Cover Image Response
struct CoverImageResponse: Codable {
    let coverImageUrl: String
}

// MARK: - Collaborator
struct Collaborator: Codable, Identifiable, Equatable {
    let id: String
    let user: CollaboratorUser?
    let email: String?
    let phoneNumber: String?
    let permissionLevel: PermissionLevel
    let invitedAt: Date
    let acceptedAt: Date?

    static func == (lhs: Collaborator, rhs: Collaborator) -> Bool {
        lhs.id == rhs.id
    }
}

struct CollaboratorUser: Codable, Equatable {
    let id: String
    let displayName: String
    let email: String
}

enum PermissionLevel: String, Codable, CaseIterable {
    case view = "view"
    case edit = "edit"
    case admin = "admin"

    var displayName: String {
        switch self {
        case .view: return "View Only"
        case .edit: return "Can Edit"
        case .admin: return "Admin"
        }
    }
}

// MARK: - Collaborators Response
struct CollaboratorsResponse: Codable {
    let collaborators: [Collaborator]
}

// MARK: - Add Collaborator Request
struct AddCollaboratorRequest: Codable {
    var email: String?
    var phoneNumber: String?
    var permissionLevel: String = "view"
}
