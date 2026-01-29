import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var displayName: String = ""
    @State private var phoneNumber: String = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Profile Photo
                    VStack(spacing: Theme.Spacing.sm) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                AvatarView(
                                    name: displayName.isEmpty ? "U" : displayName,
                                    imageURL: appState.currentUser?.profilePhotoUrl,
                                    size: 100,
                                    colors: colors
                                )

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

                        Text("Tap to change photo")
                            .font(AppTypography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.lg)

                    // Form
                    VStack(spacing: Theme.Spacing.md) {
                        InputField(
                            title: "Display Name",
                            text: $displayName,
                            placeholder: "Your name",
                            textContentType: .name,
                            colors: colors
                        )

                        InputField(
                            title: "Phone Number",
                            text: $phoneNumber,
                            placeholder: "+1 (555) 123-4567",
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber,
                            colors: colors
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let error = error {
                        Text(error)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: save) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .foregroundColor(colors.accentPrimary)
                    }
                }
                .disabled(isSaving || displayName.isEmpty)
            }
        }
        .onAppear {
            displayName = appState.currentUser?.displayName ?? ""
            phoneNumber = appState.currentUser?.phoneNumber ?? ""
        }
    }

    private func save() {
        isSaving = true
        error = nil

        Task {
            do {
                let request = UpdateUserRequest(
                    displayName: displayName,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                )
                let updatedUser = try await AuthService.shared.updateUser(request)
                appState.currentUser = updatedUser
                dismiss()
            } catch {
                self.error = "Failed to save changes"
            }
            isSaving = false
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileEditView()
            .environmentObject(AppState())
            .preferredColorScheme(.dark)
    }
}
