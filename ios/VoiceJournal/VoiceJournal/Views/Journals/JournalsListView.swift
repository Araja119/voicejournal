import SwiftUI

struct JournalsListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingCreateJournal = false
    @State private var starredPersonIds: Set<String> = []
    @State private var collapsedSections: Set<String> = []
    @State private var navigationPath = NavigationPath()

    private let maxStarredPeople = 5

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack(path: $navigationPath) {
            ZStack {
                AppBackground()

                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.journals.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "No Journals Yet",
                        message: "Create your first journal to start collecting stories from loved ones",
                        actionTitle: "Create Journal",
                        action: { showingCreateJournal = true },
                        colors: colors
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // All person sections (starred first, then alphabetical)
                            ForEach(allPersonSections, id: \.personId) { section in
                                PersonJournalSection(
                                    section: section,
                                    isStarred: starredPersonIds.contains(section.personId),
                                    canStar: starredPersonIds.count < maxStarredPeople || starredPersonIds.contains(section.personId),
                                    isCollapsed: collapsedSections.contains(section.personId),
                                    onToggleStar: { toggleStar(personId: section.personId) },
                                    onToggleCollapse: { toggleCollapse(sectionId: section.personId) },
                                    onDelete: { Task { await viewModel.loadJournals() } },
                                    colors: colors
                                )
                            }

                            // General journals (no dedicated person)
                            if !generalJournals.isEmpty {
                                GeneralJournalSection(
                                    journals: generalJournals,
                                    isCollapsed: collapsedSections.contains("general"),
                                    onToggleCollapse: { toggleCollapse(sectionId: "general") },
                                    onDelete: { Task { await viewModel.loadJournals() } },
                                    colors: colors
                                )
                            }
                        }
                        .padding(.top, Theme.Spacing.sm)
                        .padding(.bottom, Theme.Spacing.xxl)
                        .animation(.easeInOut(duration: 0.2), value: starredPersonIds)
                    }
                }
            }
            .navigationTitle("Journals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateJournal = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(colors.accentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateJournal) {
                CreateJournalSheet(onCreate: { journal in
                    Task {
                        await viewModel.loadJournals()
                        // Small delay to ensure sheet is dismissed before navigation
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        navigationPath.append(journal.id)
                    }
                })
            }
            .navigationDestination(for: String.self) { journalId in
                JournalDetailView(journalId: journalId) {
                    Task { await viewModel.loadJournals() }
                }
            }
        }
        .task {
            loadStarredPeople()
            await viewModel.loadJournals()
        }
        .refreshable {
            await viewModel.loadJournals()
        }
    }

    // MARK: - Grouped Data

    private var journalsByPerson: [String: [Journal]] {
        var grouped: [String: [Journal]] = [:]
        for journal in viewModel.journals {
            if let person = journal.dedicatedToPerson {
                grouped[person.id, default: []].append(journal)
            }
        }
        return grouped
    }

    private var generalJournals: [Journal] {
        viewModel.journals.filter { $0.dedicatedToPerson == nil }
    }

    private var allPersonSections: [JournalSection] {
        let sections = journalsByPerson
            .compactMap { personId, journals -> JournalSection? in
                guard let person = journals.first?.dedicatedToPerson else { return nil }
                return JournalSection(personId: personId, person: person, journals: journals)
            }

        // Sort: starred first (alphabetically), then non-starred (alphabetically)
        return sections.sorted { a, b in
            let aStarred = starredPersonIds.contains(a.personId)
            let bStarred = starredPersonIds.contains(b.personId)

            if aStarred && !bStarred { return true }
            if !aStarred && bStarred { return false }
            return a.person.name.lowercased() < b.person.name.lowercased()
        }
    }

    // MARK: - Star Management

    private func loadStarredPeople() {
        if let saved = UserDefaults.standard.array(forKey: "starredPeopleIds") as? [String] {
            starredPersonIds = Set(saved)
        }
    }

    private func saveStarredPeople() {
        UserDefaults.standard.set(Array(starredPersonIds), forKey: "starredPeopleIds")
    }

    private func toggleStar(personId: String) {
        if starredPersonIds.contains(personId) {
            starredPersonIds.remove(personId)
        } else if starredPersonIds.count < maxStarredPeople {
            starredPersonIds.insert(personId)
        }
        saveStarredPeople()
    }

    private func toggleCollapse(sectionId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if collapsedSections.contains(sectionId) {
                collapsedSections.remove(sectionId)
            } else {
                collapsedSections.insert(sectionId)
            }
        }
    }
}

