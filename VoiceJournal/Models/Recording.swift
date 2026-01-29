import Foundation

// MARK: - Recording
struct Recording: Codable, Identifiable, Equatable {
    let id: String
    let question: RecordingQuestionInfo?
    let person: RecordingPersonInfo?
    let journal: RecordingJournalInfo?
    let audioUrl: String
    let durationSeconds: Int?
    let transcription: String?
    let recordedAt: Date?

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id
    }

    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "--:--" }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Recording Info Types
struct RecordingQuestionInfo: Codable {
    let id: String
    let questionText: String
}

struct RecordingPersonInfo: Codable {
    let id: String
    let name: String
}

struct RecordingJournalInfo: Codable {
    let id: String
    let title: String
}

// MARK: - Recordings List Response
struct RecordingsListResponse: Codable {
    let recordings: [Recording]
    let total: Int
    let limit: Int
    let offset: Int
}

// MARK: - Recording Page Data (public)
struct RecordingPageData: Codable {
    let assignmentId: String
    let questionText: String
    let personName: String
    let requesterName: String
    let journalTitle: String
    let status: AssignmentStatus
    let alreadyAnswered: Bool
}

// MARK: - Upload Recording Response
struct UploadRecordingResponse: Codable {
    let message: String
    let recordingId: String
    let durationSeconds: Int?
}

// MARK: - Transcribe Response
struct TranscribeResponse: Codable {
    let message: String
    let estimatedTimeSeconds: Int?
}
