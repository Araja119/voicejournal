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
                            ForEach(Array(allPersonSections.enumerated()), id: \.element.personId) { index, section in
                                PersonJournalSection(
                                    section: section,
                                    isStarred: starredPersonIds.contains(section.personId),
                                    canStar: starredPersonIds.count < maxStarredPeople || starredPersonIds.contains(section.personId),
                                    isCollapsed: collapsedSections.contains(section.personId),
                                    isFirst: index == 0,
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
                                    isFirst: allPersonSections.isEmpty,
                                    onToggleCollapse: { toggleCollapse(sectionId: "general") },
                                    onDelete: { Task { await viewModel.loadJournals() } },
                                    colors: colors
                                )
                            }
                        }
                        .padding(.top, Theme.Spacing.md)
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
    @Environment(\.colorScheme) var colorScheme

    let section: JournalSection
    let isStarred: Bool
    let canStar: Bool
    let isCollapsed: Bool
    let isFirst: Bool
    let onToggleStar: () -> Void
    let onToggleCollapse: () -> Void
    let onDelete: () -> Void
    let colors: AppColors

    // Activity summary text - neutral colors, no gold
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
        let textColors = GlassTextColors(colorScheme: colorScheme)

        // Single glass container for person + all their journals
        VStack(spacing: 0) {
            // Person header row
            Button(action: onToggleCollapse) {
                HStack(spacing: Theme.Spacing.md) {
                    // Avatar
                    AvatarView(
                        name: section.person.name,
                        imageURL: section.person.profilePhotoUrl,
                        size: 44,
                        colors: colors
                    )

                    // Name + stats
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.person.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(textColors.primary)

                        Text(activitySummary)
                            .font(.system(size: 13))
                            .foregroundColor(textColors.secondary)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColors.tertiary)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Journals inside the same container - NO dividers, spacing creates separation
            if !isCollapsed {
                VStack(spacing: 4) {  // Spacing instead of divider lines
                    ForEach(section.journals, id: \.id) { journal in
                        NavigationLink {
                            JournalDetailView(journalId: journal.id, onDelete: onDelete)
                        } label: {
                            CompactJournalCard(journal: journal, colors: colors)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 10)
            }
        }
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, isFirst ? 0 : 20)
    }
}

// MARK: - General Journal Section
struct GeneralJournalSection: View {
    @Environment(\.colorScheme) var colorScheme

    let journals: [Journal]
    let isCollapsed: Bool
    let isFirst: Bool
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
        let textColors = GlassTextColors(colorScheme: colorScheme)

        VStack(spacing: 0) {
            // Header row
            Button(action: onToggleCollapse) {
                HStack(spacing: Theme.Spacing.md) {
                    GlassIconCircle(icon: "book.closed.fill", iconColor: GlassIconColors.slate, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("General")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(textColors.primary)

                        Text(activitySummary)
                            .font(.system(size: 13))
                            .foregroundColor(textColors.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColors.tertiary)
                        .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Journals inside container - NO dividers, spacing creates separation
            if !isCollapsed {
                VStack(spacing: 4) {  // Spacing instead of divider lines
                    ForEach(journals, id: \.id) { journal in
                        NavigationLink {
                            JournalDetailView(journalId: journal.id, onDelete: onDelete)
                        } label: {
                            CompactJournalCard(journal: journal, colors: colors)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 10)
            }
        }
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, isFirst ? 0 : 20)
    }
}

// MARK: - Compact Journal Row (simple row inside container, no decoration)
struct CompactJournalCard: View {
    @Environment(\.colorScheme) var colorScheme

    let journal: Journal
    let colors: AppColors

    // Activity state
    private var isActive: Bool {
        journal.questionCount > 0 && journal.answeredCount < journal.questionCount
    }

    private var awaitingCount: Int {
        journal.questionCount - journal.answeredCount
    }

    // Status text
    private var statusText: String? {
        if journal.questionCount == 0 {
            return "No questions yet"
        } else if journal.answeredCount == 0 {
            return "\(journal.questionCount) sent • awaiting"
        } else if awaitingCount > 0 {
            return "\(journal.answeredCount) recorded • \(awaitingCount) awaiting"
        } else {
            return "\(journal.answeredCount) recorded"
        }
    }

    var body: some View {
        let textColors = GlassTextColors(colorScheme: colorScheme)

        HStack(spacing: 12) {
            // Cover placeholder
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
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(journal.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textColors.primary)
                    .lineLimit(1)

                if let status = statusText {
                    Text(status)
                        .font(.system(size: 12))
                        .foregroundColor(textColors.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textColors.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    // Journal tile icon - solid object that sits ON the glass, not faded into it
    private var coverPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.black.opacity(0.06))  // Dark fill creates contrast on light glass

            Image(systemName: "book.closed.fill")  // Filled icon, not outline
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark
                    ? .white.opacity(0.35)
                    : .black.opacity(0.55))  // Strong ink, not faded
        }
        .shadow(color: colorScheme == .dark
            ? .black.opacity(0.15)
            : .black.opacity(0.08),
            radius: 4, x: 0, y: 2)  // Micro shadow - tile sits ON glass
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
