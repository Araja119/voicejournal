import SwiftUI
import Combine

// MARK: - Journal View Model
@MainActor
class JournalViewModel: ObservableObject {
    @Published var journals: [Journal] = []
    @Published var isLoading = false
    @Published var error: String?

    private let journalService = JournalService.shared

    func loadJournals() async {
        isLoading = true
        error = nil

        do {
            journals = try await journalService.listJournals()
        } catch {
            self.error = "Failed to load journals"
        }

        isLoading = false
    }

    func createJournal(title: String, description: String?, privacySetting: String) async throws -> Journal {
        let request = CreateJournalRequest(
            title: title,
            description: description,
            privacySetting: privacySetting
        )
        let journal = try await journalService.createJournal(request)
        journals.insert(journal, at: 0)
        return journal
    }

    func deleteJournal(id: String) async -> Bool {
        do {
            try await journalService.deleteJournal(id: id)
            journals.removeAll { $0.id == id }
            return true
        } catch {
            self.error = "Failed to delete journal"
            return false
        }
    }
}
