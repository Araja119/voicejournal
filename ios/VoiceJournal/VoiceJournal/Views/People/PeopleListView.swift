import SwiftUI

struct PeopleListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PeopleViewModel()
    @State private var showingAddPerson = false
    @State private var selectedPerson: Person?

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                AppBackground()

                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            // Myself card (always at top)
                            if let myself = viewModel.myselfPerson {
                                MyselfCard(person: myself, colors: colors)
                            }

                            // Section header for family & friends
                            if !viewModel.people.isEmpty {
                                Text("Family & Friends")
                                    .font(AppTypography.labelMedium)
                                    .foregroundColor(colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, Theme.Spacing.sm)
                            }

                            // Other people
                            ForEach(viewModel.people) { person in
                                PersonCard(person: person, colors: colors)
                                    .onTapGesture {
                                        selectedPerson = person
                                    }
                            }

                            // Empty state for no other people
                            if viewModel.people.isEmpty {
                                VStack(spacing: Theme.Spacing.md) {
                                    Text("No family or friends added yet")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(colors.textSecondary)

                                    Button(action: { showingAddPerson = true }) {
                                        HStack {
                                            Image(systemName: "plus")
                                            Text("Add Person")
                                        }
                                        .font(AppTypography.labelMedium)
                                        .foregroundColor(colors.accentPrimary)
                                    }
                                }
                                .padding(.top, Theme.Spacing.xl)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("My People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPerson = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(colors.accentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                AddPersonSheet(onSave: { _ in
                    Task { await viewModel.loadPeople() }
                })
            }
            .sheet(item: $selectedPerson) { person in
                EditPersonSheet(person: person, onSave: {
                    Task { await viewModel.loadPeople() }
                }, onDelete: {
                    Task { await viewModel.loadPeople() }
                })
            }
        }
        .task {
            // Load people first
            await viewModel.loadPeople()

            // If no "myself" person from database, create synthetic one from current user
            if viewModel.myselfPerson == nil, let user = appState.currentUser {
                viewModel.createSyntheticMyself(from: user)
            }
        }
    }
}

// MARK: - Myself Card
struct MyselfCard: View {
    let person: Person
    let colors: AppColors

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            AvatarView(
                name: person.name,
                imageURL: person.profilePhotoUrl,
                size: 56,
                colors: colors
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Myself")
                    .font(AppTypography.headlineSmall)
                    .foregroundColor(colors.textPrimary)

                Text("Record your own stories")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(colors.textSecondary)
            }

            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(colors.accentPrimary)
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface)
        .cornerRadius(Theme.Radius.md)
    }
}

// MARK: - Person Card
struct PersonCard: View {
    let person: Person
    let colors: AppColors

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            AvatarView(
                name: person.name,
                imageURL: person.profilePhotoUrl,
                size: 56,
                colors: colors
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(person.name)
                    .font(AppTypography.headlineSmall)
                    .foregroundColor(colors.textPrimary)

                Text(person.displayRelationship)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(colors.textSecondary)

                if let recordings = person.totalRecordings, recordings > 0 {
                    Text("\(recordings) recording\(recordings == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(colors.accentPrimary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(colors.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface)
        .cornerRadius(Theme.Radius.md)
    }
}

// MARK: - Preview
#Preview {
    PeopleListView()
        .preferredColorScheme(.dark)
}
