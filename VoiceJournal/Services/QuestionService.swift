import Foundation

// MARK: - Question Service
class QuestionService {
    static let shared = QuestionService()
    private let client = APIClient.shared

    private init() {}

    // MARK: - Create Question
    func createQuestion(journalId: String, _ request: CreateQuestionRequest) async throws -> Question {
        return try await client.request(.createQuestion(journalId: journalId), body: request)
    }

    // MARK: - Bulk Create Questions
    func bulkCreateQuestions(journalId: String, _ request: BulkCreateQuestionsRequest) async throws -> BulkCreateQuestionsResponse {
        return try await client.request(.bulkCreateQuestions(journalId: journalId), body: request)
    }

    // MARK: - Update Question
    func updateQuestion(journalId: String, questionId: String, _ request: UpdateQuestionRequest) async throws -> Question {
        return try await client.request(.updateQuestion(journalId: journalId, questionId: questionId), body: request)
    }

    // MARK: - Delete Question
    func deleteQuestion(journalId: String, questionId: String) async throws {
        try await client.requestNoContent(.deleteQuestion(journalId: journalId, questionId: questionId))
    }

    // MARK: - Reorder Questions
    func reorderQuestions(journalId: String, questionIds: [String]) async throws -> MessageResponse {
        let request = ReorderQuestionsRequest(questionIds: questionIds)
        return try await client.request(.reorderQuestions(journalId: journalId), body: request)
    }

    // MARK: - Assign Question
    func assignQuestion(questionId: String, personIds: [String]) async throws -> AssignQuestionResponse {
        let request = AssignQuestionRequest(personIds: personIds)
        return try await client.request(.assignQuestion(questionId: questionId), body: request)
    }

    // MARK: - Send Assignment
    func sendAssignment(assignmentId: String, channel: SendChannel, customMessage: String? = nil) async throws -> SendAssignmentResponse {
        let request = SendAssignmentRequest(channel: channel, customMessage: customMessage)
        return try await client.request(.sendAssignment(assignmentId: assignmentId), body: request)
    }

    // MARK: - Send Reminder
    func sendReminder(assignmentId: String, channel: SendChannel, customMessage: String? = nil) async throws -> SendAssignmentResponse {
        let request = SendAssignmentRequest(channel: channel, customMessage: customMessage)
        return try await client.request(.remindAssignment(assignmentId: assignmentId), body: request)
    }

    // MARK: - Delete Assignment
    func deleteAssignment(assignmentId: String) async throws {
        try await client.requestNoContent(.deleteAssignment(assignmentId: assignmentId))
    }
}
