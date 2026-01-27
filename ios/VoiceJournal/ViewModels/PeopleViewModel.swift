import SwiftUI
import Combine

// MARK: - People View Model
@MainActor
class PeopleViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var isLoading = false
    @Published var error: String?

    private let peopleService = PeopleService.shared

    func loadPeople() async {
        isLoading = true
        error = nil

        do {
            people = try await peopleService.listPeople()
        } catch {
            self.error = "Failed to load people"
        }

        isLoading = false
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
