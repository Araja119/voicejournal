import Foundation

// MARK: - Question
struct Question: Codable, Identifiable, Equatable {
    let id: String
    let questionText: String
    let source: QuestionSource
    let displayOrder: Int
    let assignments: [Assignment]?

    static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.id == rhs.id
    }

    var hasAnsweredAssignment: Bool {
        assignments?.contains { $0.status == .answered } ?? false
    }

    var answeredAssignments: [Assignment] {
        assignments?.filter { $0.status == .answered } ?? []
    }

    var pendingAssignments: [Assignment] {
        assignments?.filter { $0.status != .answered } ?? []
    }
}

// MARK: - Question Source
enum QuestionSource: String, Codable {
    case custom = "custom"
    case template = "template"
}

// MARK: - Create Question Request
struct CreateQuestionRequest: Codable {
    let questionText: String
    var templateId: String?
    var assignToPersonIds: [String]?
}

// MARK: - Bulk Create Questions Request
struct BulkCreateQuestionsRequest: Codable {
    let questions: [BulkQuestionItem]
    var assignToPersonIds: [String]?

    struct BulkQuestionItem: Codable {
        let questionText: String
        var templateId: String?
    }
}

// MARK: - Bulk Create Response
struct BulkCreateQuestionsResponse: Codable {
    let questions: [Question]
}

// MARK: - Update Question Request
struct UpdateQuestionRequest: Codable {
    var questionText: String?
    var displayOrder: Int?
}

// MARK: - Reorder Questions Request
struct ReorderQuestionsRequest: Codable {
    let questionIds: [String]
}

// MARK: - Assign Question Request
struct AssignQuestionRequest: Codable {
    let personIds: [String]
}

// MARK: - Assign Question Response
struct AssignQuestionResponse: Codable {
    let assignments: [Assignment]
}
