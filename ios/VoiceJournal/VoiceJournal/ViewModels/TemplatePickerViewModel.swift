import SwiftUI
import Combine

// MARK: - Template Picker View Model
@MainActor
class TemplatePickerViewModel: ObservableObject {
    @Published var relationships: [RelationshipType] = []
    @Published var templates: [QuestionTemplate] = []
    @Published var selectedRelationship: String?
    @Published var isLoading = false
    @Published var error: String?

    private let templateService = TemplateService.shared

    // Sample questions for explore view
    private let sampleQuestions: [String: [String]] = [
        "parent": [
            "What's your earliest childhood memory?",
            "What was your wedding day like?",
            "What advice would you give your younger self?"
        ],
        "grandparent": [
            "What was life like when you were growing up?",
            "How did you meet grandma/grandpa?",
            "What traditions did your family have?"
        ],
        "spouse": [
            "What was your first impression of me?",
            "What's your favorite memory of us together?",
            "What dreams do you have for our future?"
        ],
        "friend": [
            "How did we first meet?",
            "What's your favorite memory of our friendship?",
            "What do you value most about our friendship?"
        ]
    ]

    // MARK: - Load Relationships
    func loadRelationships() async {
        isLoading = true
        error = nil

        do {
            var fetchedRelationships = try await templateService.getRelationships()

            // Add sample questions for explore view
            for i in 0..<fetchedRelationships.count {
                let type = fetchedRelationships[i].type
                fetchedRelationships[i].sampleQuestions = sampleQuestions[type] ?? [
                    "Tell me about a meaningful moment in your life.",
                    "What advice would you give to others?",
                    "What are you most proud of?"
                ]
            }

            self.relationships = fetchedRelationships
        } catch {
            self.error = "Failed to load relationships"
            // Provide fallback data
            self.relationships = RelationshipType.allTypes.map { type in
                RelationshipType(
                    type: type,
                    displayName: RelationshipType.displayName(for: type),
                    questionCount: 20,
                    sampleQuestions: sampleQuestions[type] ?? ["Tell me about yourself."]
                )
            }
        }

        isLoading = false
    }

    // MARK: - Load Templates
    func loadTemplates(for relationship: String) async {
        isLoading = true
        error = nil
        selectedRelationship = relationship

        do {
            templates = try await templateService.listTemplates(relationship: relationship)
        } catch {
            self.error = "Failed to load questions"
        }

        isLoading = false
    }

    // MARK: - Get Templates by Category
    var templatesByCategory: [TemplateCategory] {
        templates.groupedByCategory()
    }
}
