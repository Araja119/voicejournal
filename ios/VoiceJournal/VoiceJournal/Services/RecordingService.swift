import Foundation

// MARK: - Recording Service
class RecordingService {
    static let shared = RecordingService()
    private let client = APIClient.shared

    private init() {}

    // MARK: - List Recordings
    func listRecordings(
        journalId: String? = nil,
        personId: String? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> RecordingsListResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        if let journalId = journalId {
            queryItems.append(URLQueryItem(name: "journal_id", value: journalId))
        }
        if let personId = personId {
            queryItems.append(URLQueryItem(name: "person_id", value: personId))
        }

        return try await client.request(.recordings, queryItems: queryItems)
    }

    // MARK: - Get Recording
    func getRecording(id: String) async throws -> Recording {
        return try await client.request(.recording(id: id))
    }

    // MARK: - Delete Recording
    func deleteRecording(id: String) async throws {
        try await client.requestNoContent(.deleteRecording(id: id))
    }

    // MARK: - Request Transcription
    func requestTranscription(recordingId: String) async throws -> TranscribeResponse {
        return try await client.request(.transcribeRecording(id: recordingId))
    }

    // MARK: - Get Recording Page Data (Public)
    func getRecordingPageData(linkToken: String) async throws -> RecordingPageData {
        return try await client.request(.recordingPage(linkToken: linkToken))
    }

    // MARK: - Upload Recording (Public)
    func uploadRecording(linkToken: String, audioData: Data, durationSeconds: Int?) async throws -> UploadRecordingResponse {
        var additionalFields: [String: String]? = nil
        if let duration = durationSeconds {
            additionalFields = ["duration_seconds": String(duration)]
        }

        return try await client.upload(
            .uploadRecording(linkToken: linkToken),
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/mp4",
            fieldName: "audio",
            additionalFields: additionalFields
        )
    }

    // MARK: - Upload Recording (Authenticated - Self Recording)
    /// Upload a recording as the authenticated user for self-journaling
    func uploadRecordingAuthenticated(
        journalId: String,
        questionId: String,
        audioData: Data,
        durationSeconds: Int?,
        idempotencyKey: String
    ) async throws -> Recording {
        var additionalFields: [String: String]? = nil
        if let duration = durationSeconds {
            additionalFields = ["duration_seconds": String(duration)]
        }

        return try await client.upload(
            .uploadAuthenticatedRecording(journalId: journalId, questionId: questionId),
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/mp4",
            fieldName: "audio",
            additionalFields: additionalFields,
            additionalHeaders: ["Idempotency-Key": idempotencyKey]
        )
    }
}