// MARK: - Journal Section Model
struct JournalSection {
    let personId: String
    let person: JournalPerson
    let journals: [Journal]

    // Computed activity stats for the section
    var totalQuestions: Int {
        journals.reduce(0) { $0 + $1.questionCount }
    }

    var totalAnswered: Int {
        journals.reduce(0) { $0 + $1.answeredCount }
    }

    var awaitingCount: Int {
        totalQuestions - totalAnswered
    }

    var hasActivity: Bool {
        totalQuestions > 0 && awaitingCount > 0
    }
}

// MARK: - Person Journal Section
struct PersonJournalSection: View {
    let section: JournalSection
    let isStarred: Bool
    let canStar: Bool
    let isCollapsed: Bool
    let onToggleStar: () -> Void
    let onToggleCollapse: () -> Void
    let onDelete: () -> Void
    let colors: AppColors

    // Activity summary text
    private var activitySummary: String {
        let journalText = "\(section.journals.count) journal\(section.journals.count == 1 ? "" : "s")"

        if section.awaitingCount > 0 {
            return "\(journalText) • \(section.awaitingCount) awaiting"
        } else if section.totalAnswered > 0 {
            return "\(journalText) • \(section.totalAnswered) recorded"
        }
        return journalText
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section Header - elevated as narrative anchor
            HStack(spacing: Theme.Spacing.md) {
                // Tappable area for collapse
                Button(action: onToggleCollapse) {
                    HStack(spacing: Theme.Spacing.md) {
                        // Larger avatar for person prominence
                        AvatarView(
                            name: section.person.name,
                            imageURL: section.person.profilePhotoUrl,
                            size: 44,
                            colors: colors
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.person.name)
                                .font(AppTypography.headlineSmall)
                                .foregroundColor(colors.textPrimary)

                            // Activity summary with meaning
                            HStack(spacing: Theme.Spacing.xs) {
                                if section.hasActivity {
                                    Circle()
                                        .fill(colors.accentSecondary)
                                        .frame(width: 6, height: 6)
                                }
                                Text(activitySummary)
                                    .font(AppTypography.caption)
                                    .foregroundColor(section.hasActivity ? colors.accentSecondary : colors.textSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Pin button (star = pin person to top)
                Button(action: onToggleStar) {
                    Image(systemName: isStarred ? "pin.fill" : "pin")
                        .font(.system(size: 16))
                        .foregroundColor(isStarred ? colors.accentPrimary : colors.textSecondary.opacity(canStar ? 0.6 : 0.3))
                        .rotationEffect(.degrees(isStarred ? 0 : 45))
                }
                .disabled(!isStarred && !canStar)

                // Collapse indicator (tappable)
                Button(action: onToggleCollapse) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(colors.surface.opacity(0.5))

            // Journals (collapsible)
            if !isCollapsed {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(section.journals) { journal in
                        NavigationLink {
                            JournalDetailView(journalId: journal.id, onDelete: onDelete)
                        } label: {
                            CompactJournalCard(journal: journal, colors: colors)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
            }

            // Thicker divider for section separation
            Rectangle()
                .fill(colors.textSecondary.opacity(0.15))
                .frame(height: 2)
                .padding(.top, Theme.Spacing.xs)
        }
    }
}

// MARK: - General Journal Section
struct GeneralJournalSection: View {
    let journals: [Journal]
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    let onDelete: () -> Void
    let colors: AppColors

    // Activity stats
    private var totalQuestions: Int {
        journals.reduce(0) { $0 + $1.questionCount }
    }

    private var totalAnswered: Int {
        journals.reduce(0) { $0 + $1.answeredCount }
    }

    private var awaitingCount: Int {
        totalQuestions - totalAnswered
    }

    private var activitySummary: String {
        let journalText = "\(journals.count) journal\(journals.count == 1 ? "" : "s")"
        if awaitingCount > 0 {
            return "\(journalText) • \(awaitingCount) awaiting"
        }
        return journalText
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section Header (tappable to collapse)
            Button(action: onToggleCollapse) {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(colors.textSecondary.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 18))
                            .foregroundColor(colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("General")
                            .font(AppTypography.headlineSmall)
                            .foregroundColor(colors.textPrimary)

                        Text(activitySummary)
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary)
                    }

                    Spacer()

                    // Collapse indicator with animation
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colors.textSecondary)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(colors.surface.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())

            // Journals (collapsible)
            if !isCollapsed {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(journals) { journal in
                        NavigationLink {
                            JournalDetailView(journalId: journal.id, onDelete: onDelete)
                        } label: {
                            CompactJournalCard(journal: journal, colors: colors)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
            }

            // Thicker divider for section separation
            Rectangle()
                .fill(colors.textSecondary.opacity(0.15))
                .frame(height: 2)
                .padding(.top, Theme.Spacing.xs)
        }
    }
}

// MARK: - Compact Journal Card
struct CompactJournalCard: View {
    let journal: Journal
    let colors: AppColors

    // Activity state
    private var isActive: Bool {
        journal.questionCount > 0 && journal.answeredCount < journal.questionCount
    }

    private var awaitingCount: Int {
        journal.questionCount - journal.answeredCount
    }

    // Meaningful status text instead of raw numbers
    // For empty journals, let the CTA do the talking
    private var statusText: String? {
        if journal.questionCount == 0 {
            return nil  // Don't show status for empty - CTA is enough
        } else if journal.answeredCount == 0 {
            return "\(journal.questionCount) sent • awaiting replies"
        } else if awaitingCount > 0 {
            return "\(journal.answeredCount) recorded • \(awaitingCount) awaiting"
        } else {
            return "\(journal.answeredCount) recorded"
        }
    }

    // Next action hint
    private var nextActionHint: String? {
        if journal.questionCount == 0 {
            return "Start this journal"
        } else if isActive {
            return "Awaiting response"
        }
        return nil
    }

    // Whether this is an empty/not-started journal
    private var isEmpty: Bool {
        journal.questionCount == 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Activity indicator - accent line on left for active journals
            Rectangle()
                .fill(isActive ? colors.accentSecondary : Color.clear)
                .frame(width: 3)

            HStack(spacing: Theme.Spacing.md) {
                // Cover image or placeholder
                Group {
                    if let coverUrl = journal.coverImageUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                coverPlaceholder
                            }
                        }
                    } else {
                        coverPlaceholder
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))

                // Info
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(journal.title)
                        .font(AppTypography.labelLarge)
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)

                    // Meaningful status (only for non-empty journals)
                    if let status = statusText {
                        Text(status)
                            .font(AppTypography.caption)
                            .foregroundColor(isActive ? colors.textSecondary : colors.textSecondary.opacity(0.7))
                            .lineLimit(1)
                    }

                    // Next action hint (subtle, not a button)
                    if let hint = nextActionHint {
                        Text(hint)
                            .font(AppTypography.caption)
                            .foregroundColor(isEmpty ? colors.accentPrimary.opacity(0.8) : colors.accentSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colors.textSecondary.opacity(0.6))
            }
            .padding(Theme.Spacing.sm)
        }
        .background(isActive ? colors.surface : colors.surface.opacity(0.8))
        .cornerRadius(Theme.Radius.md)
    }

    private var coverPlaceholder: some View {
        Rectangle()
            .fill(colors.accentPrimary.opacity(0.1))
            .overlay(
                Image(systemName: "book.fill")
                    .font(.system(size: 18))
                    .foregroundColor(colors.accentPrimary.opacity(0.3))
            )
    }
}

// MARK: - Original Journal Card (keeping for reference)
struct JournalCard: View {
    let journal: Journal
    let colors: AppColors

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Cover image or placeholder
            if let coverUrl = journal.coverImageUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        coverPlaceholder
                    }
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(Theme.Radius.md)
            } else {
                coverPlaceholder
            }

            // Title and dedicated person
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(journal.title)
                    .font(AppTypography.headlineSmall)
                    .foregroundColor(colors.textPrimary)

                // Dedicated to person
                if let person = journal.dedicatedToPerson {
                    HStack(spacing: Theme.Spacing.xs) {
                        AvatarView(name: person.name, imageURL: person.profilePhotoUrl, size: 20, colors: colors)
                        Text("For \(person.name)")
                            .font(AppTypography.caption)
                            .foregroundColor(colors.accentPrimary)
                    }
                }

                if let description = journal.description {
                    Text(description)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                }
            }

            // Stats
            HStack(spacing: Theme.Spacing.md) {
                Label("\(journal.questionCount)", systemImage: "questionmark.circle")
                Label("\(journal.answeredCount)", systemImage: "waveform")
                Label("\(journal.personCount)", systemImage: "person")
            }
            .font(AppTypography.caption)
            .foregroundColor(colors.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface)
        .cornerRadius(Theme.Radius.lg)
    }

    private var coverPlaceholder: some View {
        Rectangle()
            .fill(colors.accentPrimary.opacity(0.1))
            .frame(height: 120)
            .overlay(
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(colors.accentPrimary.opacity(0.3))
            )
            .cornerRadius(Theme.Radius.md)
    }
}

// MARK: - Preview
#Preview {
    JournalsListView()
        .preferredColorScheme(.dark)
}
