import SwiftUI

struct JournalDetailView: View {
    let journalId: String

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = JournalDetailViewModel()
    @State private var showingAddQuestion = false

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            colors.background
                .ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView()
            } else if let journal = viewModel.journal {
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header
                        journalHeader(journal: journal, colors: colors)

                        // Questions
                        if let questions = journal.questions, !questions.isEmpty {
                            questionsSection(questions: questions, colors: colors)
                        } else {
                            EmptyStateView(
                                icon: "questionmark.circle",
                                title: "No Questions Yet",
                                message: "Add your first question to get started",
                                actionTitle: "Add Question",
                                action: { showingAddQuestion = true },
                                colors: colors
                            )
                            .padding(.top, Theme.Spacing.xl)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationTitle(viewModel.journal?.title ?? "Journal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddQuestion = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors(colorScheme).accentPrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddQuestion) {
            CreateQuestionSheet(journalId: journalId) {
                Task { await viewModel.loadJournal(id: journalId) }
            }
        }
        .task {
            await viewModel.loadJournal(id: journalId)
        }
    }

    @ViewBuilder
    private func journalHeader(journal: Journal, colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let description = journal.description {
                Text(description)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textSecondary)
            }

            // Stats
            HStack(spacing: Theme.Spacing.lg) {
                statItem(value: journal.questionCount, label: "Questions", colors: colors)
                statItem(value: journal.answeredCount, label: "Answered", colors: colors)
                statItem(value: journal.personCount, label: "People", colors: colors)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    @ViewBuilder
    private func statItem(value: Int, label: String, colors: AppColors) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(AppTypography.headlineMedium)
                .foregroundColor(colors.textPrimary)

            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(colors.textSecondary)
        }
    }

    @ViewBuilder
    private func questionsSection(questions: [Question], colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Questions")
                .font(AppTypography.headlineSmall)
                .foregroundColor(colors.textPrimary)

            ForEach(questions) { question in
                QuestionCard(question: question, colors: colors)
            }
        }
    }
}

// MARK: - Question Card
struct QuestionCard: View {
    let question: Question
    let colors: AppColors
    @State private var showingRecordingModal = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Question text
            Text(question.questionText)
                .font(AppTypography.bodyLarge)
                .foregroundColor(colors.textPrimary)

            // Assignments
            if let assignments = question.assignments, !assignments.isEmpty {
                ForEach(assignments) { assignment in
                    assignmentRow(assignment: assignment, colors: colors)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface)
        .cornerRadius(Theme.Radius.md)
    }

    @ViewBuilder
    private func assignmentRow(assignment: Assignment, colors: AppColors) -> some View {
        HStack {
            if let name = assignment.personName {
                AvatarView(name: name, size: 32, colors: colors)

                Text(name)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(colors.textPrimary)
            }

            Spacer()

            StatusBadge(status: assignment.status, colors: colors)

            // Play button if answered
            if assignment.status == .answered {
                Button(action: {}) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(colors.accentPrimary)
                }
            }
        }
        .padding(.top, Theme.Spacing.xs)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        JournalDetailView(journalId: "test-id")
    }
    .preferredColorScheme(.dark)
}
