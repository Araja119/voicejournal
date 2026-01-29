import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var showingLogin = false
    @State private var showingSignup = false
    @State private var showingExplore = false

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    // Logo and tagline
                    VStack(spacing: Theme.Spacing.md) {
                        Circle()
                            .fill(colors.accentPrimary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                            )

                        Text("VoiceJournal")
                            .font(AppTypography.displayMedium)
                            .foregroundColor(colors.textPrimary)

                        Text("Capture the voices that matter most")
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                    }

                    Spacer()

                    // Actions
                    VStack(spacing: Theme.Spacing.md) {
                        // Explore button (primary path)
                        Button(action: { showingExplore = true }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Explore Questions")
                            }
                            .font(AppTypography.buttonPrimary)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(colors.accentPrimary)
                            .cornerRadius(Theme.Radius.md)
                        }

                        // Sign up button
                        Button(action: { showingSignup = true }) {
                            Text("Create Account")
                                .font(AppTypography.buttonPrimary)
                                .foregroundColor(colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(Theme.Radius.md)
                        }

                        // Login link
                        Button(action: { showingLogin = true }) {
                            Text("Already have an account? Log in")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingSignup) {
                SignupView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingExplore) {
                ExploreTemplatesView(onSignupTap: {
                    showingExplore = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingSignup = true
                    }
                })
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
