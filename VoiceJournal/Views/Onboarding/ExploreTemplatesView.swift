import SwiftUI

struct ExploreTemplatesView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TemplatePickerViewModel()

    var onSignupTap: () -> Void

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Discover Questions")
                            .font(AppTypography.headlineLarge)
                            .foregroundColor(colors.textPrimary)

                        Text("Browse thoughtful questions for your loved ones")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.md)

                    // Relationship Categories
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(viewModel.relationships, id: \.type) { relationship in
                                RelationshipCard(
                                    relationship: relationship,
                                    colors: colors
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }

                    // Bottom CTA
                    VStack(spacing: Theme.Spacing.sm) {
                        Button(action: onSignupTap) {
                            Text("Create Account to Get Started")
                                .font(AppTypography.buttonPrimary)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.md)
                                .background(colors.accentPrimary)
                                .cornerRadius(Theme.Radius.md)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(colors.background)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadRelationships()
        }
    }
}

// MARK: - Relationship Card
struct RelationshipCard: View {
    let relationship: RelationshipType
    let colors: AppColors

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text(relationship.displayName)
                            .font(AppTypography.headlineSmall)
                            .foregroundColor(colors.textPrimary)

                        Text("\(relationship.questionCount) questions")
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(colors.textSecondary)
                }
                .padding(Theme.Spacing.md)
                .background(colors.surface)
                .cornerRadius(Theme.Radius.md)
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(relationship.sampleQuestions.prefix(3), id: \.self) { question in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Circle()
                                .fill(colors.accentPrimary.opacity(0.2))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)

                            Text(question)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ExploreTemplatesView(onSignupTap: {})
        .preferredColorScheme(.dark)
}
