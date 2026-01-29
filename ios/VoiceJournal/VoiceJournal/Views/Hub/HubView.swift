import SwiftUI

struct HubView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var showingMenu = false
    @State private var showingSettings = false
    @State private var showingNewJournal = false
    @State private var showingSendQuestion = false
    @State private var showingPeople = false
    @State private var showingRecordings = false
    @State private var showingJournals = false
    @State private var pendingJournalId: String?
    @State private var navigateToJournalId: String?
    @State private var showFABTooltip = false

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

                VStack(spacing: 0) {
                    // Top Bar
                    topBar(colors: colors)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Theme.Spacing.lg) {
                            // Welcome Header with intent
                            welcomeHeader(colors: colors)

                            // Primary Action - THE one action
                            primaryAction(colors: colors)

                            // Secondary Action
                            secondaryAction(colors: colors)

                            // Tertiary Actions
                            tertiaryActions(colors: colors)

                            Spacer(minLength: Theme.Spacing.xxl + 40) // Room for FAB
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }
                }

                // Floating Record Button with optional tooltip
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingRecordButton(colors: colors)
                            .padding(.trailing, Theme.Spacing.lg)
                            .padding(.bottom, Theme.Spacing.lg)
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
                // Randomize intent phrase on appear
                currentIntentIndex = Int.random(in: 0..<intentPhrases.count)

                // Show FAB tooltip on first launch
                checkFirstLaunchTooltip()
            }
        }
    }

    // MARK: - First Launch Tooltip
    private func checkFirstLaunchTooltip() {
        let hasSeenTooltip = UserDefaults.standard.bool(forKey: "hasSeenFABTooltip")
        if !hasSeenTooltip {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFABTooltip = true
                }
                // Auto-dismiss after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFABTooltip = false
                    }
                    UserDefaults.standard.set(true, forKey: "hasSeenFABTooltip")
                }
            }
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(colors: AppColors) -> some View {
        HStack {
            // Menu Button
            Button(action: { showingJournals = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.textPrimary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Settings Button
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
            // Greeting
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

            // Intent line - subtle but readable
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

    // MARK: - Primary Action (THE one action)
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

    // MARK: - Floating Record Button
    @ViewBuilder
    private func floatingRecordButton(colors: AppColors) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                // Dismiss tooltip if showing
                if showFABTooltip {
                    withAnimation {
                        showFABTooltip = false
                    }
                    UserDefaults.standard.set(true, forKey: "hasSeenFABTooltip")
                }
                // Quick record action
            }) {
                ZStack {
                    // Outer glow for emphasis
                    Circle()
                        .fill(colors.accentPrimary.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .blur(radius: 4)

                    Circle()
                        .fill(colors.accentPrimary)
                        .frame(width: 64, height: 64)
                        .overlay(
                            // Mic with waveform hint
                            HStack(spacing: 2) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 22, weight: .medium))
                                Image(systemName: "waveform")
                                    .font(.system(size: 10, weight: .medium))
                                    .opacity(0.7)
                            }
                            .foregroundColor(.white)
                        )
                        .shadow(color: colors.accentPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }

            // First-use tooltip
            if showFABTooltip {
                tooltipView(colors: colors)
                    .offset(x: -70, y: -10)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottomTrailing)))
            }
        }
    }

    @ViewBuilder
    private func tooltipView(colors: AppColors) -> some View {
        Text("Record a response or memory")
            .font(AppTypography.caption)
            .foregroundColor(colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(colors.surface)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Preview
#Preview {
    HubView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
