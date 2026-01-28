import SwiftUI

struct CreateJournalSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var privacySetting = "private"
    @State private var isSaving = false
    @State private var error: String?

    var onCreate: (Journal) -> Void

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Title
                        InputField(
                            title: "Journal Title",
                            text: $title,
                            placeholder: "e.g., Mom's Life Story",
                            colors: colors
                        )

                        // Description
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Description (optional)")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            TextEditor(text: $description)
                                .font(AppTypography.bodyLarge)
                                .foregroundColor(colors.textPrimary)
                                .frame(minHeight: 100)
                                .padding(Theme.Spacing.sm)
                                .background(colors.surface)
                                .cornerRadius(Theme.Radius.md)
                        }

                        // Privacy Setting
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Privacy")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            Picker("Privacy", selection: $privacySetting) {
                                Text("Private").tag("private")
                                Text("Shared").tag("shared")
                                Text("Public").tag("public")
                            }
                            .pickerStyle(.segmented)
                        }

                        // Privacy explanation
                        Text(privacyExplanation)
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary)

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
            }
            .navigationTitle("New Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { create() }
                        .foregroundColor(colors.accentPrimary)
                        .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private var privacyExplanation: String {
        switch privacySetting {
        case "private":
            return "Only you can see this journal."
        case "shared":
            return "You can invite specific people to view this journal."
        case "public":
            return "Anyone with the link can view this journal."
        default:
            return ""
        }
    }

    private func create() {
        isSaving = true
        error = nil

        Task {
            do {
                let request = CreateJournalRequest(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    privacySetting: privacySetting
                )
                let journal = try await JournalService.shared.createJournal(request)
                onCreate(journal)
                dismiss()
            } catch {
                self.error = "Failed to create journal"
            }
            isSaving = false
        }
    }
}

// MARK: - Preview
#Preview {
    CreateJournalSheet(onCreate: { _ in })
        .preferredColorScheme(.dark)
}
