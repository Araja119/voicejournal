import Foundation

// MARK: - Template Service
class TemplateService {
    static let shared = TemplateService()
    private let client = APIClient.shared

    private init() {}

    // MARK: - List Templates
    func listTemplates(relationship: String? = nil, category: String? = nil) async throws -> [QuestionTemplate] {
        var queryItems: [URLQueryItem] = []

        if let relationship = relationship {
            queryItems.append(URLQueryItem(name: "relationship_type", value: relationship))
        }
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        let response: TemplatesResponse = try await client.request(
            .templates,
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
        return response.templates
    }

    // MARK: - Get Relationships
    func getRelationships() async throws -> [RelationshipType] {
        let response: RelationshipsResponse = try await client.request(.relationships)
        return response.relationships
    }

    // MARK: - Get Templates Grouped by Relationship
    func getTemplatesGroupedByRelationship() async throws -> [String: [QuestionTemplate]] {
        let templates = try await listTemplates()
        return templates.groupedByRelationship()
    }

    // MARK: - Get Templates Grouped by Category
    func getTemplatesGroupedByCategory(relationship: String) async throws -> [TemplateCategory] {
        let templates = try await listTemplates(relationship: relationship)
        return templates.groupedByCategory()
    }
}
