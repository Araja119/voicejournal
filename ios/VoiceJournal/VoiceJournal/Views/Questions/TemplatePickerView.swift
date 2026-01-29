import SwiftUI

struct TemplatePickerView: View {
    var onSelect: (QuestionTemplate) -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TemplatePickerViewModel()

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.lg) {
                            ForEach(groupedTemplates.keys.sorted(), id: \.self) { category in
                                TemplateCategorySection(
                                    category: category,
                                    templates: groupedTemplates[category] ?? [],
                                    colors: colors,
                                    onSelect: { template in
                                        onSelect(template)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Question Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.textSecondary)
                }
            }
        }
        .task {
            await viewModel.loadRelationships()
        }
    }

    private var groupedTemplates: [String: [QuestionTemplate]] {
        Dictionary(grouping: viewModel.templates) { $0.category ?? "Other" }
    }
}

// MARK: - Category Section
struct TemplateCategorySection: View {
    let category: String
    let templates: [QuestionTemplate]
    let colors: AppColors
    let onSelect: (QuestionTemplate) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(category.capitalized)
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(colors.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(colors.textSecondary)
                }
            }

            // Templates
            if isExpanded {
                ForEach(templates) { template in
                    TemplateCard(
                        template: template,
                        colors: colors,
                        onSelect: onSelect
                    )
                }
            }
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: QuestionTemplate
    let colors: AppColors
    let onSelect: (QuestionTemplate) -> Void

    var body: some View {
        Button(action: { onSelect(template) }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(template.questionText)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(template.displayRelationship)
                        .font(AppTypography.caption)
                        .foregroundColor(colors.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colors.accentPrimary.opacity(0.15))
                        .cornerRadius(Theme.Radius.sm)

                    Spacer()

                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(colors.accentPrimary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(colors.surface)
            .cornerRadius(Theme.Radius.md)
        }
    }
}

// MARK: - Preview
#Preview {
    TemplatePickerView(onSelect: { _ in })
        .preferredColorScheme(.dark)
}
