import SwiftUI
import Combine

struct HubView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var showingSettings = false
    @State private var showingSendQuestion = false
    @State private var showingPeople = false
    @State private var showingRecordings = false
    @State private var showingJournals = false
    @State private var navigateToJournalId: String?
    @State private var hasLoadedOnce = false

    // Carousel state
    @State private var currentCarouselIndex = 0
    @State private var carouselTimer: Timer?

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
                            // Welcome Header with carousel
                            welcomeHeader(colors: colors)

                            // In Progress Panel - THE CORE (hybrid approach)
                            if activityViewModel.hasInProgressItems {
                                inProgressPanel(colors: colors)
                            }

                            // Primary Action - Send Question
                            sendQuestionCard(colors: colors)

                            // Secondary Actions
                            myPeopleCard(colors: colors)
                            latestRecordingsCard(colors: colors)
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
            .navigationDestination(item: $navigateToJournalId) { journalId in
                JournalDetailView(journalId: journalId)
            }
            .fullScreenCover(isPresented: $showingPeople) {
                PeopleListView()
                    .environmentObject(appState)
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
            .task {
                // Only load once to prevent glitching on navigation back
                if !hasLoadedOnce {
                    await activityViewModel.loadActivity()
                    hasLoadedOnce = true
                    startCarouselTimer()
                }
            }
            .refreshable {
                await activityViewModel.loadActivity()
            }
            .onDisappear {
                // Don't stop timer - keep it running
            }
        }
    }

    // MARK: - Carousel Timer
    private func startCarouselTimer() {
        carouselTimer?.invalidate()
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 9.0, repeats: true) { _ in
            // Slow, gentle fade for a soft, warm feel
            withAnimation(.easeInOut(duration: 1.8)) {
                currentCarouselIndex = activityViewModel.nextCarouselIndex(current: currentCarouselIndex)
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
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }

    // MARK: - Welcome Header with Carousel
    @ViewBuilder
    private func welcomeHeader(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Welcome back,")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white.opacity(0.85))

            Text(appState.currentUser?.displayName ?? "Friend")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            // Carousel text - observant, not instructive
            // Soft, gradual fade between sentences
            Text(activityViewModel.carouselText(at: currentCarouselIndex))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, Theme.Spacing.xxs)
                .id(currentCarouselIndex)
                .transition(.opacity.animation(.easeInOut(duration: 1.8)))
                .animation(.easeInOut(duration: 1.8), value: currentCarouselIndex)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - In Progress Panel
    @ViewBuilder
    private func inProgressPanel(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colors.accentSecondary)

                Text("In Progress")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)

            // Story cards - stable references
            VStack(spacing: Theme.Spacing.sm) {
                // Card 1: Most meaningful loose end
                if let looseEnd = activityViewModel.cardOne {
                    InProgressCardStyled(
                        item: looseEnd,
                        cardType: .waiting,
                        colors: colors,
                        onTap: {
                            navigateToJournalId = looseEnd.journalId
                        }
                    )
                }

                // Card 2: Continue story (different person or different journal)
                if let continueStory = activityViewModel.cardTwo {
                    InProgressCardStyled(
                        item: continueStory,
                        cardType: .continue,
                        colors: colors,
                        onTap: {
                            navigateToJournalId = continueStory.journalId
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    // MARK: - Send Question Card
    @ViewBuilder
    private func sendQuestionCard(colors: AppColors) -> some View {
        Button(action: { showingSendQuestion = true }) {
            HStack(spacing: Theme.Spacing.md) {
                Circle()
                    .fill(colors.accentPrimary.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(colors.accentPrimary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Send Question")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Prompt a meaningful memory")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.64))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - My People Card
    @ViewBuilder
    private func myPeopleCard(colors: AppColors) -> some View {
        Button(action: { showingPeople = true }) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(colors.textSecondary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("My People")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("The voices that matter")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.64))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Latest Recordings Card
    @ViewBuilder
    private func latestRecordingsCard(colors: AppColors) -> some View {
        Button(action: { showingRecordings = true }) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(colors.textSecondary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest Recordings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Listen back")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.64))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - In Progress Card (Mockup Style with Avatar)
struct InProgressCardStyled: View {
    enum CardType {
        case waiting
        case `continue`
    }

    let item: InProgressItem
    let cardType: CardType
    let colors: AppColors
    let onTap: () -> Void

    private var buttonText: String {
        switch cardType {
        case .waiting:
            return "\(item.unansweredCount) unanswered"
        case .continue:
            return "Continue"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                // Avatar with profile photo
                AvatarView(
                    name: item.personName,
                    imageURL: item.personPhotoUrl,
                    size: 40,
                    colors: colors
                )

                // Content - give it priority to expand
                VStack(alignment: .leading, spacing: 2) {
                    // Primary line - allow 2 lines for longer titles
                    Text(item.primaryText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    // Secondary line
                    Text(item.secondaryText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                // Golden status pill
                StatusPill(label: buttonText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(colors.surface.opacity(0.4))
            .cornerRadius(Theme.Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Pill (Golden Gradient - Premium Style)
struct StatusPill: View {
    let label: String

    // 3-stop golden gradient (brighter start)
    private let gradientStart = Color(red: 0.973, green: 0.855, blue: 0.561)  // #F8DA8F
    private let gradientMid = Color(red: 0.949, green: 0.706, blue: 0.380)    // #F2B461
    private let gradientEnd = Color(red: 0.910, green: 0.604, blue: 0.286)    // #E89A49

    // Text color: rgba(60, 36, 12, 0.92) - warm brown, NOT black
    private let textColor = Color(red: 0.235, green: 0.141, blue: 0.047).opacity(0.92)

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(textColor)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: gradientStart, location: 0),
                                .init(color: gradientMid, location: 0.55),
                                .init(color: gradientEnd, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            // Top sheen highlight (stronger glassy effect)
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.45), location: 0),
                                .init(color: Color.white.opacity(0), location: 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            // Inner top highlight (inset 0 1px 0)
            .overlay(
                Capsule()
                    .inset(by: 1)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.22), location: 0),
                                .init(color: Color.white.opacity(0), location: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            // Outer border
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            // Shadow (more lift)
            .shadow(color: Color.black.opacity(0.32), radius: 7, x: 0, y: 6)
            // Vertical nudge down 2px
            .offset(y: 2)
    }
}

// MARK: - In Progress Item Model
struct InProgressItem: Identifiable, Equatable {
    let id: String
    let personId: String
    let personName: String
    let personPhotoUrl: String?
    let journalId: String
    let journalTitle: String
    let primaryText: String
    let secondaryText: String
    let tertiaryText: String?
    let unansweredCount: Int
    let oldestUnansweredDate: Date?
    let lastActivityDate: Date?
    let responseRate: Double

    static func == (lhs: InProgressItem, rhs: InProgressItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Activity View Model
@MainActor
class ActivityViewModel: ObservableObject {
    @Published var peopleOwingStoriesCount: Int = 0
    @Published var totalUnansweredCount: Int = 0
    @Published var cardOne: InProgressItem?
    @Published var cardTwo: InProgressItem?
    @Published var lastReplyTimeAgo: String?
    @Published var longestWaitingPersonName: String?

    // Stable storage to prevent glitching
    private var loadedCardOne: InProgressItem?
    private var loadedCardTwo: InProgressItem?

    var hasInProgressItems: Bool {
        cardOne != nil
    }

    // MARK: - Carousel Logic

    /// Approved carousel sentences with weighted distribution
    func carouselText(at index: Int) -> String {
        let sentences = buildCarouselSentences()
        guard !sentences.isEmpty else { return "" }
        return sentences[index % sentences.count]
    }

    func nextCarouselIndex(current: Int) -> Int {
        let sentences = buildCarouselSentences()
        guard sentences.count > 1 else { return 0 }
        return (current + 1) % sentences.count
    }

    private func buildCarouselSentences() -> [String] {
        var sentences: [String] = []

        // Data-driven (primary weight - these appear more often)
        if peopleOwingStoriesCount > 0 {
            sentences.append("You're waiting on \(peopleOwingStoriesCount) \(peopleOwingStoriesCount == 1 ? "person" : "people") today.")
        }
        if totalUnansweredCount > 0 {
            sentences.append("\(totalUnansweredCount) \(totalUnansweredCount == 1 ? "story is" : "stories are") waiting to be heard.")
        }
        if peopleOwingStoriesCount > 0 {
            sentences.append("\(peopleOwingStoriesCount) \(peopleOwingStoriesCount == 1 ? "conversation is" : "conversations are") still open.")
        }
        if let timeAgo = lastReplyTimeAgo {
            sentences.append("Last reply was \(timeAgo).")
        }
        if let name = longestWaitingPersonName {
            sentences.append("You haven't heard from \(name) in a while.")
        }
        if let journal = cardOne?.journalTitle {
            sentences.append("\"\(journal)\" is still waiting.")
        }

        // Emotional truths (sprinkled in - rare)
        sentences.append("Every question becomes a memory.")
        sentences.append("Some stories only they can tell.")

        // Action bias (very rare)
        sentences.append("Today is a good day to ask.")

        // If no data, use emotional/action only
        if sentences.count < 3 {
            sentences.append("Memories fade. Voices don't.")
            sentences.append("One question can change what you remember.")
            sentences.append("A story is waiting.")
        }

        return sentences
    }

    // MARK: - Load Activity

    func loadActivity() async {
        do {
            let journals = try await JournalService.shared.listJournals()
            let recordingsResponse = try await RecordingService.shared.listRecordings()
            let recordings = recordingsResponse.recordings

            // Build per-person activity data
            var personActivityMap: [String: PersonActivityData] = [:]
            var totalUnanswered = 0

            for journal in journals {
                guard let person = journal.dedicatedToPerson else { continue }
                if person.isSelf { continue }

                let unansweredCount = journal.questionCount - journal.answeredCount
                if unansweredCount <= 0 { continue }

                totalUnanswered += unansweredCount

                var personData = personActivityMap[person.id] ?? PersonActivityData(
                    personId: person.id,
                    personName: person.name,
                    personPhotoUrl: person.profilePhotoUrl
                )

                personData.journalsWithUnanswered.append(JournalActivityData(
                    journalId: journal.id,
                    journalTitle: journal.title,
                    unansweredCount: unansweredCount,
                    createdAt: journal.createdAt
                ))

                personData.totalUnanswered += unansweredCount
                personActivityMap[person.id] = personData
            }

            // Calculate last reply time
            if let latestRecording = recordings.first,
               let recordedAt = latestRecording.recordedAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                lastReplyTimeAgo = formatter.localizedString(for: recordedAt, relativeTo: Date())
            }

            // Track response rates
            var personRecordingCounts: [String: (total: Int, recent: Date?)] = [:]
            for recording in recordings {
                guard let person = recording.person else { continue }
                var data = personRecordingCounts[person.id] ?? (total: 0, recent: nil)
                data.total += 1
                if let recordedAt = recording.recordedAt {
                    if data.recent == nil || recordedAt > data.recent! {
                        data.recent = recordedAt
                    }
                }
                personRecordingCounts[person.id] = data
            }

            // Build items sorted by oldest first
            var items: [InProgressItem] = []

            for (personId, personData) in personActivityMap {
                guard let oldestJournal = personData.journalsWithUnanswered.min(by: { $0.createdAt < $1.createdAt }) else { continue }

                let recordingData = personRecordingCounts[personId]

                let item = InProgressItem(
                    id: "\(personId)-\(oldestJournal.journalId)",
                    personId: personId,
                    personName: personData.personName,
                    personPhotoUrl: personData.personPhotoUrl,
                    journalId: oldestJournal.journalId,
                    journalTitle: oldestJournal.journalTitle,
                    primaryText: "Waiting on \(personData.personName)",
                    secondaryText: formatLastReplyShort(recordingData?.recent),
                    tertiaryText: nil,
                    unansweredCount: personData.totalUnanswered,
                    oldestUnansweredDate: oldestJournal.createdAt,
                    lastActivityDate: recordingData?.recent,
                    responseRate: calculateResponseRate(
                        totalSent: personData.totalUnanswered + (recordingData?.total ?? 0),
                        totalAnswered: recordingData?.total ?? 0
                    )
                )

                items.append(item)
            }

            // Sort by oldest unanswered (most meaningful loose end first)
            items.sort { item1, item2 in
                guard let date1 = item1.oldestUnansweredDate,
                      let date2 = item2.oldestUnansweredDate else { return false }
                return date1 < date2
            }

            // Update counts
            peopleOwingStoriesCount = items.count
            totalUnansweredCount = totalUnanswered
            longestWaitingPersonName = items.first?.personName

            // Only update cards if we haven't loaded yet OR if data meaningfully changed
            if loadedCardOne == nil || hasDataChanged(newItems: items) {
                loadedCardOne = items.first
                loadedCardTwo = items.count > 1 ? createContinueCard(from: items[1]) : nil
            }

            cardOne = loadedCardOne
            cardTwo = loadedCardTwo

        } catch {
            print("Failed to load activity: \(error)")
        }
    }

    private func hasDataChanged(newItems: [InProgressItem]) -> Bool {
        // Check if the primary card person changed
        if let currentFirst = loadedCardOne,
           let newFirst = newItems.first {
            return currentFirst.personId != newFirst.personId ||
                   currentFirst.unansweredCount != newFirst.unansweredCount
        }
        return true
    }

    private func createContinueCard(from item: InProgressItem) -> InProgressItem {
        // Transform to "Continue" style
        return InProgressItem(
            id: item.id + "-continue",
            personId: item.personId,
            personName: item.personName,
            personPhotoUrl: item.personPhotoUrl,
            journalId: item.journalId,
            journalTitle: item.journalTitle,
            primaryText: "Continue \(item.journalTitle)",
            secondaryText: formatContinueSubtitle(item),
            tertiaryText: nil,
            unansweredCount: item.unansweredCount,
            oldestUnansweredDate: item.oldestUnansweredDate,
            lastActivityDate: item.lastActivityDate,
            responseRate: item.responseRate
        )
    }

    private func formatContinueSubtitle(_ item: InProgressItem) -> String {
        return "\(item.unansweredCount) awaiting"
    }

    private func formatLastReply(_ date: Date?, personName: String) -> String? {
        guard let date = date else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Last reply from \(personName) — \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private func formatLastReplyShort(_ date: Date?) -> String {
        guard let date = date else { return "No replies yet" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last reply \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private func calculateResponseRate(totalSent: Int, totalAnswered: Int) -> Double {
        guard totalSent > 0 else { return 0.5 }
        return Double(totalAnswered) / Double(totalSent)
    }
}

// MARK: - Helper Types
private struct PersonActivityData {
    let personId: String
    let personName: String
    let personPhotoUrl: String?
    var journalsWithUnanswered: [JournalActivityData] = []
    var totalUnanswered: Int = 0
}

private struct JournalActivityData {
    let journalId: String
    let journalTitle: String
    let unansweredCount: Int
    let createdAt: Date
}

// MARK: - Preview
#Preview {
    HubView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
