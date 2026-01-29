import SwiftUI
import Combine

struct HubView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var showingSettings = false
    @State private var showingNewJournal = false
    @State private var showingSendQuestion = false
    @State private var showingPeople = false
    @State private var showingRecordings = false
    @State private var showingJournals = false
    @State private var pendingJournalId: String?
    @State private var navigateToJournalId: String?
    @State private var activityJournalId: String?

    // Intent phrases - rotates to keep it fresh
    private let intentPhrases = [
        "Who do you want to hear from today?",
        "Let's capture a story.",
        "What memory matters right now?",
        "A question can unlock a lifetime."
    ]

    @State private var currentIntentIndex = 0

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top Bar
                        topBar(colors: colors)

                        VStack(spacing: Theme.Spacing.lg) {
                            // Welcome Header with intent
                            welcomeHeader(colors: colors)

                            // Primary Action - THE one action
                            primaryAction(colors: colors)

                            // Secondary Action
                            secondaryAction(colors: colors)

                            // Activity / Continuity section (after New Journal)
                            if activityViewModel.hasActivity {
                                activitySection(colors: colors)
                            }

                            // Tertiary Actions (at bottom)
                            tertiaryActions(colors: colors)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(appState)
                    .preferredColorScheme(appState.colorScheme)
            }
            .sheet(isPresented: $showingNewJournal, onDismiss: {
                if let journalId = pendingJournalId {
                    pendingJournalId = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToJournalId = journalId
                    }
                }
            }) {
                CreateJournalSheet(onCreate: { journal in
                    pendingJournalId = journal.id
                })
            }
            .navigationDestination(item: $navigateToJournalId) { journalId in
                JournalDetailView(journalId: journalId)
            }
            .navigationDestination(item: $activityJournalId) { journalId in
                JournalDetailView(journalId: journalId)
            }
            .fullScreenCover(isPresented: $showingPeople) {
                PeopleListView()
            }
            .fullScreenCover(isPresented: $showingRecordings) {
                RecordingsListView()
            }
            .fullScreenCover(isPresented: $showingJournals) {
                JournalsListView()
            }
            .sheet(isPresented: $showingSendQuestion) {
                SendQuestionSheet()
            }
            .onAppear {
                currentIntentIndex = Int.random(in: 0..<intentPhrases.count)
            }
            .task {
                await activityViewModel.loadActivity()
            }
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(colors: AppColors) -> some View {
        HStack {
            Button(action: { showingJournals = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.textPrimary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.textPrimary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }

    // MARK: - Welcome Header
    @ViewBuilder
    private func welcomeHeader(colors: AppColors) -> some View {
        let shadowColor = colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.25)
        let strongShadow = colorScheme == .dark ? Color.black.opacity(0.7) : Color.black.opacity(0.3)

        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Welcome back,")
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(colors.textPrimary)
                    .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
                    .shadow(color: shadowColor, radius: 6, x: 0, y: 2)

                Text(appState.currentUser?.displayName ?? "Friend")
                    .font(AppTypography.displayMedium)
                    .foregroundColor(colors.textPrimary)
                    .shadow(color: strongShadow, radius: 4, x: 0, y: 2)
                    .shadow(color: strongShadow, radius: 8, x: 0, y: 3)
            }

            Text(intentPhrases[currentIntentIndex])
                .font(AppTypography.bodyMedium)
                .foregroundColor(colors.textPrimary.opacity(0.85))
                .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
                .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Primary Action
    @ViewBuilder
    private func primaryAction(colors: AppColors) -> some View {
        HubActionCard(
            title: "Send Question",
            subtitle: "Prompt a meaningful memory",
            icon: "paperplane.fill",
            accentColor: colors.accentPrimary,
            colors: colors,
            prominence: .primary
        ) {
            showingSendQuestion = true
        }
    }

    // MARK: - Secondary Action
    @ViewBuilder
    private func secondaryAction(colors: AppColors) -> some View {
        HubActionCard(
            title: "New Journal",
            subtitle: "Start a living story",
            icon: "book.fill",
            accentColor: colors.accentSecondary,
            colors: colors,
            prominence: .standard
        ) {
            showingNewJournal = true
        }
    }

    // MARK: - Tertiary Actions
    @ViewBuilder
    private func tertiaryActions(colors: AppColors) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            SecondaryActionRow(
                title: "My People",
                subtitle: "The voices that matter",
                icon: "person.2.fill",
                colors: colors
            ) {
                showingPeople = true
            }

            SecondaryActionRow(
                title: "Latest Recordings",
                subtitle: "Listen back",
                icon: "waveform",
                colors: colors
            ) {
                showingRecordings = true
            }
        }
    }

    // MARK: - Activity Section (Continuity)
    @ViewBuilder
    private func activitySection(colors: AppColors) -> some View {
        let shadowColor = colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.2)

        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section label
            Text("In progress")
                .font(AppTypography.caption)
                .foregroundColor(colors.textPrimary.opacity(0.6))
                .shadow(color: shadowColor, radius: 2, x: 0, y: 1)

            // Activity card - soft, non-interruptive
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Waiting on - tappable to go to journal
                if let waitingOn = activityViewModel.waitingOnName,
                   let journalId = activityViewModel.waitingOnJournalId {
                    Button(action: {
                        activityJournalId = journalId
                    }) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(colors.accentSecondary)

                            Text("Waiting on \(waitingOn)")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(colors.textSecondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if activityViewModel.awaitingCount > 0 {
                    Text("\(activityViewModel.awaitingCount) question\(activityViewModel.awaitingCount == 1 ? "" : "s") awaiting responses")
                        .font(AppTypography.caption)
                        .foregroundColor(colors.textSecondary)
                }

                // Last reply - tappable to go to that journal
                if let lastReply = activityViewModel.lastReplyInfo {
                    if let journalId = activityViewModel.lastReplyJournalId {
                        Button(action: {
                            activityJournalId = journalId
                        }) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 12))
                                    .foregroundColor(colors.accentPrimary.opacity(0.7))

                                Text(lastReply)
                                    .font(AppTypography.caption)
                                    .foregroundColor(colors.textSecondary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(colors.textSecondary.opacity(0.4))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, Theme.Spacing.xxs)
                    } else {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "waveform")
                                .font(.system(size: 12))
                                .foregroundColor(colors.accentPrimary.opacity(0.7))

                            Text(lastReply)
                                .font(AppTypography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.xxs)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(colors.surface.opacity(colorScheme == .dark ? 0.6 : 0.8))
            )
        }
    }
}

