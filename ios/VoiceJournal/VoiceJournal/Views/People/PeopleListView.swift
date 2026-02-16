import SwiftUI

struct PeopleListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = PeopleViewModel()
    @State private var showingAddPerson = false
    @State private var selectedPerson: Person?
    @State private var showingProfileEdit = false

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
                            // Myself card (always at top, tappable to edit profile)
                            if let myself = viewModel.myselfPerson {
                                MyselfCard(person: myself, colors: colors)
                                    .onTapGesture {
                                        showingProfileEdit = true
                                    }
                            }

                            // Section header for family & friends
                            if !viewModel.people.isEmpty {
                                Text("Family & Friends")
                                    .font(AppTypography.labelMedium)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
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
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))

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
                    Task { await reloadPeople() }
                })
            }
            .sheet(item: $selectedPerson) { person in
                EditPersonSheet(person: person, onSave: {
                    Task { await reloadPeople() }
                }, onDelete: {
                    Task { await reloadPeople() }
                })
            }
            .sheet(isPresented: $showingProfileEdit) {
                NavigationStack {
                    ProfileEditView()
                        .environmentObject(appState)
                }
            }
            .onChange(of: showingProfileEdit) { _, isShowing in
                if !isShowing {
                    Task { await reloadPeople() }
                }
            }
        }
        .task {
            await reloadPeople()
        }
    }

    /// Loads people from API and ensures "Myself" card is always present with latest user data
    private func reloadPeople() async {
        await viewModel.loadPeople()
        if let user = appState.currentUser {
            viewModel.refreshSyntheticMyself(from: user)
        }
    }
}

// MARK: - Myself Card
struct MyselfCard: View {
    @Environment(\.colorScheme) var colorScheme

    let person: Person
    let colors: AppColors

    // Surface color - matches HubView glass style
    private var cardSurface: Color {
        colorScheme == .dark
            ? Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.68)
            : Color.white.opacity(0.75)
    }

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
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))

                Text("Record your own stories")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }

            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundColor(colors.accentPrimary)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.12), radius: 12, x: 0, y: 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Person Card
struct PersonCard: View {
    @Environment(\.colorScheme) var colorScheme

    let person: Person
    let colors: AppColors

    // Surface color - matches HubView glass style
    private var cardSurface: Color {
        colorScheme == .dark
            ? Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.64)
            : Color.white.opacity(0.70)
    }

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
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))

                Text(person.displayRelationship)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))

                if let recordings = person.totalRecordings, recordings > 0 {
                    Text("\(recordings) recording\(recordings == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(colors.accentPrimary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.10), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview
#Preview {
    PeopleListView()
        .preferredColorScheme(.dark)
}
