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
    @State private var currentSuggestedQuestion: SuggestedQuestion?
    @State private var aiSuggestedQuestions: [SuggestedQuestion] = []
    @State private var isLoadingAISuggestions = false
    @State private var currentSuggestionIndex = 0

    // Question deletion state
    @State private var questionToDelete: Question?
    @State private var showingQuestionDeleteConfirmation = false
    @State private var isDeletingQuestion = false

    // Question editing state
    @State private var questionToEdit: Question?
    @State private var showingEditQuestion = false
    @State private var editedQuestionText = ""


    // Recording state (for self-journals)
    @State private var showingRecordingModal = false
    @State private var recordingQuestion: Question?
    @State private var recordingIdempotencyKey: String?
    @State private var isUploadingRecording = false
    @State private var uploadError: String?

    // Playback state
    @State private var playbackRecording: Recording?
    @State private var debugMessage: String?

    // Remind state
    @State private var remindingAssignmentId: String?
    @State private var remindSuccessAssignmentId: String?
    @State private var remindError: String?

    // Send question state
    @State private var sendingQuestionId: String?
    @State private var sendError: String?

    // Share sheet state
    @State private var pendingShareAssignmentId: String?

    // Recording deletion state
    @State private var recordingToDelete: String? // recording ID
    @State private var showingDeleteRecordingConfirmation = false
    @State private var isDeletingRecording = false

    // Journal editing state
    @State private var showingEditJournal = false
    @State private var editedJournalTitle = ""
    @State private var editedJournalDescription = ""
    @State private var isSavingJournal = false

    // Fallback questions if AI fetch fails
    private let fallbackQuestions: [SuggestedQuestion] = [
        SuggestedQuestion(question: "What's one childhood memory that still makes you smile?", category: "memories"),
        SuggestedQuestion(question: "What life lesson took you the longest to learn?", category: "life lessons"),
        SuggestedQuestion(question: "What's a tradition from your family that you cherish?", category: "family"),
        SuggestedQuestion(question: "What moment in your life are you most proud of?", category: "achievements"),
        SuggestedQuestion(question: "What advice would you give your younger self?", category: "advice")
    ]

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            AppBackground()
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
                        Button(action: {
                            editedJournalTitle = viewModel.journal?.title ?? ""
                            editedJournalDescription = viewModel.journal?.description ?? ""
                            showingEditJournal = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }

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
        .confirmationDialog(
            "Delete this question?",
            isPresented: $showingQuestionDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteQuestion()
            }
            Button("Cancel", role: .cancel) {
                questionToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete this recording?",
            isPresented: $showingDeleteRecordingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Recording", role: .destructive) {
                deleteRecording()
            }
            Button("Cancel", role: .cancel) {
                recordingToDelete = nil
            }
        } message: {
            Text("The voice recording will be permanently deleted. The question will revert to its previous state.")
        }
        .sheet(isPresented: $showingAddQuestion) {
            CreateQuestionSheet(journalId: journalId) {
                Task { await viewModel.loadJournal(id: journalId) }
            }
        }
        .sheet(isPresented: $showingEditQuestion) {
            EditQuestionSheet(
                questionText: $editedQuestionText,
                onSave: {
                    saveEditedQuestion()
                },
                onCancel: {
                    showingEditQuestion = false
                    questionToEdit = nil
                }
            )
        }
        .sheet(isPresented: $showingEditJournal) {
            EditJournalSheet(
                title: $editedJournalTitle,
                description: $editedJournalDescription,
                isSaving: isSavingJournal,
                onSave: {
                    saveEditedJournal()
                },
                onCancel: {
                    showingEditJournal = false
                }
            )
        }
        .fullScreenCover(item: $recordingQuestion) { question in
            RecordingModal(
                questionText: question.questionText,
                onComplete: { audioData, duration in
                    let questionToUpload = question
                    recordingQuestion = nil
                    Task {
                        await uploadSelfRecording(
                            question: questionToUpload,
                            audioData: audioData,
                            duration: duration
                        )
                    }
                },
                onCancel: {
                    recordingQuestion = nil
                    recordingIdempotencyKey = nil
                }
            )
        }
        .fullScreenCover(item: $playbackRecording) { recording in
            RecordingPlayerView(recording: recording)
        }
        .alert("Upload Failed", isPresented: .init(
            get: { uploadError != nil },
            set: { if !$0 { uploadError = nil } }
        )) {
            Button("OK", role: .cancel) {
                uploadError = nil
            }
        } message: {
            if let error = uploadError {
                Text(error)
            }
        }
        .alert("Debug", isPresented: .init(
            get: { debugMessage != nil },
            set: { if !$0 { debugMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                debugMessage = nil
            }
        } message: {
            if let msg = debugMessage {
                Text(msg)
            }
        }
        .alert("Reminder", isPresented: .init(
            get: { remindError != nil },
            set: { if !$0 { remindError = nil } }
        )) {
            Button("OK", role: .cancel) {
                remindError = nil
            }
        } message: {
            if let error = remindError {
                Text(error)
            }
        }
        .alert("Send Failed", isPresented: .init(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button("OK", role: .cancel) {
                sendError = nil
            }
        } message: {
            if let error = sendError {
                Text(error)
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

    private func deleteQuestion() {
        guard let question = questionToDelete else { return }
        isDeletingQuestion = true

        Task {
            do {
                print("🗑️ Deleting question: \(question.id) from journal: \(journalId)")
                try await QuestionService.shared.deleteQuestion(journalId: journalId, questionId: question.id)
                print("🗑️ Delete successful, reloading journal")
                await viewModel.loadJournal(id: journalId)
            } catch {
                print("🗑️ Failed to delete question: \(error)")
            }
            questionToDelete = nil
            isDeletingQuestion = false
        }
    }

    private func deleteRecording() {
        guard let recordingId = recordingToDelete else { return }
        isDeletingRecording = true

        Task {
            do {
                try await RecordingService.shared.deleteRecording(id: recordingId)
                await viewModel.loadJournal(id: journalId)
            } catch {
                print("Failed to delete recording: \(error)")
            }
            recordingToDelete = nil
            isDeletingRecording = false
        }
    }

    private func saveEditedQuestion() {
        guard let question = questionToEdit else { return }
        let trimmedText = editedQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        Task {
            do {
                print("✏️ Updating question: \(question.id)")
                let request = UpdateQuestionRequest(questionText: trimmedText)
                _ = try await QuestionService.shared.updateQuestion(
                    journalId: journalId,
                    questionId: question.id,
                    request
                )
                print("✏️ Update successful, reloading journal")
                await viewModel.loadJournal(id: journalId)
            } catch {
                print("✏️ Failed to update question: \(error)")
            }
            showingEditQuestion = false
            questionToEdit = nil
            editedQuestionText = ""
        }
    }

    private func saveEditedJournal() {
        let trimmedTitle = editedJournalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isSavingJournal = true

        Task {
            do {
                let request = UpdateJournalRequest(
                    title: trimmedTitle,
                    description: editedJournalDescription.isEmpty ? nil : editedJournalDescription
                )
                _ = try await JournalService.shared.updateJournal(id: journalId, request)
                await viewModel.loadJournal(id: journalId)
            } catch {
                print("Failed to update journal: \(error)")
            }
            isSavingJournal = false
            showingEditJournal = false
        }
    }

    // MARK: - Recording Functions

    private func startRecording(for question: Question) {
        recordingIdempotencyKey = UUID().uuidString
        recordingQuestion = question  // This triggers the fullScreenCover
    }

    private func playRecording(for assignment: Assignment) {
        // Fetch the full recording when play button is tapped
        guard let assignmentRecording = assignment.recording else {
            debugMessage = "No recording found in assignment! Status: \(assignment.status.rawValue)"
            return
        }

        Task {
            do {
                let fullRecording = try await RecordingService.shared.getRecording(id: assignmentRecording.id)
                await MainActor.run {
                    playbackRecording = fullRecording
                }
            } catch {
                await MainActor.run {
                    debugMessage = "API Failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Remind Functions

    private func sendReminder(for assignment: Assignment) {
        // Check per-assignment eligibility
        let eligibility = RemindEligibility.check(assignment)
        guard eligibility.canRemind else { return }

        // Check daily/person caps
        if let capBlock = RemindCapTracker.shared.canRemindPerson(assignment.personId) {
            switch capBlock {
            case .dailyCapReached:
                remindError = "You've reached the daily reminder limit. Try again tomorrow."
            case .personCapReached:
                remindError = "You've already reminded this person today."
            default:
                break
            }
            return
        }

        remindingAssignmentId = assignment.id

        Task {
            do {
                let _ = try await QuestionService.shared.sendReminder(
                    assignmentId: assignment.id,
                    channel: .share
                )

                // Record in cap tracker
                RemindCapTracker.shared.recordRemind(personId: assignment.personId)

                // Show success flash
                remindingAssignmentId = nil
                remindSuccessAssignmentId = assignment.id

                // Clear success flash after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    remindSuccessAssignmentId = nil
                }

                // Refresh journal to get updated reminderCount/lastReminderAt
                await viewModel.loadJournal(id: journalId)
            } catch {
                remindingAssignmentId = nil
                remindError = "Could not send reminder. Try again later."
            }
        }
    }

    // MARK: - Send Question Functions

    private func sendQuestion(for question: Question) {
        guard let journal = viewModel.journal,
              let person = journal.dedicatedToPerson else { return }

        sendingQuestionId = question.id

        Task {
            do {
                // Step 1: Assign if no assignment exists for this person
                var assignment: Assignment
                if let existing = question.assignments?.first(where: { $0.personId == person.id }) {
                    assignment = existing
                } else {
                    let response = try await QuestionService.shared.assignQuestion(
                        questionId: question.id, personIds: [person.id]
                    )
                    assignment = response.assignments.first!
                }

                // Step 2: Get recording link
                let link = assignment.recordingLink ?? assignment.uniqueLinkToken.map { token in
                    APIConfig.baseURL.replacingOccurrences(of: "/v1", with: "") + "/record/" + token
                }

                guard let recordingLink = link else {
                    sendError = "Could not generate recording link."
                    sendingQuestionId = nil
                    return
                }

                // Step 3: Build share text and present share sheet
                let senderName = journal.owner.displayName
                let shareText = "\(senderName) has a question for you:\n\n\"\(question.questionText)\"\n\nTap to record your answer:\n\(recordingLink)"
                let assignmentId = assignment.id

                await MainActor.run {
                    pendingShareAssignmentId = assignmentId
                    sendingQuestionId = nil
                    SharePresenter.present(items: [shareText]) { completed in
                        handleShareCompletion(completed: completed)
                    }
                }
            } catch {
                sendError = "Failed to send question. Try again."
                sendingQuestionId = nil
            }
        }
    }

    private func resendQuestion(for question: Question) {
        guard let journal = viewModel.journal else { return }

        if let assignment = question.assignments?.first(where: {
            $0.status == .sent || $0.status == .viewed
        }) {
            let link = assignment.recordingLink ?? assignment.uniqueLinkToken.map { token in
                APIConfig.baseURL.replacingOccurrences(of: "/v1", with: "") + "/record/" + token
            }

            guard let recordingLink = link else {
                sendError = "Could not generate recording link."
                return
            }

            let senderName = journal.owner.displayName
            let shareText = "\(senderName) has a question for you:\n\n\"\(question.questionText)\"\n\nTap to record your answer:\n\(recordingLink)"

            pendingShareAssignmentId = assignment.id
            SharePresenter.present(items: [shareText]) { completed in
                handleShareCompletion(completed: completed)
            }
        }
    }

    private func handleShareCompletion(completed: Bool) {
        guard completed, let assignmentId = pendingShareAssignmentId else {
            pendingShareAssignmentId = nil
            return
        }

        Task {
            do {
                _ = try await QuestionService.shared.sendAssignment(
                    assignmentId: assignmentId, channel: .share
                )
                await viewModel.loadJournal(id: journalId)
            } catch {
                sendError = "Failed to mark as sent."
            }
            pendingShareAssignmentId = nil
        }
    }

    private func copyLink(for question: Question) {
        if let assignment = question.assignments?.first,
           let link = assignment.recordingLink {
            UIPasteboard.general.string = link
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    @MainActor
    private func uploadSelfRecording(question: Question, audioData: Data, duration: Int) async {
        guard let idempotencyKey = recordingIdempotencyKey else { return }

        isUploadingRecording = true

        do {
            let _ = try await RecordingService.shared.uploadRecordingAuthenticated(
                journalId: journalId,
                questionId: question.id,
                audioData: audioData,
                durationSeconds: duration,
                idempotencyKey: idempotencyKey
            )

            // Refresh journal to get updated question state
            await viewModel.loadJournal(id: journalId)

            recordingQuestion = nil
            recordingIdempotencyKey = nil
        } catch {
            print("🎙️ Upload failed: \(error)")
            uploadError = "Failed to save recording. Please try again."
        }

        isUploadingRecording = false
    }

    private func addSuggestedQuestion() {
        guard let question = currentSuggestedQuestion else { return }
        isAddingSuggestedQuestion = true

        Task {
            do {
                let request = CreateQuestionRequest(questionText: question.question)
                _ = try await QuestionService.shared.createQuestion(journalId: journalId, request)
                await viewModel.loadJournal(id: journalId)
            } catch {
                print("Failed to add question: \(error)")
            }
            isAddingSuggestedQuestion = false
        }
    }

    private func loadAISuggestedQuestions() {
        guard !isLoadingAISuggestions else { return }
        isLoadingAISuggestions = true

        Task {
            do {
                let suggestions = try await QuestionService.shared.getSuggestedQuestions(journalId: journalId, count: 5)
                await MainActor.run {
                    aiSuggestedQuestions = suggestions
                    if !suggestions.isEmpty {
                        currentSuggestedQuestion = suggestions[0]
                        currentSuggestionIndex = 0
                    }
                }
            } catch {
                print("Failed to load AI suggestions: \(error)")
                // Use fallback questions
                await MainActor.run {
                    aiSuggestedQuestions = fallbackQuestions
                    currentSuggestedQuestion = fallbackQuestions.randomElement()
                }
            }
            await MainActor.run {
                isLoadingAISuggestions = false
            }
        }
    }

    private func showNextSuggestion() {
        let questions = aiSuggestedQuestions.isEmpty ? fallbackQuestions : aiSuggestedQuestions
        guard !questions.isEmpty else { return }

        currentSuggestionIndex = (currentSuggestionIndex + 1) % questions.count
        currentSuggestedQuestion = questions[currentSuggestionIndex]
    }

    // MARK: - Hero Header
    @ViewBuilder
    private func heroHeader(journal: Journal, colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Person avatar if dedicated
            if let person = journal.dedicatedToPerson {
                // Check if this is a self-journal (relationship "self" or linked to owner)
                let isMyJournal = person.isSelf || (journal.isOwner && person.linkedUserId == journal.owner.id)

                HStack(spacing: Theme.Spacing.sm) {
                    AvatarView(
                        name: person.name,
                        imageURL: person.profilePhotoUrl,
                        size: 40,
                        colors: colors
                    )
                    if isMyJournal {
                        Text("My Journal")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                    } else {
                        Text("For \(person.name)")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                    }
                }
            }

            Text(journal.title)
                .font(AppTypography.headlineLarge)
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                .lineLimit(2)

            if let description = journal.description, !description.isEmpty {
                Text(description)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                    .italic()
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.25) : Color.white.opacity(0.4))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 1)
        )
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
            // Header with refresh button
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("AI suggested question")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(colors.textSecondary)

                Spacer()

                // Refresh/Try another button
                Button(action: { showNextSuggestion() }) {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("Try another")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(colors.accentPrimary)
                }
                .disabled(isLoadingAISuggestions || isAddingSuggestedQuestion)
            }

            // Question content
            if isLoadingAISuggestions {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                    Text("Generating personalized suggestions...")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Theme.Spacing.md)
            } else if let question = currentSuggestedQuestion {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(question.question)
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Category tag
                    Text(question.category)
                        .font(AppTypography.caption)
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(colors.textSecondary.opacity(0.1))
                        .cornerRadius(Theme.Radius.sm)
                }
            }

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
                .disabled(isAddingSuggestedQuestion || isLoadingAISuggestions || currentSuggestedQuestion == nil)

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
            if currentSuggestedQuestion == nil && aiSuggestedQuestions.isEmpty {
                loadAISuggestedQuestions()
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
        // A self-journal is when:
        // 1. The dedicated person has relationship "self", OR
        // 2. The dedicated person is linked to the journal owner (same user ID)
        let isSelfJournal = journal.dedicatedToPerson?.isSelf == true ||
            (journal.isOwner && journal.dedicatedToPerson?.linkedUserId == journal.owner.id)

        // Track if we've seen the first draft (for CTA prominence)
        let questionStates = questions.map { getQuestionState($0) }
        let firstDraftIndex = questionStates.firstIndex(of: .draft)

        VStack(alignment: .leading, spacing: 0) {
            Text("Journal Timeline")
                .font(AppTypography.headlineSmall)
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
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
                        isSelfJournal: isSelfJournal,
                        colors: colors,
                        onEditTapped: {
                            questionToEdit = question
                            editedQuestionText = question.questionText
                            showingEditQuestion = true
                        },
                        onDeleteTapped: {
                            questionToDelete = question
                            showingQuestionDeleteConfirmation = true
                        },
                        onSendTapped: {
                            sendQuestion(for: question)
                        },
                        onCopyLinkTapped: {
                            copyLink(for: question)
                        },
                        onResendTapped: {
                            resendQuestion(for: question)
                        },
                        onRecordTapped: {
                            startRecording(for: question)
                        },
                        onPlayTapped: { assignment in
                            playRecording(for: assignment)
                        },
                        onRemindTapped: { assignment in
                            sendReminder(for: assignment)
                        },
                        onDeleteRecordingTapped: question.assignments?.first(where: { $0.status == .answered })?.recording != nil ? {
                            if let recording = question.assignments?.first(where: { $0.status == .answered })?.recording {
                                recordingToDelete = recording.id
                                showingDeleteRecordingConfirmation = true
                            }
                        } : nil,
                        sendingQuestionId: sendingQuestionId,
                        remindingAssignmentId: remindingAssignmentId,
                        remindSuccessAssignmentId: remindSuccessAssignmentId
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
    @Environment(\.colorScheme) var colorScheme

    let question: Question
    let recipientName: String?
    let state: QuestionState
    let isFirstDraft: Bool
    let isSelfJournal: Bool
    let colors: AppColors

    // Callbacks for actions
    var onEditTapped: () -> Void = {}
    var onDeleteTapped: () -> Void = {}
    var onSendTapped: () -> Void = {}
    var onCopyLinkTapped: () -> Void = {}
    var onResendTapped: () -> Void = {}
    var onRecordTapped: () -> Void = {}
    var onPlayTapped: ((Assignment) -> Void)?
    var onRemindTapped: ((Assignment) -> Void)?
    var onDeleteRecordingTapped: (() -> Void)?

    // Send/Remind UI state (passed from parent)
    var sendingQuestionId: String?
    var remindingAssignmentId: String?
    var remindSuccessAssignmentId: String?

    /// First assignment eligible for remind (for header-level capsule)
    private var firstEligibleAssignment: Assignment? {
        question.assignments?.first { assignment in
            (assignment.status == .sent || assignment.status == .viewed)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header row with question text, remind capsule, and menu button
            HStack(alignment: .top) {
                Text(question.questionText)
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))

                Spacer()

                // Remind capsule — small, contextual, question-level
                if state == .awaiting, let firstEligible = firstEligibleAssignment {
                    remindButton(for: firstEligible)
                }

                // Menu appears directly under the ellipsis button
                Menu {
                    if state == .draft {
                        Button(action: onEditTapped) {
                            Label("Edit Question", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: onDeleteTapped) {
                            Label("Delete Draft", systemImage: "trash")
                        }
                    } else {
                        Button(action: onCopyLinkTapped) {
                            Label("Copy Link", systemImage: "link")
                        }
                        Button(action: onResendTapped) {
                            Label("Resend", systemImage: "arrow.clockwise")
                        }
                        if state == .answered, let onDeleteRec = onDeleteRecordingTapped {
                            Button(role: .destructive, action: onDeleteRec) {
                                Label("Delete Recording", systemImage: "waveform.slash")
                            }
                        }
                        Button(role: .destructive, action: onDeleteTapped) {
                            Label("Delete Question", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
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
        .background(
            ZStack {
                // Backdrop blur
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(.ultraThinMaterial)
                // Overlay
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(cardBackground)
            }
        )
        .cornerRadius(Theme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - State-Based Background - color scheme aware
    private var cardBackground: Color {
        if colorScheme == .dark {
            let baseColor = Color(red: 24/255, green: 26/255, blue: 32/255)
            switch state {
            case .draft:
                return baseColor.opacity(0.72)
            case .awaiting:
                return baseColor.opacity(0.68)
            case .answered:
                return baseColor.opacity(0.75)
            }
        } else {
            // Light mode: use white with varying opacity
            switch state {
            case .draft:
                return Color.white.opacity(0.6)
            case .awaiting:
                return Color.white.opacity(0.55)
            case .answered:
                return Color.white.opacity(0.7)
            }
        }
    }

    private var borderColor: Color {
        if colorScheme == .dark {
            return state == .answered ? colors.accentPrimary.opacity(0.25) : Color.white.opacity(0.05)
        } else {
            return state == .answered ? colors.accentPrimary.opacity(0.3) : Color.black.opacity(0.06)
        }
    }

    // MARK: - Draft State Content
    @ViewBuilder
    private var draftContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // CTA - different for self-journals vs regular journals
            if isSelfJournal {
                // Self-journal: "Record Answer" button (purple accent)
                if isFirstDraft {
                    Button(action: onRecordTapped) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12))
                            Text("Record Answer")
                        }
                        .font(AppTypography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(colors.accentRecord)
                        .cornerRadius(Theme.Radius.md)
                    }
                } else {
                    Button(action: onRecordTapped) {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "mic")
                                .font(.system(size: 11))
                            Text("Record")
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(colors.accentRecord)
                    }
                }
            } else {
                // Regular journal: "Send to [Name]" button
                if sendingQuestionId == question.id {
                    ProgressView()
                        .tint(colors.accentPrimary)
                } else if isFirstDraft {
                    Button(action: onSendTapped) {
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
                    Button(action: onSendTapped) {
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
                            AvatarView(name: name, imageURL: assignment.personProfilePhotoUrl, size: 24, colors: colors)

                            Text(name)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                        }

                        Spacer()

                        // Status chip
                        awaitingStatusChip(for: assignment.status)
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

    // MARK: - Remind Button (small capsule utility — question-level)
    @ViewBuilder
    private func remindButton(for assignment: Assignment) -> some View {
        let eligibility = RemindEligibility.check(assignment)
        let isReminding = remindingAssignmentId == assignment.id
        let isSuccess = remindSuccessAssignmentId == assignment.id

        if isSuccess {
            // Success flash
            Text("Sent!")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .frame(height: 24)
        } else if isReminding {
            // Loading state
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.6)
                .frame(height: 24)
        } else if eligibility.canRemind {
            // Eligible — small outlined capsule, not a CTA
            Text("Remind")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.55))
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(
                    Capsule()
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.12),
                            lineWidth: 1
                        )
                )
                .onTapGesture { onRemindTapped?(assignment) }
        } else {
            // Not eligible — muted state
            switch eligibility.reason {
            case .cooldownActive:
                if let remaining = eligibility.cooldownRemaining {
                    Text(RemindEligibility.formatCooldown(remaining))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3))
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                }
            case .maxRemindersReached:
                Text("3\u{00D7}")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.25) : .black.opacity(0.25))
                    .padding(.horizontal, 6)
                    .frame(height: 24)
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Answered State Content
    @ViewBuilder
    private var answeredContent: some View {
        if let assignments = question.assignments {
            ForEach(assignments) { assignment in
                HStack {
                    if let name = assignment.personName {
                        AvatarView(name: name, imageURL: assignment.personProfilePhotoUrl, size: 28, colors: colors)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))

                            if assignment.status == .answered {
                                HStack(spacing: Theme.Spacing.xxs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text("Answered")
                                        .font(AppTypography.caption)
                                }
                                .foregroundColor(.green)
                            } else {
                                awaitingStatusChip(for: assignment.status)
                            }
                        }
                    }

                    Spacer()

                    // Play button if answered
                    if assignment.status == .answered {
                        Button {
                            NSLog("🎙️ Play button TAPPED for assignment: %@", assignment.id)
                            onPlayTapped?(assignment)
                        } label: {
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
                        .buttonStyle(.plain)
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
                AvatarView(name: name, imageURL: assignment.personProfilePhotoUrl, size: 32, colors: colors)

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

// MARK: - Edit Question Sheet
struct EditQuestionSheet: View {
    @Binding var questionText: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    Text("Edit your question")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextEditor(text: $questionText)
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(Theme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(Theme.Radius.md)
                        .frame(minHeight: 120)
                        .focused($isTextFieldFocused)

                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Edit Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(colors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(colors.accentPrimary)
                    .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Edit Journal Sheet
struct EditJournalSheet: View {
    @Binding var title: String
    @Binding var description: String
    let isSaving: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?

    enum Field {
        case title, description
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    // Title field
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Title")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)

                        TextField("Journal title", text: $title)
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(colors.textPrimary)
                            .padding(Theme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(Theme.Radius.md)
                            .focused($focusedField, equals: .title)
                    }

                    // Description field
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Description (optional)")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)

                        TextEditor(text: $description)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(Theme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(Theme.Radius.md)
                            .frame(minHeight: 100)
                            .focused($focusedField, equals: .description)
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Edit Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(colors.textSecondary)
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            onSave()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(colors.accentPrimary)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear {
                focusedField = .title
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        JournalDetailView(journalId: "test-id")
    }
    .preferredColorScheme(.dark)
}

// MARK: - Remind Button States Preview
#Preview("Remind States - Light") {
    RemindStatesPreview()
        .preferredColorScheme(.light)
}

#Preview("Remind States - Dark") {
    RemindStatesPreview()
        .preferredColorScheme(.dark)
}

/// Self-contained preview showing all Remind button states
private struct RemindStatesPreview: View {
    @Environment(\.colorScheme) var colorScheme

    // Mock assignments in different remind states
    private var eligibleAssignment: Assignment {
        Assignment(
            id: "a1", personId: "p1", personName: "Grandma Rose",
            personProfilePhotoUrl: nil, status: .sent,
            uniqueLinkToken: nil, recordingLink: nil, recording: nil,
            sentAt: Date().addingTimeInterval(-2 * 86400), // 2 days ago
            viewedAt: nil, answeredAt: nil,
            reminderCount: 0, lastReminderAt: nil
        )
    }

    private var cooldownAssignment: Assignment {
        Assignment(
            id: "a2", personId: "p2", personName: "Uncle Mike",
            personProfilePhotoUrl: nil, status: .viewed,
            uniqueLinkToken: nil, recordingLink: nil, recording: nil,
            sentAt: Date().addingTimeInterval(-3 * 86400),
            viewedAt: Date().addingTimeInterval(-86400),
            answeredAt: nil,
            reminderCount: 1, lastReminderAt: Date().addingTimeInterval(-3600) // 1 hour ago (needs 72h)
        )
    }

    private var maxRemindedAssignment: Assignment {
        Assignment(
            id: "a3", personId: "p3", personName: "Dad",
            personProfilePhotoUrl: nil, status: .sent,
            uniqueLinkToken: nil, recordingLink: nil, recording: nil,
            sentAt: Date().addingTimeInterval(-30 * 86400),
            viewedAt: nil, answeredAt: nil,
            reminderCount: 3, lastReminderAt: Date().addingTimeInterval(-10 * 86400)
        )
    }

    private var answeredAssignment: Assignment {
        Assignment(
            id: "a4", personId: "p4", personName: "Mom",
            personProfilePhotoUrl: nil, status: .answered,
            uniqueLinkToken: nil, recordingLink: nil, recording: AssignmentRecording(id: "r1", durationSeconds: 45, recordedAt: Date()),
            sentAt: Date().addingTimeInterval(-5 * 86400),
            viewedAt: Date().addingTimeInterval(-3 * 86400),
            answeredAt: Date().addingTimeInterval(-86400),
            reminderCount: 1, lastReminderAt: Date().addingTimeInterval(-4 * 86400)
        )
    }

    private var pendingAssignment: Assignment {
        Assignment(
            id: "a5", personId: "p5", personName: "Sister",
            personProfilePhotoUrl: nil, status: .pending,
            uniqueLinkToken: nil, recordingLink: nil, recording: nil,
            sentAt: nil, viewedAt: nil, answeredAt: nil,
            reminderCount: 0, lastReminderAt: nil
        )
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Title
                    Text("Remind Button States")
                        .font(AppTypography.headlineLarge)
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 1. Eligible - can remind
                    sectionLabel("1. Eligible (sent 2 days ago, 0 reminders)")
                    mockTimelineCard(
                        question: "What's your earliest childhood memory?",
                        assignment: eligibleAssignment,
                        state: .awaiting,
                        colors: colors
                    )

                    // 2. Cooldown active
                    sectionLabel("2. Cooldown Active (reminded 1h ago, needs 72h)")
                    mockTimelineCard(
                        question: "Tell me about your first job.",
                        assignment: cooldownAssignment,
                        state: .awaiting,
                        colors: colors
                    )

                    // 3. Max reminders reached
                    sectionLabel("3. Max Reached (3 reminders sent)")
                    mockTimelineCard(
                        question: "What advice would you give your younger self?",
                        assignment: maxRemindedAssignment,
                        state: .awaiting,
                        colors: colors
                    )

                    // 4. Answered (no remind button)
                    sectionLabel("4. Answered (remind not shown)")
                    mockTimelineCard(
                        question: "What makes you happiest today?",
                        assignment: answeredAssignment,
                        state: .answered,
                        colors: colors
                    )

                    // 5. Draft/Pending (no remind button)
                    sectionLabel("5. Draft/Not Sent (remind not shown)")
                    mockTimelineCard(
                        question: "What family tradition do you cherish most?",
                        assignment: pendingAssignment,
                        state: .draft,
                        colors: colors
                    )

                    // Hub card with remind
                    sectionLabel("6. Hub 'In Progress' Card with Remind")
                    mockHubCard(colors: colors)
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption)
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func mockTimelineCard(question: String, assignment: Assignment, state: QuestionState, colors: AppColors) -> some View {
        QuestionTimelineCard(
            question: Question(
                id: "q-\(assignment.id)",
                questionText: question,
                source: .custom,
                displayOrder: 0,
                assignments: [assignment]
            ),
            recipientName: assignment.personName,
            state: state,
            isFirstDraft: false,
            isSelfJournal: false,
            colors: colors,
            onRemindTapped: { _ in },
            remindingAssignmentId: nil,
            remindSuccessAssignmentId: nil
        )
    }

    @ViewBuilder
    private func mockHubCard(colors: AppColors) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            let item = InProgressItem(
                id: "hub-1",
                personId: "p1",
                personName: "Grandma Rose",
                personPhotoUrl: nil,
                journalId: "j1",
                journalTitle: "Stories from the Old Country",
                primaryText: "Waiting on Grandma Rose",
                secondaryText: "Last reply 3 days ago",
                tertiaryText: nil,
                unansweredCount: 3,
                oldestUnansweredDate: Date().addingTimeInterval(-7 * 86400),
                lastActivityDate: Date().addingTimeInterval(-3 * 86400),
                responseRate: 0.4
            )

            // Idle state
            sectionLabel("Idle — primary action")
            InProgressCardStyled(
                item: item,
                cardType: .waiting,
                colors: colors,
                onTap: {},
                onRemindTapped: {},
                remindState: .idle
            )

            // Success state
            sectionLabel("After tap — 'Sent!' flash")
            InProgressCardStyled(
                item: item,
                cardType: .waiting,
                colors: colors,
                onTap: {},
                onRemindTapped: {},
                remindState: .success
            )
        }
    }
}
