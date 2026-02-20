import Foundation

// MARK: - Assignment
struct Assignment: Codable, Identifiable, Equatable {
    let id: String
    let personId: String
    let personName: String?
    let personProfilePhotoUrl: String?
    let status: AssignmentStatus
    let uniqueLinkToken: String?
    let recordingLink: String?
    let recording: AssignmentRecording?
    let sentAt: Date?
    let viewedAt: Date?
    let answeredAt: Date?
    let reminderCount: Int?
    let lastReminderAt: Date?

    static func == (lhs: Assignment, rhs: Assignment) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Assignment Status
enum AssignmentStatus: String, Codable {
    case pending = "pending"
    case sent = "sent"
    case viewed = "viewed"
    case answered = "answered"

    var displayName: String {
        switch self {
        case .pending: return "Not Sent"
        case .sent: return "Sent"
        case .viewed: return "Viewed"
        case .answered: return "Answered"
        }
    }

    var color: String {
        switch self {
        case .pending: return "gray"
        case .sent: return "orange"
        case .viewed: return "blue"
        case .answered: return "green"
        }
    }
}

// MARK: - Assignment Recording (nested)
struct AssignmentRecording: Codable, Identifiable {
    let id: String
    let durationSeconds: Int?
    let recordedAt: Date?
}

// MARK: - Send Assignment Request
struct SendAssignmentRequest: Codable {
    let channel: SendChannel
    var customMessage: String?
}

enum SendChannel: String, Codable {
    case sms = "sms"
    case email = "email"
    case push = "push"
    case share = "share"
}

// MARK: - Send Assignment Response
struct SendAssignmentResponse: Codable {
    let message: String
    let sentVia: String?
    let sentAt: Date?
    let reminderCount: Int?
    let nextEligibleAt: Date?
}
