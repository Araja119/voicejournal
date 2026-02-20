import SwiftUI
import PhotosUI

struct EditPersonSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    let person: Person
    var onSave: () -> Void
    var onDelete: () -> Void

    @State private var name: String
    @State private var relationship: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    @State private var isDeleting = false
    @State private var showingDeleteConfirmation = false
    @State private var error: String?

    init(person: Person, onSave: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.person = person
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: person.name)
        _relationship = State(initialValue: person.relationship)
        _email = State(initialValue: person.email ?? "")
        _phoneNumber = State(initialValue: person.phoneNumber ?? "")
    }

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
                                    // Show newly selected photo
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(colors.accentPrimary, lineWidth: 3)
                                        )
                                } else if let photoUrl = person.profilePhotoUrl,
                                          let url = URL(string: photoUrl) {
                                    // Show existing photo
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        default:
                                            AvatarView(name: person.name, size: 100, colors: colors)
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(colors.accentPrimary.opacity(0.5), lineWidth: 2)
                                    )
                                } else {
                                    // Show avatar with edit indicator
                                    ZStack {
                                        AvatarView(name: person.name, size: 100, colors: colors)

                                        Circle()
                                            .fill(colors.accentPrimary)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 35, y: 35)
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

                            Text(selectedImageData != nil || person.profilePhotoUrl != nil ? "Change Photo" : "Add Photo")
                                .font(AppTypography.caption)
                                .foregroundColor(colors.accentPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.md)

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
                                ForEach(RelationshipType.allTypes, id: \.self) { type in
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

                        // Contact Info (optional)
                        Text("Contact Info (optional)")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, Theme.Spacing.sm)

                        InputField(
                            title: "Email",
                            text: $email,
                            placeholder: "email@example.com",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            colors: colors
                        )

                        InputField(
                            title: "Phone",
                            text: $phoneNumber,
                            placeholder: "+1 (555) 123-4567",
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber,
                            colors: colors
                        )

                        if let error = error {
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(.red)
                        }

                        // Delete Button
                        Button(action: { showingDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Person")
                            }
                            .font(AppTypography.labelMedium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
                }
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(colors.accentPrimary)
                        .disabled(name.isEmpty || isSaving)
                }
            }
        }
        .confirmationDialog(
            "Delete \(person.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) { deletePerson() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(person.name) along with ALL of their journals, questions, and voice recordings. This cannot be undone.")
        }
    }

    private func save() {
        isSaving = true
        error = nil

        Task {
            do {
                let request = UpdatePersonRequest(
                    name: name,
                    relationship: relationship,
                    email: email.isEmpty ? nil : email,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                )
                _ = try await PeopleService.shared.updatePerson(id: person.id, request)

                // Upload photo if a new one was selected
                if let imageData = selectedImageData {
                    let compressed = ImageUtils.compressForUpload(imageData) ?? imageData
                    _ = try? await PeopleService.shared.uploadPhoto(
                        personId: person.id,
                        imageData: compressed,
                        mimeType: "image/jpeg"
                    )
                }

                onSave()
                dismiss()
            } catch {
                self.error = "Failed to update person"
            }
            isSaving = false
        }
    }

    private func deletePerson() {
        isDeleting = true

        Task {
            do {
                try await PeopleService.shared.deletePerson(id: person.id)
                onDelete()
                dismiss()
            } catch {
                self.error = "Failed to delete person"
            }
            isDeleting = false
        }
    }
}

// MARK: - Preview
#Preview {
    EditPersonSheet(
        person: Person(
            id: "1",
            name: "John Doe",
            relationship: "parent",
            email: "john@example.com",
            phoneNumber: nil,
            profilePhotoUrl: nil,
            totalRecordings: 5,
            pendingQuestions: 2,
            createdAt: Date()
        ),
        onSave: {},
        onDelete: {}
    )
    .preferredColorScheme(.dark)
}
