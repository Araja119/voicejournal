import Foundation

// MARK: - Question Template
struct QuestionTemplate: Codable, Identifiable, Equatable {
    let id: String
    let relationshipType: String
    let questionText: String
    let category: String?
    let displayOrder: Int
    let isActive: Bool?

    static func == (lhs: QuestionTemplate, rhs: QuestionTemplate) -> Bool {
        lhs.id == rhs.id
    }

    var displayRelationship: String {
        RelationshipType.displayName(for: relationshipType)
    }
}

// MARK: - Templates Response
struct TemplatesResponse: Codable {
    let templates: [QuestionTemplate]
}

// MARK: - Template Category
struct TemplateCategory: Identifiable {
    let name: String
    let templates: [QuestionTemplate]

    var id: String { name }

    var displayName: String {
        switch name.lowercased() {
        case "childhood": return "Childhood"
        case "family": return "Family"
        case "career": return "Career"
        case "relationships": return "Relationships"
        case "values": return "Values & Beliefs"
        case "memories": return "Memories"
        case "advice": return "Advice"
        case "life_lessons": return "Life Lessons"
        case "stories": return "Stories"
        case "leadership": return "Leadership"
        case "team": return "Team"
        case "growth": return "Growth"
        case "mentorship": return "Mentorship"
        default: return name.capitalized
        }
    }
}

// MARK: - Grouped Templates
extension Array where Element == QuestionTemplate {
    func groupedByCategory() -> [TemplateCategory] {
        let grouped = Dictionary(grouping: self) { $0.category ?? "other" }
        return grouped.map { TemplateCategory(name: $0.key, templates: $0.value) }
            .sorted { $0.name < $1.name }
    }

    func groupedByRelationship() -> [String: [QuestionTemplate]] {
        Dictionary(grouping: self) { $0.relationshipType }
    }
}
