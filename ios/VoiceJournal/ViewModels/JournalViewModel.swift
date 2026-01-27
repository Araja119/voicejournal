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

// MARK: - Journal Detail View Model
@MainActor
class JournalDetailViewModel: ObservableObject {
    @Published var journal: Journal?
    @Published var isLoading = false
    @Published var error: String?

    private let journalService = JournalService.shared
    private let questionService = QuestionService.shared

    func loadJournal(id: String) async {
        isLoading = true
        error = nil

        do {
            journal = try await journalService.getJournal(id: id)
        } catch {
            self.error = "Failed to load journal"
        }

        isLoading = false
    }

    func addQuestion(text: String, assignToPersonIds: [String]? = nil) async throws {
        guard let journalId = journal?.id else { return }

        let request = CreateQuestionRequest(
            questionText: text,
            assignToPersonIds: assignToPersonIds
        )
        _ = try await questionService.createQuestion(journalId: journalId, request)

        // Reload journal to get updated questions
        await loadJournal(id: journalId)
    }

    func deleteQuestion(questionId: String) async -> Bool {
        guard let journalId = journal?.id else { return false }

        do {
            try await questionService.deleteQuestion(journalId: journalId, questionId: questionId)
            await loadJournal(id: journalId)
            return true
        } catch {
            self.error = "Failed to delete question"
            return false
        }
    }
}
