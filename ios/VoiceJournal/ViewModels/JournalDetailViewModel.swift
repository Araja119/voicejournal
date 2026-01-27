import Foundation

@MainActor
class JournalDetailViewModel: ObservableObject {
    @Published var journal: Journal?
    @Published var isLoading = false
    @Published var error: String?

    func loadJournal(id: String) async {
        isLoading = true
        error = nil

        do {
            journal = try await JournalService.shared.getJournal(id: id)
        } catch {
            self.error = "Failed to load journal"
            print("Error loading journal: \(error)")
        }

        isLoading = false
    }

    func deleteQuestion(questionId: String, journalId: String) async {
        do {
            try await QuestionService.shared.deleteQuestion(
                journalId: journalId,
                questionId: questionId
            )
            // Reload journal to update the list
            await loadJournal(id: journalId)
        } catch {
            self.error = "Failed to delete question"
        }
    }
}
