import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                List {
                    // Profile Section
                    Section {
                        NavigationLink {
                            ProfileEditView()
                                .environmentObject(appState)
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                AvatarView(
                                    name: appState.currentUser?.displayName ?? "User",
                                    imageURL: appState.currentUser?.profilePhotoUrl,
                                    size: 56,
                                    colors: colors
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appState.currentUser?.displayName ?? "User")
                                        .font(AppTypography.headlineSmall)
                                        .foregroundColor(colors.textPrimary)

                                    Text(appState.currentUser?.email ?? "")
                                        .font(AppTypography.bodySmall)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                        }
                    }
                    .listRowBackground(colors.surface)

                    // Appearance Section
                    Section("Appearance") {
                        Toggle(isOn: $appState.isDarkMode) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(colors.accentPrimary)
                                Text("Dark Mode")
                            }
                        }
                        .onChange(of: appState.isDarkMode) { _, _ in
                            appState.toggleTheme()
                        }
                    }
                    .listRowBackground(colors.surface)

                    // Account Section
                    Section("Account") {
                        Button(action: { showingLogoutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Log Out")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .listRowBackground(colors.surface)

                    // About Section
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .listRowBackground(colors.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    Task {
                        await appState.logout()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
