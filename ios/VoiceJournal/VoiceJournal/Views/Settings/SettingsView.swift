import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingFinalDeleteAlert = false
    @State private var isDeletingAccount = false

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
                        Toggle(isOn: Binding(
                            get: { appState.isDarkMode },
                            set: { newValue in
                                if newValue != appState.isDarkMode {
                                    appState.toggleTheme()
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(colors.accentPrimary)
                                Text("Dark Mode")
                            }
                        }

                        // Background theme carousel
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Background")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.md) {
                                    ForEach(BackgroundTheme.allCases) { theme in
                                        ThemeThumbnail(
                                            theme: theme,
                                            isSelected: appState.backgroundTheme == theme,
                                            colors: colors
                                        ) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                appState.setBackgroundTheme(theme)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
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

                        Button(action: { showingDeleteAccountAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Delete Account")
                                    .foregroundColor(.red)
                            }
                        }
                        .disabled(isDeletingAccount)
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
            .alert("Delete Account?", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Account", role: .destructive) {
                    showingFinalDeleteAlert = true
                }
            } message: {
                Text("This will permanently delete your account and all data including journals, recordings, and people.")
            }
            .alert("Are you absolutely sure?", isPresented: $showingFinalDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    isDeletingAccount = true
                    Task {
                        do {
                            try await appState.deleteAccount()
                            dismiss()
                        } catch {
                            isDeletingAccount = false
                        }
                    }
                }
            } message: {
                Text("This cannot be undone. All your journals, questions, voice recordings, and people will be permanently deleted.")
            }
        }
    }
}

// MARK: - Theme Thumbnail
struct ThemeThumbnail: View {
    let theme: BackgroundTheme
    let isSelected: Bool
    let colors: AppColors
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Image(theme.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.accentPrimary, lineWidth: 3)
                            .frame(width: 90, height: 130)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(colors.accentPrimary)
                            .background(Circle().fill(.white).padding(2))
                    }
                }

                Text(theme.name(for: colorScheme))
                    .font(AppTypography.caption)
                    .foregroundColor(isSelected ? colors.accentPrimary : colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
