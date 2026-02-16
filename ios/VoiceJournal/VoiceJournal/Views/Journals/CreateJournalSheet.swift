import SwiftUI
import PhotosUI

struct CreateJournalSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @StateObject private var peopleViewModel = PeopleViewModel()

    @State private var title = ""
    @State private var description = ""
    @State private var selectedPerson: Person?
    @State private var isPersonPickerExpanded = false
    @State private var showingAddPerson = false
    @State private var isSaving = false
    @State private var error: String?

    var onCreate: (Journal) -> Void

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Title
                        InputField(
                            title: "Journal Title",
                            text: $title,
                            placeholder: "e.g., Mom's Life Story",
                            colors: colors
                        )

                        // Dedicated To Person Picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Dedicated To")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            VStack(spacing: 0) {
                                // Header / Selected value
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isPersonPickerExpanded.toggle()
                                    }
                                }) {
                                    HStack {
                                        if let person = selectedPerson {
                                            AvatarView(name: person.name, imageURL: person.profilePhotoUrl, size: 28, colors: colors)
                                            Text(person.isSelf ? "Myself" : person.name)
                                                .foregroundColor(colors.textPrimary)
                                        } else {
                                            Image(systemName: "person.crop.circle")
                                                .font(.system(size: 24))
                                                .foregroundColor(colors.textSecondary)
                                            Text("Select a person")
                                                .foregroundColor(colors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: isPersonPickerExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    .font(AppTypography.bodyLarge)
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.vertical, Theme.Spacing.md)
                                }

                                // Expandable options
                                if isPersonPickerExpanded {
                                    // Myself option (first, with special styling)
                                    if let myself = peopleViewModel.myselfPerson {
                                        Divider()
                                            .background(colors.background)

                                        Button(action: {
                                            selectedPerson = myself
                                            withAnimation { isPersonPickerExpanded = false }
                                        }) {
                                            HStack {
                                                AvatarView(name: myself.name, imageURL: myself.profilePhotoUrl, size: 28, colors: colors)
                                                VStack(alignment: .leading, spacing: 0) {
                                                    Text("Myself")
                                                        .foregroundColor(colors.textPrimary)
                                                    Text("Record your own stories")
                                                        .font(AppTypography.caption)
                                                        .foregroundColor(colors.textSecondary)
                                                }
                                                Spacer()
                                                if selectedPerson?.id == myself.id {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(colors.accentPrimary)
                                                }
                                            }
                                            .font(AppTypography.bodyMedium)
                                            .padding(.horizontal, Theme.Spacing.md)
                                            .padding(.vertical, Theme.Spacing.sm)
                                            .background(colors.accentPrimary.opacity(0.05))
                                        }
                                    }

                                    // People list (excluding myself)
                                    ForEach(peopleViewModel.people) { person in
                                        Divider()
                                            .background(colors.background)

                                        Button(action: {
                                            selectedPerson = person
                                            withAnimation { isPersonPickerExpanded = false }
                                        }) {
                                            HStack {
                                                AvatarView(name: person.name, imageURL: person.profilePhotoUrl, size: 28, colors: colors)
                                                VStack(alignment: .leading, spacing: 0) {
                                                    Text(person.name)
                                                        .foregroundColor(colors.textPrimary)
                                                    Text(person.displayRelationship)
                                                        .font(AppTypography.caption)
                                                        .foregroundColor(colors.textSecondary)
                                                }
                                                Spacer()
                                                if selectedPerson?.id == person.id {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(colors.accentPrimary)
                                                }
                                            }
                                            .font(AppTypography.bodyMedium)
                                            .padding(.horizontal, Theme.Spacing.md)
                                            .padding(.vertical, Theme.Spacing.sm)
                                        }
                                    }

                                    // Add new person option
                                    Divider()
                                        .background(colors.background)

                                    Button(action: {
                                        withAnimation { isPersonPickerExpanded = false }
                                        showingAddPerson = true
                                    }) {
                                        HStack {
                                            ZStack {
                                                Circle()
                                                    .fill(colors.accentPrimary.opacity(0.2))
                                                    .frame(width: 28, height: 28)
                                                Image(systemName: "plus")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(colors.accentPrimary)
                                            }
                                            Text("Add New Person")
                                                .foregroundColor(colors.accentPrimary)
                                            Spacer()
                                        }
                                        .font(AppTypography.bodyMedium)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .padding(.vertical, Theme.Spacing.sm)
                                    }
                                }
                            }
                            .background(colors.surface)
                            .cornerRadius(Theme.Radius.md)

                            Text("Choose who this journal is for to keep your journals organized")
                                .font(AppTypography.caption)
                                .foregroundColor(colors.textSecondary)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Description (optional)")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            TextEditor(text: $description)
                                .font(AppTypography.bodyLarge)
                                .foregroundColor(colors.textPrimary)
                                .frame(minHeight: 100)
                                .padding(Theme.Spacing.sm)
                                .background(colors.surface)
                                .cornerRadius(Theme.Radius.md)
                        }

                        if let error = error {
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(.red)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
                }
            }
            .navigationTitle("New Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { create() }
                        .foregroundColor(colors.accentPrimary)
                        .disabled(title.isEmpty || isSaving)
                }
            }
        }
        .task {
            // Load people first
            await peopleViewModel.loadPeople()

            // Ensure "myself" person exists with latest user data
            if let user = appState.currentUser {
                peopleViewModel.refreshSyntheticMyself(from: user)
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            QuickAddPersonSheet { newPerson in
                // Refresh people list and select the updated person (with photo URL)
                Task {
                    await peopleViewModel.loadPeople()
                    // Find the person with updated data (including photo)
                    if let updatedPerson = peopleViewModel.people.first(where: { $0.id == newPerson.id }) {
                        selectedPerson = updatedPerson
                    } else {
                        selectedPerson = newPerson
                    }
                }
            }
        }
    }

    private func create() {
        isSaving = true
        error = nil

        Task {
            do {
                var dedicatedPersonId = selectedPerson?.id

                // If this is a synthetic "myself" person, create a real one first
                if let person = selectedPerson, person.id.hasPrefix("myself-"), let user = appState.currentUser {
                    if let realMyself = await peopleViewModel.ensureRealMyselfExists(user: user) {
                        dedicatedPersonId = realMyself.id
                    }
                }

                let request = CreateJournalRequest(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    privacySetting: "private",
                    dedicatedToPersonId: dedicatedPersonId
                )
                let journal = try await JournalService.shared.createJournal(request)
                onCreate(journal)
                dismiss()
            } catch {
                self.error = "Failed to create journal"
            }
            isSaving = false
        }
    }
}

