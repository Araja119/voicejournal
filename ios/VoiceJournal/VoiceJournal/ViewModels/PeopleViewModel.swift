import SwiftUI
import Combine

// MARK: - People View Model
@MainActor
class PeopleViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var myselfPerson: Person?
    @Published var isLoading = false
    @Published var error: String?

    private let peopleService = PeopleService.shared

    func loadPeople() async {
        isLoading = true
        error = nil

        do {
            let allPeople = try await peopleService.listPeople()
            // Update myselfPerson from API if available, otherwise keep existing (synthetic)
            if let apiMyself = allPeople.first(where: { $0.isSelf }) {
                myselfPerson = apiMyself
            }
            people = allPeople.filter { !$0.isSelf }
        } catch {
            self.error = "Failed to load people"
        }

        isLoading = false
    }

    /// Creates or updates a synthetic "Myself" person from the current user for display purposes.
    /// If a real person from the API exists, it won't be overridden.
    func refreshSyntheticMyself(from user: User) {
        // If we have a real "myself" person from the database (not synthetic), don't override
        if let existing = myselfPerson, !existing.id.hasPrefix("myself-") { return }

        // Create or update synthetic person with latest user data
        myselfPerson = Person(
            id: "myself-\(user.id)",
            name: user.displayName,
            relationship: "self",
            email: user.email,
            phoneNumber: user.phoneNumber,
            profilePhotoUrl: user.profilePhotoUrl,
            totalRecordings: nil,
            pendingQuestions: nil,
            createdAt: user.createdAt
        )
    }

    /// Ensures a real "Myself" person record exists in the database
    func ensureRealMyselfExists(user: User) async -> Person? {
        do {
            let myself = try await peopleService.ensureMyselfExists(user: user)
            myselfPerson = myself
            return myself
        } catch {
            print("Failed to create myself person in database: \(error)")
            return nil
        }
    }

    func deletePerson(id: String) async -> Bool {
        do {
            try await peopleService.deletePerson(id: id)
            people.removeAll { $0.id == id }
            return true
        } catch {
            self.error = "Failed to delete person"
            return false
        }
    }
}
