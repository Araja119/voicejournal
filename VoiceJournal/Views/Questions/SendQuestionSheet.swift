import SwiftUI

struct SendQuestionSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @StateObject private var peopleViewModel = PeopleViewModel()
    @StateObject private var journalViewModel = JournalViewModel()

    @State private var selectedPerson: Person?
    @State private var selectedJournal: Journal?
    @State private var questionText = ""
    @State private var showingTemplatePicker = false
    @State private var showingCreateJournal = false
    @State private var isSending = false
    @State private var error: String?
    @State private var step: SendQuestionStep = .selectPerson

    enum SendQuestionStep {
        case selectPerson
        case selectJournal
        case writeQuestion
    }

    /// Journals dedicated to the selected person
    private var journalsForSelectedPerson: [Journal] {
        guard let person = selectedPerson else { return [] }
        return journalViewModel.journals.filter { journal in
            journal.dedicatedToPerson?.id == person.id
        }
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator(colors: colors)
                        .padding(.top, Theme.Spacing.md)

                    // Content based on step
                    switch step {
                    case .selectPerson:
                        selectPersonView(colors: colors)
                    case .selectJournal:
                        selectJournalView(colors: colors)
                    case .writeQuestion:
                        writeQuestionView(colors: colors)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: handleBack) {
                        if step == .selectPerson {
                            Text("Cancel")
                                .foregroundColor(colors.textSecondary)
                        } else {
                            Image(systemName: "chevron.left")
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }

                if step == .writeQuestion {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Send") { sendQuestion() }
                            .foregroundColor(colors.accentPrimary)
                            .disabled(questionText.isEmpty || isSending)
                    }
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerView { template in
                    questionText = template.questionText
                }
            }
        }
        .task {
            await peopleViewModel.loadPeople()
            await journalViewModel.loadJournals()
        }
    }

    private var navigationTitle: String {
        switch step {
        case .selectPerson: return "Who to ask?"
        case .selectJournal: return "Which journal?"
        case .writeQuestion: return "Your question"
        }
    }

    @ViewBuilder
    private func progressIndicator(colors: AppColors) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index <= stepIndex ? colors.accentPrimary : colors.surface)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    private var stepIndex: Int {
        switch step {
        case .selectPerson: return 0
        case .selectJournal: return 1
        case .writeQuestion: return 2
        }
    }

    @ViewBuilder
    private func selectPersonView(colors: AppColors) -> some View {
        if peopleViewModel.isLoading {
            LoadingView()
        } else if peopleViewModel.people.isEmpty {
            EmptyStateView(
                icon: "person.2",
                title: "No People Yet",
                message: "Add people first to send them questions",
                colors: colors
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(peopleViewModel.people) { person in
                        Button(action: {
                            selectedPerson = person
                            withAnimation { step = .selectJournal }
                        }) {
                            HStack(spacing: Theme.Spacing.md) {
                                AvatarView(name: person.name, size: 48, colors: colors)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.name)
                                        .font(AppTypography.headlineSmall)
                                        .foregroundColor(colors.textPrimary)

                                    Text(person.displayRelationship)
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(colors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(colors.textSecondary)
                            }
                            .padding(Theme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(Theme.Radius.md)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
            }
        }
    }

    @ViewBuilder
    private func selectJournalView(colors: AppColors) -> some View {
        if journalViewModel.isLoading {
            LoadingView()
        } else if journalsForSelectedPerson.isEmpty {
            // No journals dedicated to this person - show create option
            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                // Message
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(colors.textSecondary.opacity(0.5))

                    Text("No journals exist for \(selectedPerson?.name ?? "this person").")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Create one below.")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(colors.textSecondary)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                // Create Journal Button at bottom
                Button(action: { showingCreateJournal = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Journal")
                    }
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(colors.accentPrimary)
                    .cornerRadius(Theme.Radius.md)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $showingCreateJournal) {
                CreateJournalForPersonSheet(
                    person: selectedPerson!,
                    onCreate: { journal in
                        Task { await journalViewModel.loadJournals() }
                        selectedJournal = journal
                        withAnimation { step = .writeQuestion }
                    }
                )
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(journalsForSelectedPerson) { journal in
                        Button(action: {
                            selectedJournal = journal
                            withAnimation { step = .writeQuestion }
                        }) {
                            HStack(spacing: Theme.Spacing.md) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(colors.accentPrimary)
                                    .frame(width: 48, height: 48)
                                    .background(colors.accentPrimary.opacity(0.1))
                                    .cornerRadius(Theme.Radius.sm)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(journal.title)
                                        .font(AppTypography.headlineSmall)
                                        .foregroundColor(colors.textPrimary)

                                    if let description = journal.description {
                                        Text(description)
                                            .font(AppTypography.bodySmall)
                                            .foregroundColor(colors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(colors.textSecondary)
                            }
                            .padding(Theme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(Theme.Radius.md)
                        }
                    }

                    // Option to create another journal
                    Button(action: { showingCreateJournal = true }) {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(colors.accentPrimary)
                                .frame(width: 48, height: 48)
                                .background(colors.accentPrimary.opacity(0.1))
                                .cornerRadius(Theme.Radius.sm)

                            Text("Create new journal")
                                .font(AppTypography.headlineSmall)
                                .foregroundColor(colors.accentPrimary)

                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(Theme.Radius.md)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
            }
            .sheet(isPresented: $showingCreateJournal) {
                CreateJournalForPersonSheet(
                    person: selectedPerson!,
                    onCreate: { journal in
                        Task { await journalViewModel.loadJournals() }
                        selectedJournal = journal
                        withAnimation { step = .writeQuestion }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func writeQuestionView(colors: AppColors) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Selected person
                if let person = selectedPerson {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Asking")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(colors.textSecondary)

                        AvatarView(name: person.name, size: 24, colors: colors)

                        Text(person.name)
                            .font(AppTypography.labelLarge)
                            .foregroundColor(colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Question input
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    TextEditor(text: $questionText)
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(colors.textPrimary)
                        .frame(minHeight: 120)
                        .padding(Theme.Spacing.sm)
                        .background(colors.surface)
                        .cornerRadius(Theme.Radius.md)
                }

                // Template button
                Button(action: { showingTemplatePicker = true }) {
                    HStack {
                        Image(systemName: "text.book.closed")
                        Text("Choose from templates")
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(colors.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(colors.accentPrimary.opacity(0.1))
                    .cornerRadius(Theme.Radius.md)
                }

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

    private func handleBack() {
        switch step {
        case .selectPerson:
            dismiss()
        case .selectJournal:
            withAnimation { step = .selectPerson }
        case .writeQuestion:
            withAnimation { step = .selectJournal }
        }
    }

    private func sendQuestion() {
        guard let journal = selectedJournal,
              let person = selectedPerson else { return }

        isSending = true
        error = nil

        Task {
            do {
                // Create the question
                let request = CreateQuestionRequest(
                    questionText: questionText,
                    assignToPersonIds: [person.id]
                )
                _ = try await QuestionService.shared.createQuestion(
                    journalId: journal.id,
                    request
                )
                dismiss()
            } catch {
                self.error = "Failed to send question"
            }
            isSending = false
        }
    }
}

// MARK: - Create Journal For Person Sheet
struct CreateJournalForPersonSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let person: Person
    var onCreate: (Journal) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var privacySetting = "private"
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Person header
                        HStack(spacing: Theme.Spacing.md) {
                            AvatarView(name: person.name, size: 48, colors: colors)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Creating journal for")
                                    .font(AppTypography.caption)
                                    .foregroundColor(colors.textSecondary)

                                Text(person.name)
                                    .font(AppTypography.headlineSmall)
                                    .foregroundColor(colors.textPrimary)
                            }

                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                        .background(colors.accentPrimary.opacity(0.1))
                        .cornerRadius(Theme.Radius.md)

                        // Title
                        InputField(
                            title: "Journal Title",
                            text: $title,
                            placeholder: "e.g., \(person.name)'s Life Story",
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
                                .frame(minHeight: 80)
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

    private func create() {
        isSaving = true
        error = nil

        Task {
            do {
                let request = CreateJournalRequest(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    privacySetting: privacySetting,
                    dedicatedToPersonId: person.id
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
    SendQuestionSheet()
        .preferredColorScheme(.dark)
}
