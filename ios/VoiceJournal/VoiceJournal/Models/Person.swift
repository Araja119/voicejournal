import Foundation

// MARK: - Person
struct Person: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let relationship: String
    let email: String?
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let totalRecordings: Int?
    let pendingQuestions: Int?
    let createdAt: Date

    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }

    var displayRelationship: String {
        RelationshipType.displayName(for: relationship)
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Person Detail (with recordings)
struct PersonDetail: Codable, Identifiable {
    let id: String
    let name: String
    let relationship: String
    let email: String?
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let recordings: [PersonRecording]?
    let pendingAssignments: [PersonAssignment]?

    struct PersonRecording: Codable, Identifiable {
        let id: String
        let question: RecordingQuestion
        let journal: RecordingJournal
        let durationSeconds: Int?
        let recordedAt: Date?
    }

    struct RecordingQuestion: Codable {
        let id: String
        let questionText: String
    }

    struct RecordingJournal: Codable {
        let id: String
        let title: String
    }

    struct PersonAssignment: Codable, Identifiable {
        let id: String
        let question: RecordingQuestion
        let status: AssignmentStatus
        let sentAt: Date?
    }
}

// MARK: - People List Response
struct PeopleListResponse: Codable {
    let people: [Person]
}

// MARK: - Create Person Request
struct CreatePersonRequest: Codable {
    let name: String
    let relationship: String
    var email: String?
    var phoneNumber: String?
    var linkedUserId: String?
}

// MARK: - Update Person Request
struct UpdatePersonRequest: Codable {
    var name: String?
    var relationship: String?
    var email: String?
    var phoneNumber: String?
    var linkedUserId: String?
}

// MARK: - Person Photo Response
struct PersonPhotoResponse: Codable {
    let profilePhotoUrl: String
}

// MARK: - Relationship Type
struct RelationshipType: Codable, Identifiable, Equatable {
    let type: String
    let displayName: String
    let questionCount: Int
    var sampleQuestions: [String] = []

    var id: String { type }

    static func == (lhs: RelationshipType, rhs: RelationshipType) -> Bool {
        lhs.type == rhs.type
    }

    static let allTypes = [
        "parent", "grandparent", "spouse", "partner", "sibling",
        "child", "friend", "coworker", "boss", "mentor", "other"
    ]

    static func displayName(for type: String) -> String {
        switch type.lowercased() {
        case "parent": return "Parent"
        case "grandparent": return "Grandparent"
        case "spouse": return "Spouse"
        case "partner": return "Partner"
        case "sibling": return "Sibling"
        case "child": return "Child"
        case "friend": return "Friend"
        case "coworker": return "Coworker"
        case "boss": return "Boss"
        case "mentor": return "Mentor"
        case "other": return "Other"
        default: return type.capitalized
        }
    }
}

// MARK: - Relationships Response
struct RelationshipsResponse: Codable {
    let relationships: [RelationshipType]
}
