import Foundation

// MARK: - Journal Service
class JournalService {
    static let shared = JournalService()
    private let client = APIClient.shared

    private init() {}

    // MARK: - List Journals
    func listJournals(owned: Bool? = nil, shared: Bool? = nil) async throws -> [Journal] {
        var queryItems: [URLQueryItem] = []
        if let owned = owned {
            queryItems.append(URLQueryItem(name: "owned", value: String(owned)))
        }
        if let shared = shared {
            queryItems.append(URLQueryItem(name: "shared", value: String(shared)))
        }

        let response: JournalsListResponse = try await client.request(
            .journals,
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
        return response.journals
    }

    // MARK: - Get Journal
    func getJournal(id: String) async throws -> Journal {
        return try await client.request(.journal(id: id))
    }

    // MARK: - Create Journal
    func createJournal(_ request: CreateJournalRequest) async throws -> Journal {
        return try await client.request(.createJournal, body: request)
    }

    // MARK: - Update Journal
    func updateJournal(id: String, _ request: UpdateJournalRequest) async throws -> Journal {
        return try await client.request(.updateJournal(id: id), body: request)
    }

    // MARK: - Delete Journal
    func deleteJournal(id: String) async throws {
        try await client.requestNoContent(.deleteJournal(id: id))
    }

    // MARK: - Upload Cover Image
    func uploadCoverImage(journalId: String, imageData: Data, mimeType: String) async throws -> CoverImageResponse {
        let fileName = "cover.\(mimeType == "image/png" ? "png" : "jpg")"
        return try await client.upload(
            .uploadCoverImage(journalId: journalId),
            fileData: imageData,
            fileName: fileName,
            mimeType: mimeType,
            fieldName: "image"
        )
    }

    // MARK: - Get Shared Journal
    func getSharedJournal(shareCode: String) async throws -> Journal {
        return try await client.request(.sharedJournal(shareCode: shareCode))
    }

    // MARK: - List Collaborators
    func listCollaborators(journalId: String) async throws -> [Collaborator] {
        let response: CollaboratorsResponse = try await client.request(.collaborators(journalId: journalId))
        return response.collaborators
    }

    // MARK: - Add Collaborator
    func addCollaborator(journalId: String, _ request: AddCollaboratorRequest) async throws -> Collaborator {
        return try await client.request(.addCollaborator(journalId: journalId), body: request)
    }

    // MARK: - Remove Collaborator
    func removeCollaborator(journalId: String, collaboratorId: String) async throws {
        try await client.requestNoContent(.removeCollaborator(journalId: journalId, collaboratorId: collaboratorId))
    }
}
