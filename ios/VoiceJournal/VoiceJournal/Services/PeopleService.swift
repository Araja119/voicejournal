import Foundation

// MARK: - People Service
class PeopleService {
    static let shared = PeopleService()
    private let client = APIClient.shared

    private init() {}

    // MARK: - List People
    func listPeople() async throws -> [Person] {
        let response: PeopleListResponse = try await client.request(.people)
        return response.people
    }

    // MARK: - Get Person
    func getPerson(id: String) async throws -> PersonDetail {
        return try await client.request(.person(id: id))
    }

    // MARK: - Create Person
    func createPerson(_ request: CreatePersonRequest) async throws -> Person {
        return try await client.request(.createPerson, body: request)
    }

    // MARK: - Update Person
    func updatePerson(id: String, _ request: UpdatePersonRequest) async throws -> Person {
        return try await client.request(.updatePerson(id: id), body: request)
    }

    // MARK: - Delete Person
    func deletePerson(id: String) async throws {
        try await client.requestNoContent(.deletePerson(id: id))
    }

    // MARK: - Ensure "Myself" Person Exists
    /// Checks if a "self" person record exists, creates one if not
    func ensureMyselfExists(user: User) async throws -> Person {
        // First, check if "myself" person already exists
        let people = try await listPeople()
        if let myself = people.first(where: { $0.isSelf }) {
            return myself
        }

        // Create "myself" person if doesn't exist
        let request = CreatePersonRequest(
            name: user.displayName,
            relationship: "self",
            email: user.email,
            phoneNumber: user.phoneNumber,
            linkedUserId: user.id
        )
        return try await createPerson(request)
    }

    // MARK: - Upload Person Photo
    func uploadPhoto(personId: String, imageData: Data, mimeType: String) async throws -> PersonPhotoResponse {
        let fileName = "photo.\(mimeType == "image/png" ? "png" : "jpg")"
        return try await client.upload(
            .uploadPersonPhoto(personId: personId),
            fileData: imageData,
            fileName: fileName,
            mimeType: mimeType,
            fieldName: "photo"
        )
    }
}
