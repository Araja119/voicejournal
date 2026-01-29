import SwiftUI

struct PeopleListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PeopleViewModel()
    @State private var showingAddPerson = false
    @State private var selectedPerson: Person?

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.people.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No People Yet",
                        message: "Add your first person to start sending them questions",
                        actionTitle: "Add Person",
                        action: { showingAddPerson = true },
                        colors: colors
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(viewModel.people) { person in
                                PersonCard(person: person, colors: colors)
                                    .onTapGesture {
                                        selectedPerson = person
                                    }
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
            await viewModel.loadPeople()
        }
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
