import SwiftUI
import PhotosUI
import Contacts
import ContactsUI

struct AddPersonSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var relationship = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false
    @State private var error: String?
    @State private var showingContactPicker = false
    @State private var showRelationshipError = false

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
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(colors.accentPrimary, lineWidth: 3)
                                        )
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(colors.surface)
                                            .frame(width: 100, height: 100)

                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 40))
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

                            Text("Add Photo")
                                .font(AppTypography.caption)
                                .foregroundColor(colors.accentPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.md)

                        // Import from Contacts
                        Button(action: {
                            CNContactStore().requestAccess(for: .contacts) { _, _ in
                                DispatchQueue.main.async {
                                    showingContactPicker = true
                                }
                            }
                        }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 16))
                                Text("Import from Contacts")
                                    .font(AppTypography.labelMedium)
                            }
                            .foregroundColor(colors.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(colors.accentPrimary.opacity(0.1))
                            .cornerRadius(Theme.Radius.md)
                        }

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
                                .foregroundColor(showRelationshipError ? .red : colors.textSecondary)

                            Menu {
                                // Filter out "self" - only system can create that
                                ForEach(RelationshipType.allTypes.filter { $0 != "self" }, id: \.self) { type in
                                    Button(action: {
                                        relationship = type
                                        showRelationshipError = false
                                    }) {
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
                                    if relationship.isEmpty {
                                        Text("Select Relationship")
                                            .foregroundColor(colors.textSecondary)
                                    } else {
                                        Text(RelationshipType.displayName(for: relationship))
                                            .foregroundColor(colors.textPrimary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(colors.textSecondary)
                                }
                                .font(AppTypography.bodyLarge)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(colors.surface)
                                .cornerRadius(Theme.Radius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                                        .stroke(showRelationshipError ? Color.red : Color.clear, lineWidth: 1.5)
                                )
                            }

                            if showRelationshipError {
                                Text("Please select a relationship")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        // Contact Info
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text("Contact Info")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            Text("Add email or phone to send questions")
                                .font(AppTypography.caption)
                                .foregroundColor(colors.textSecondary.opacity(0.7))
                        }
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

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
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
                    Button("Save") { save() }
                        .foregroundColor(colors.accentPrimary)
                        .disabled(name.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker { contact in
                    let fullName = [contact.givenName, contact.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    if !fullName.isEmpty { name = fullName }
                    if let contactEmail = contact.emailAddresses.first?.value as String?, !contactEmail.isEmpty {
                        email = contactEmail
                    }
                    if let contactPhone = contact.phoneNumbers.first?.value.stringValue, !contactPhone.isEmpty {
                        phoneNumber = contactPhone
                    }
                    if let imageData = contact.thumbnailImageData ?? contact.imageData {
                        selectedImageData = imageData
                    }
                }
            }
        }
    }

    private func save() {
        if relationship.isEmpty {
            withAnimation { showRelationshipError = true }
            return
        }

        isSaving = true
        error = nil

        Task {
            do {
                let request = CreatePersonRequest(
                    name: name,
                    relationship: relationship,
                    email: email.isEmpty ? nil : email,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
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
    AddPersonSheet(onSave: { _ in })
        .preferredColorScheme(.dark)
}
