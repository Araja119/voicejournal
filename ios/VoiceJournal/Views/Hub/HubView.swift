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

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar
                    topBar(colors: colors)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Theme.Spacing.lg) {
                            // Welcome Header
                            welcomeHeader(colors: colors)

                            // Primary Action Cards
                            primaryActions(colors: colors)

                            // Secondary Actions
                            secondaryActions(colors: colors)

                            Spacer(minLength: Theme.Spacing.xxl)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }
                }

                // Floating Record Button (optional)
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
            }
            .sheet(isPresented: $showingNewJournal) {
                CreateJournalSheet(onCreate: { _ in
                    // Journal created, could navigate to it
                })
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
                    .foregroundColor(colors.textSecondary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Settings Button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }

    // MARK: - Welcome Header
    @ViewBuilder
    private func welcomeHeader(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Welcome back,")
                .font(AppTypography.bodyLarge)
                .foregroundColor(colors.textSecondary)

            Text(appState.currentUser?.displayName ?? "Friend")
                .font(AppTypography.displayMedium)
                .foregroundColor(colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Primary Actions
    @ViewBuilder
    private func primaryActions(colors: AppColors) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Send Question Card
            HubActionCard(
                title: "Send Question",
                subtitle: "Ask someone meaningful",
                icon: "paperplane.fill",
                accentColor: colors.accentPrimary,
                colors: colors
            ) {
                showingSendQuestion = true
            }

            // New Journal Card
            HubActionCard(
                title: "New Journal",
                subtitle: "Start collecting stories",
                icon: "book.fill",
                accentColor: colors.accentSecondary,
                colors: colors
            ) {
                showingNewJournal = true
            }
        }
    }

    // MARK: - Secondary Actions
    @ViewBuilder
    private func secondaryActions(colors: AppColors) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            SecondaryActionRow(
                title: "My People",
                icon: "person.2.fill",
                colors: colors
            ) {
                showingPeople = true
            }

            SecondaryActionRow(
                title: "Latest Recordings",
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
        Button(action: {
            // Quick record action
        }) {
            Circle()
                .fill(colors.accentPrimary)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(Theme.Shadow.lg)
        }
    }
}

// MARK: - Preview
#Preview {
    HubView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
