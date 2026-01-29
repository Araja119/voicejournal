import SwiftUI

struct JournalDetailView: View {
    let journalId: String
    var onDelete: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = JournalDetailViewModel()
    @State private var showingAddQuestion = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var isAddingSuggestedQuestion = false
    @State private var currentSuggestedQuestion: String = ""

    // Suggested questions for empty state
    private let suggestedQuestions = [
        "What's one childhood memory that still makes you smile?",
        "What life lesson took you the longest to learn?",
        "What's a tradition from your family that you cherish?",
        "What moment in your life are you most proud of?",
        "What advice would you give your younger self?"
    ]

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
                        // Hero Header
                        heroHeader(journal: journal, colors: colors)

                        // Progress Status
                        progressStatus(journal: journal, colors: colors)

                        // Content Section
                        if let questions = journal.questions, !questions.isEmpty {
                            // Timeline with questions
                            journalTimeline(questions: questions, journal: journal, colors: colors)
                        } else {
                            // Empty state with suggested question
                            emptyJournalState(journal: journal, colors: colors)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    Button(action: { showingAddQuestion = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AppColors(colorScheme).accentPrimary)
                    }

                    Menu {
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete Journal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors(colorScheme).textSecondary)
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete \(viewModel.journal?.title ?? "this journal")?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteJournal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the journal and all its questions. This action cannot be undone.")
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

    private func deleteJournal() {
        isDeleting = true

        Task {
            do {
                try await JournalService.shared.deleteJournal(id: journalId)
                onDelete?()
                dismiss()
            } catch {
                print("Failed to delete journal: \(error)")
            }
            isDeleting = false
        }
    }

    private func addSuggestedQuestion() {
        isAddingSuggestedQuestion = true

        Task {
            do {
                let request = CreateQuestionRequest(questionText: currentSuggestedQuestion)
                _ = try await QuestionService.shared.createQuestion(journalId: journalId, request)
                await viewModel.loadJournal(id: journalId)
            } catch {
                print("Failed to add question: \(error)")
            }
            isAddingSuggestedQuestion = false
        }
    }

    // MARK: - Hero Header
    @ViewBuilder
    private func heroHeader(journal: Journal, colors: AppColors) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Abstract visual header
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.accentPrimary.opacity(0.3),
                                colors.accentSecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)

                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    // Person avatar if dedicated
                    if let person = journal.dedicatedToPerson {
                        HStack(spacing: Theme.Spacing.sm) {
                            AvatarView(
                                name: person.name,
                                imageURL: person.profilePhotoUrl,
                                size: 40,
                                colors: colors
                            )
                            Text("For \(person.name)")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textPrimary.opacity(0.8))
                        }
                    }

                    Text(journal.title)
                        .font(AppTypography.headlineLarge)
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(2)

                    if let description = journal.description, !description.isEmpty {
                        Text(description)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(colors.textSecondary.opacity(0.8))
                            .italic()
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.lg)
            }
        }
    }

    // MARK: - Progress Status
    @ViewBuilder
    private func progressStatus(journal: Journal, colors: AppColors) -> some View {
        let recipientName = journal.dedicatedToPerson?.name

        HStack(spacing: Theme.Spacing.sm) {
            // Questions status
            progressChip(
                icon: "paperplane",
                text: journal.questionCount == 0
                    ? "No questions yet"
                    : "\(journal.questionCount) question\(journal.questionCount == 1 ? "" : "s") sent",
                isActive: journal.questionCount > 0,
                colors: colors
            )

            // Responses status - personalized when possible
            if journal.questionCount > 0 {
                let awaitingText: String = {
                    if let name = recipientName {
                        return "Waiting for \(name)"
                    }
                    return "Waiting for replies"
                }()

                progressChip(
                    icon: "waveform",
                    text: journal.answeredCount == 0
                        ? awaitingText
                        : "\(journal.answeredCount) recorded",
                    isActive: journal.answeredCount > 0,
                    colors: colors
                )
            }
        }
    }

    @ViewBuilder
    private func progressChip(icon: String, text: String, isActive: Bool, colors: AppColors) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(AppTypography.caption)
        }
        .foregroundColor(isActive ? colors.accentPrimary : colors.textSecondary)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(isActive ? colors.accentPrimary.opacity(0.15) : colors.surface)
        )
    }

    // MARK: - Empty Journal State
    @ViewBuilder
    private func emptyJournalState(journal: Journal, colors: AppColors) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Suggested Question Card
            suggestedQuestionCard(journal: journal, colors: colors)

            // Timeline Preview (ghosted)
            timelinePreview(colors: colors)
        }
    }

    @ViewBuilder
    private func suggestedQuestionCard(journal: Journal, colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Suggested first question")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(colors.textSecondary)
            }

            // Question
            Text(currentSuggestedQuestion)
                .font(AppTypography.headlineSmall)
                .foregroundColor(colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Buttons
            HStack(spacing: Theme.Spacing.md) {
                Button(action: {
                    addSuggestedQuestion()
                }) {
                    HStack {
                        if isAddingSuggestedQuestion {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Use this question")
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(colors.accentPrimary)
                    .cornerRadius(Theme.Radius.md)
                }
                .disabled(isAddingSuggestedQuestion)

                Button(action: { showingAddQuestion = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Write my own")
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(colors.surface)
                    .cornerRadius(Theme.Radius.md)
                }
                .disabled(isAddingSuggestedQuestion)
            }
        }
        .onAppear {
            if currentSuggestedQuestion.isEmpty {
                currentSuggestedQuestion = suggestedQuestions.randomElement() ?? suggestedQuestions[0]
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .stroke(colors.accentPrimary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func timelinePreview(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your journal timeline")
                .font(AppTypography.labelMedium)
                .foregroundColor(colors.textSecondary)
                .padding(.bottom, Theme.Spacing.md)

            // Ghosted timeline items
            ForEach(0..<3, id: \.self) { index in
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    // Timeline line and dot
                    VStack(spacing: 0) {
                        Circle()
                            .fill(colors.textSecondary.opacity(0.2))
                            .frame(width: 12, height: 12)

                        if index < 2 {
                            Rectangle()
                                .fill(colors.textSecondary.opacity(0.1))
                                .frame(width: 2, height: 50)
                        }
                    }

                    // Placeholder content
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.textSecondary.opacity(0.1))
                            .frame(height: 16)
                            .frame(maxWidth: index == 0 ? 200 : (index == 1 ? 160 : 180))

                        if index == 0 {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 10))
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: 60, height: 12)
                            }
                            .foregroundColor(colors.textSecondary.opacity(0.15))
                        }
                    }
                    .padding(.bottom, Theme.Spacing.sm)

                    Spacer()
                }
            }

            // Hint text
            Text("Questions and responses will appear here")
                .font(AppTypography.caption)
                .foregroundColor(colors.textSecondary.opacity(0.6))
                .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .background(colors.surface.opacity(0.5))
        .cornerRadius(Theme.Radius.lg)
    }

    // MARK: - Journal Timeline (with content)
    @ViewBuilder
    private func journalTimeline(questions: [Question], journal: Journal, colors: AppColors) -> some View {
        let recipientName = journal.dedicatedToPerson?.name

        // Track if we've seen the first draft (for CTA prominence)
        let questionStates = questions.map { getQuestionState($0) }
        let firstDraftIndex = questionStates.firstIndex(of: .draft)

        VStack(alignment: .leading, spacing: 0) {
            Text("Journal Timeline")
                .font(AppTypography.headlineSmall)
                .foregroundColor(colors.textPrimary)
                .padding(.bottom, Theme.Spacing.md)

            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                let questionState = questionStates[index]
                let isFirstDraft = (index == firstDraftIndex)

                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    // Timeline dot - state-based styling
                    VStack(spacing: 0) {
                        timelineDot(state: questionState, colors: colors)

                        if index < questions.count - 1 {
                            Rectangle()
                                .fill(colors.accentPrimary.opacity(0.3))
                                .frame(width: 2)
                                .frame(minHeight: 80)
                        }
                    }

                    // Question card with state-based UI
                    QuestionTimelineCard(
                        question: question,
                        recipientName: recipientName,
                        state: questionState,
                        isFirstDraft: isFirstDraft,
                        colors: colors
                    )
                    .padding(.bottom, Theme.Spacing.md)
                }
            }
        }
    }

    // MARK: - Timeline Dot
    @ViewBuilder
    private func timelineDot(state: QuestionState, colors: AppColors) -> some View {
        ZStack {
            switch state {
            case .draft:
                // Hollow dot for drafts
                Circle()
                    .stroke(colors.textSecondary, lineWidth: 2)
                    .frame(width: 12, height: 12)

            case .awaiting:
                // Filled warm dot for sent/awaiting
                Circle()
                    .fill(colors.accentSecondary)
                    .frame(width: 12, height: 12)

            case .answered:
                // Filled dot with checkmark for answered
                Circle()
                    .fill(colors.accentPrimary)
                    .frame(width: 14, height: 14)

                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // Determine the overall state of a question based on its assignments
    private func getQuestionState(_ question: Question) -> QuestionState {
        guard let assignments = question.assignments, !assignments.isEmpty else {
            return .draft
        }

        // If any assignment is answered, the question is answered
        if assignments.contains(where: { $0.status == .answered }) {
            return .answered
        }

        // If any assignment is sent or viewed, it's awaiting
        if assignments.contains(where: { $0.status == .sent || $0.status == .viewed }) {
            return .awaiting
        }

        // If all are pending, it's still draft-ish but assigned
        return .draft
    }
}

// MARK: - Question State
enum QuestionState {
    case draft      // Not sent yet
    case awaiting   // Sent, waiting for response
    case answered   // Has at least one recording
}

// MARK: - Question Timeline Card
struct QuestionTimelineCard: View {
    let question: Question
    let recipientName: String?
    let state: QuestionState
    let isFirstDraft: Bool
    let colors: AppColors

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header row with question text and overflow menu
            HStack(alignment: .top) {
                Text(question.questionText)
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(colors.textPrimary)

                Spacer()

                // Overflow menu - scoped by state
                Menu {
                    // Draft actions
                    if state == .draft {
                        Button(action: {
                            // TODO: Edit question
                        }) {
                            Label("Edit Question", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive, action: {
                            // TODO: Delete draft
                        }) {
                            Label("Delete Draft", systemImage: "trash")
                        }
                    }

                    // Sent/Awaiting/Answered actions
                    if state != .draft {
                        Button(action: {
                            // TODO: Copy link
                        }) {
                            Label("Copy Link", systemImage: "link")
                        }

                        Button(action: {
                            // TODO: Resend
                        }) {
                            Label("Resend", systemImage: "arrow.clockwise")
                        }

                        Divider()

                        Button(role: .destructive, action: {
                            // TODO: Delete question
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                        .frame(width: 28, height: 28)
                }
            }

            // State-based content
            switch state {
            case .draft:
                draftContent
            case .awaiting:
                awaitingContent
            case .answered:
                answeredContent
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(Theme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(state == .answered ? colors.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - State-Based Background
    private var cardBackground: Color {
        switch state {
        case .draft:
            return colors.surface
        case .awaiting:
            return colors.surface.opacity(0.8)
        case .answered:
            return colors.surface.opacity(0.9)
        }
    }

    // MARK: - Draft State Content
    @ViewBuilder
    private var draftContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Status label
            Text("Draft")
                .font(AppTypography.caption)
                .foregroundColor(colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(colors.textSecondary.opacity(0.15))
                .cornerRadius(Theme.Radius.sm)

            // CTA - full button for first draft, text link for subsequent
            if isFirstDraft {
                // Primary CTA button
                Button(action: {
                    // TODO: Open send flow
                }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                        Text(recipientName != nil ? "Send to \(recipientName!)" : "Send Question")
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(colors.accentPrimary)
                    .cornerRadius(Theme.Radius.md)
                }
            } else {
                // Smaller text button for subsequent drafts
                Button(action: {
                    // TODO: Open send flow
                }) {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 11))
                        Text("Send")
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(colors.accentPrimary)
                }
            }
        }
    }

    // MARK: - Awaiting State Content
    @ViewBuilder
    private var awaitingContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Show assignment info if available
            if let assignments = question.assignments {
                ForEach(assignments) { assignment in
                    HStack {
                        if let name = assignment.personName {
                            AvatarView(name: name, size: 24, colors: colors)

                            Text(name)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(colors.textPrimary)
                        }

                        Spacer()

                        // Status chip
                        awaitingStatusChip(for: assignment.status)

                        // Remind button for sent/viewed
                        if assignment.status == .sent || assignment.status == .viewed {
                            Button(action: {
                                // TODO: Send reminder
                            }) {
                                Text("Remind")
                                    .font(AppTypography.caption)
                                    .foregroundColor(colors.accentPrimary)
                            }
                        }
                    }
                }
            } else {
                // Fallback status
                Text("Awaiting response")
                    .font(AppTypography.caption)
                    .foregroundColor(colors.accentSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(colors.accentSecondary.opacity(0.15))
                    .cornerRadius(Theme.Radius.sm)
            }
        }
    }

    @ViewBuilder
    private func awaitingStatusChip(for status: AssignmentStatus) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .pending:
                return ("Queued", colors.textSecondary)
            case .sent:
                return ("Sent", colors.accentSecondary)
            case .viewed:
                return ("Opened", Color.blue)
            case .answered:
                return ("Answered", colors.accentPrimary)
            }
        }()

        Text(text)
            .font(AppTypography.caption)
            .foregroundColor(color)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xxs)
            .background(color.opacity(0.15))
            .cornerRadius(Theme.Radius.sm)
    }

    // MARK: - Answered State Content
    @ViewBuilder
    private var answeredContent: some View {
        if let assignments = question.assignments {
            ForEach(assignments) { assignment in
                HStack {
                    if let name = assignment.personName {
                        AvatarView(name: name, size: 28, colors: colors)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(colors.textPrimary)

                            if assignment.status == .answered {
                                HStack(spacing: Theme.Spacing.xxs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text("Answered")
                                        .font(AppTypography.caption)
                                }
                                .foregroundColor(colors.accentPrimary)
                            } else {
                                awaitingStatusChip(for: assignment.status)
                            }
                        }
                    }

                    Spacer()

                    // Play button if answered
                    if assignment.status == .answered {
                        Button(action: {
                            // TODO: Play recording
                        }) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text("Play")
                                    .font(AppTypography.labelMedium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(colors.accentPrimary)
                            .cornerRadius(Theme.Radius.md)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Legacy Question Card (kept for reference)
struct QuestionCard: View {
    let question: Question
    let colors: AppColors
    @State private var showingRecordingModal = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(question.questionText)
                .font(AppTypography.bodyLarge)
                .foregroundColor(colors.textPrimary)

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
