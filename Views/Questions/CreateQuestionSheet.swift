import SwiftUI

struct CreateQuestionSheet: View {
    let journalId: String
    var onSave: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var questionText = ""
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    // Question input
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Your Question")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)

                        TextEditor(text: $questionText)
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(colors.textPrimary)
                            .frame(minHeight: 120)
                            .padding(Theme.Spacing.sm)
                            .background(colors.surface)
                            .cornerRadius(Theme.Radius.md)
                    }

                    // Tips
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Tips for great questions:")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)

                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                                Circle()
                                    .fill(colors.accentPrimary)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                Text(tip)
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(colors.surface.opacity(0.5))
                    .cornerRadius(Theme.Radius.md)

                    if let error = error {
                        Text(error)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)
            }
            .navigationTitle("Add Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { save() }
                        .foregroundColor(colors.accentPrimary)
                        .disabled(questionText.isEmpty || isSaving)
                }
            }
        }
    }

    private let tips = [
        "Open-ended questions get richer answers",
        "Ask about specific memories or experiences",
        "Keep it personal and meaningful"
    ]

    private func save() {
        isSaving = true
        error = nil

        Task {
            do {
                let request = CreateQuestionRequest(questionText: questionText)
                _ = try await QuestionService.shared.createQuestion(
                    journalId: journalId,
                    request
                )
                onSave()
                dismiss()
            } catch {
                self.error = "Failed to add question"
            }
            isSaving = false
        }
    }
}

// MARK: - Preview
#Preview {
    CreateQuestionSheet(journalId: "test", onSave: {})
        .preferredColorScheme(.dark)
}
