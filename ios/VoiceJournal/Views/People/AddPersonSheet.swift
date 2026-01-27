import SwiftUI

struct AddPersonSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var relationship = "parent"
    @State private var email = ""
    @State private var phoneNumber = ""
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
                    email: email.isEmpty ? nil : email,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                )
                let person = try await PeopleService.shared.createPerson(request)
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
