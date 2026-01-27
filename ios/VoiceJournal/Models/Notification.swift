import Foundation

// MARK: - App Notification
struct AppNotification: Codable, Identifiable, Equatable {
    let id: String
    let notificationType: NotificationType
    let title: String?
    let body: String?
    let relatedAssignmentId: String?
    let relatedRecordingId: String?
    let sentAt: Date
    let readAt: Date?

    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }

    var isRead: Bool {
        readAt != nil
    }
}

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case recordingReceived = "recording_received"
    case assignmentSent = "assignment_sent"
    case reminderSent = "reminder_sent"
    case collaboratorAdded = "collaborator_added"
    case transcriptionComplete = "transcription_complete"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = NotificationType(rawValue: rawValue) ?? .unknown
    }

    var icon: String {
        switch self {
        case .recordingReceived: return "waveform"
        case .assignmentSent: return "paperplane.fill"
        case .reminderSent: return "bell.fill"
        case .collaboratorAdded: return "person.badge.plus"
        case .transcriptionComplete: return "text.alignleft"
        case .unknown: return "bell"
        }
    }
}

// MARK: - Notifications Response
struct NotificationsResponse: Codable {
    let notifications: [AppNotification]
    let total: Int
    let limit: Int
    let offset: Int
}

// MARK: - Message Response
struct MessageResponse: Codable {
    let message: String
}

// MARK: - Dashboard Stats
struct DashboardStats: Codable {
    let totalJournals: Int
    let totalQuestionsSent: Int
    let totalRecordingsReceived: Int
    let pendingAssignments: Int
    let answeredAssignments: Int
    let recentActivity: [RecentActivity]?
}

struct RecentActivity: Codable, Identifiable {
    let type: String
    let description: String
    let timestamp: Date

    var id: String { "\(type)-\(timestamp.timeIntervalSince1970)" }
}
