import Foundation

// MARK: - API Configuration
enum APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:3000/v1"
    #else
    static let baseURL = "https://api.voicejournal.app/v1"
    #endif

    static let timeout: TimeInterval = 30
    static let uploadTimeout: TimeInterval = 120
}

// MARK: - API Endpoint
enum APIEndpoint {
    // Auth
    case signup
    case login
    case refresh
    case logout
    case forgotPassword
    case resetPassword

    // Users
    case currentUser
    case updateUser
    case uploadProfilePhoto
    case registerPushToken

    // Journals
    case journals
    case journal(id: String)
    case createJournal
    case updateJournal(id: String)
    case deleteJournal(id: String)
    case uploadCoverImage(journalId: String)
    case collaborators(journalId: String)
    case addCollaborator(journalId: String)
    case removeCollaborator(journalId: String, collaboratorId: String)
    case sharedJournal(shareCode: String)

    // People
    case people
    case person(id: String)
    case createPerson
    case updatePerson(id: String)
    case deletePerson(id: String)
    case uploadPersonPhoto(personId: String)

    // Templates
    case templates
    case relationships

    // Questions
    case createQuestion(journalId: String)
    case bulkCreateQuestions(journalId: String)
    case updateQuestion(journalId: String, questionId: String)
    case deleteQuestion(journalId: String, questionId: String)
    case reorderQuestions(journalId: String)
    case assignQuestion(questionId: String)
    case suggestedQuestions(journalId: String)

    // Assignments
    case sendAssignment(assignmentId: String)
    case remindAssignment(assignmentId: String)
    case deleteAssignment(assignmentId: String)

    // Recordings (public)
    case recordingPage(linkToken: String)
    case uploadRecording(linkToken: String)

    // Recordings (authenticated)
    case recordings
    case recording(id: String)
    case deleteRecording(id: String)
    case transcribeRecording(id: String)

    // Notifications
    case notifications
    case markNotificationRead(id: String)
    case markAllNotificationsRead

    // Stats
    case dashboardStats

    // MARK: - Path
    var path: String {
        switch self {
        // Auth
        case .signup: return "/auth/signup"
        case .login: return "/auth/login"
        case .refresh: return "/auth/refresh"
        case .logout: return "/auth/logout"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword: return "/auth/reset-password"

        // Users
        case .currentUser, .updateUser: return "/users/me"
        case .uploadProfilePhoto: return "/users/me/profile-photo"
        case .registerPushToken: return "/users/me/push-token"

        // Journals
        case .journals, .createJournal: return "/journals"
        case .journal(let id), .updateJournal(let id), .deleteJournal(let id):
            return "/journals/\(id)"
        case .uploadCoverImage(let journalId):
            return "/journals/\(journalId)/cover-image"
        case .collaborators(let journalId), .addCollaborator(let journalId):
            return "/journals/\(journalId)/collaborators"
        case .removeCollaborator(let journalId, let collaboratorId):
            return "/journals/\(journalId)/collaborators/\(collaboratorId)"
        case .sharedJournal(let shareCode):
            return "/journals/shared/\(shareCode)"

        // People
        case .people, .createPerson: return "/people"
        case .person(let id), .updatePerson(let id), .deletePerson(let id):
            return "/people/\(id)"
        case .uploadPersonPhoto(let personId):
            return "/people/\(personId)/photo"

        // Templates
        case .templates: return "/templates"
        case .relationships: return "/templates/relationships"

        // Questions
        case .createQuestion(let journalId):
            return "/journals/\(journalId)/questions"
        case .bulkCreateQuestions(let journalId):
            return "/journals/\(journalId)/questions/bulk"
        case .updateQuestion(let journalId, let questionId), .deleteQuestion(let journalId, let questionId):
            return "/journals/\(journalId)/questions/\(questionId)"
        case .reorderQuestions(let journalId):
            return "/journals/\(journalId)/questions/reorder"
        case .assignQuestion(let questionId):
            return "/questions/\(questionId)/assign"
        case .suggestedQuestions(let journalId):
            return "/journals/\(journalId)/suggested-questions"

        // Assignments
        case .sendAssignment(let assignmentId):
            return "/assignments/\(assignmentId)/send"
        case .remindAssignment(let assignmentId):
            return "/assignments/\(assignmentId)/remind"
        case .deleteAssignment(let assignmentId):
            return "/assignments/\(assignmentId)"

        // Recordings (public)
        case .recordingPage(let linkToken):
            return "/record/\(linkToken)"
        case .uploadRecording(let linkToken):
            return "/record/\(linkToken)/upload"

        // Recordings (authenticated)
        case .recordings: return "/recordings"
        case .recording(let id), .deleteRecording(let id):
            return "/recordings/\(id)"
        case .transcribeRecording(let id):
            return "/recordings/\(id)/transcribe"

        // Notifications
        case .notifications: return "/notifications"
        case .markNotificationRead(let id):
            return "/notifications/\(id)/read"
        case .markAllNotificationsRead:
            return "/notifications/read-all"

        // Stats
        case .dashboardStats: return "/stats/dashboard"
        }
    }

    // MARK: - HTTP Method
    var method: HTTPMethod {
        switch self {
        // GET
        case .currentUser, .journals, .journal, .collaborators, .sharedJournal,
             .people, .person, .templates, .relationships,
             .recordingPage, .recordings, .recording,
             .notifications, .dashboardStats, .suggestedQuestions:
            return .get

        // POST
        case .signup, .login, .refresh, .logout, .forgotPassword, .resetPassword,
             .uploadProfilePhoto, .registerPushToken,
             .createJournal, .uploadCoverImage, .addCollaborator,
             .createPerson, .uploadPersonPhoto,
             .createQuestion, .bulkCreateQuestions, .assignQuestion,
             .sendAssignment, .remindAssignment,
             .uploadRecording, .transcribeRecording,
             .markAllNotificationsRead:
            return .post

        // PATCH
        case .updateUser, .updateJournal, .updatePerson, .updateQuestion, .reorderQuestions,
             .markNotificationRead:
            return .patch

        // DELETE
        case .deleteJournal, .removeCollaborator, .deletePerson, .deleteQuestion,
             .deleteAssignment, .deleteRecording:
            return .delete
        }
    }

    // MARK: - Requires Auth
    var requiresAuth: Bool {
        switch self {
        case .signup, .login, .refresh, .forgotPassword, .resetPassword,
             .templates, .relationships,
             .recordingPage, .uploadRecording:
            return false
        default:
            return true
        }
    }

    // MARK: - Full URL
    var url: URL? {
        URL(string: APIConfig.baseURL + path)
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}