// MARK: - Quick Add Person Sheet
struct QuickAddPersonSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var relationship = "parent"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    @State private var error: String?

    var onSave: (Person) -> Void

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Profile Photo
                        VStack(spacing: Theme.Spacing.sm) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                if let imageData = selectedImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(colors.accentPrimary, lineWidth: 3)
                                        )
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(colors.surface)
                                            .frame(width: 80, height: 80)

                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 32))
                                            .foregroundColor(colors.textSecondary)
                                    }
                                }
                            }
                            .onChange(of: selectedPhoto) { _, newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                        selectedImageData = data
                                    }
                                }
                            }

                            Text(selectedImageData != nil ? "Change Photo" : "Add Photo")
                                .font(AppTypography.caption)
                                .foregroundColor(colors.accentPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.sm)

                        // Name
                        InputField(
                            title: "Name",
                            text: $name,
                            placeholder: "Who is this person?",
                            textContentType: .name,
                            colors: colors
                        )

                        // Relationship Picker
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Relationship")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            Menu {
                                // Filter out "self" - only system can create that
                                ForEach(RelationshipType.allTypes.filter { $0 != "self" }, id: \.self) { type in
                                    Button(action: { relationship = type }) {
                                        HStack {
                                            Text(RelationshipType.displayName(for: type))
                                            if relationship == type {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(RelationshipType.displayName(for: relationship))
                                        .foregroundColor(colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(colors.textSecondary)
                                }
                                .font(AppTypography.bodyLarge)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(colors.surface)
                                .cornerRadius(Theme.Radius.md)
                            }
                        }

                        if let error = error {
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(.red)
                        }

                        Text("You can add more details like email and phone number later in My People.")
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { save() }
                        .foregroundColor(colors.accentPrimary)
                        .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        error = nil

        Task {
            do {
                let request = CreatePersonRequest(
                    name: name,
                    relationship: relationship,
                    email: nil,
                    phoneNumber: nil
                )
                let person = try await PeopleService.shared.createPerson(request)

                // Upload photo if selected
                if let imageData = selectedImageData {
                    let compressed = ImageUtils.compressForUpload(imageData) ?? imageData
                    _ = try? await PeopleService.shared.uploadPhoto(
                        personId: person.id,
                        imageData: compressed,
                        mimeType: "image/jpeg"
                    )
                }

                onSave(person)
                dismiss()
            } catch {
                self.error = "Failed to add person"
            }
            isSaving = false
        }
    }
}

// MARK: - Preview
#Preview {
    CreateJournalSheet(onCreate: { _ in })
        .preferredColorScheme(.dark)
}