// MARK: - Activity View Model
@MainActor
class ActivityViewModel: ObservableObject {
    @Published var waitingOnName: String?
    @Published var waitingOnJournalId: String?
    @Published var awaitingCount: Int = 0
    @Published var lastReplyInfo: String?
    @Published var lastReplyJournalId: String?

    var hasActivity: Bool {
        waitingOnName != nil || awaitingCount > 0 || lastReplyInfo != nil
    }

    func loadActivity() async {
        // Load journals to compute activity
        do {
            let journals = try await JournalService.shared.listJournals()

            var totalAwaiting = 0
            var mostRecentWaiting: (name: String, journalId: String, date: Date)?

            for journal in journals {
                // Count awaiting
                let awaiting = journal.questionCount - journal.answeredCount
                totalAwaiting += awaiting

                // Track who we're waiting on (most recent)
                if awaiting > 0, let person = journal.dedicatedToPerson {
                    if mostRecentWaiting == nil || journal.createdAt > mostRecentWaiting!.date {
                        mostRecentWaiting = (person.name, journal.id, journal.createdAt)
                    }
                }
            }

            // Load recent recordings for last reply info
            let recordingsResponse = try await RecordingService.shared.listRecordings()
            if let latestRecording = recordingsResponse.recordings.first,
               let person = latestRecording.person,
               let recordedAt = latestRecording.recordedAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                let relativeTime = formatter.localizedString(for: recordedAt, relativeTo: Date())
                lastReplyInfo = "Last reply from \(person.name) — \(relativeTime)"
                lastReplyJournalId = latestRecording.journal?.id
            }

            awaitingCount = totalAwaiting
            waitingOnName = mostRecentWaiting?.name
            waitingOnJournalId = mostRecentWaiting?.journalId

        } catch {
            // Silently fail - activity section just won't show
            print("Failed to load activity: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    HubView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
