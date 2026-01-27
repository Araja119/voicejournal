import SwiftUI

struct JournalsListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingCreateJournal = false

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

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
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(viewModel.journals) { journal in
                                NavigationLink {
                                    JournalDetailView(journalId: journal.id)
                                } label: {
                                    JournalCard(journal: journal, colors: colors)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
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
                CreateJournalSheet(onCreate: { _ in
                    Task { await viewModel.loadJournals() }
                })
            }
        }
        .task {
            await viewModel.loadJournals()
        }
    }
}

// MARK: - Journal Card
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

            // Title and description
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(journal.title)
                    .font(AppTypography.headlineSmall)
                    .foregroundColor(colors.textPrimary)

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
