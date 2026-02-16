import SwiftUI

private struct TutorialStep {
    let icon: String
    let iconColor: Color
    let headline: String
    let body: String
    let button: String
}

struct FirstTimeTutorialView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0

    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "mic.fill",
            iconColor: Color(hex: "FF7A2F"),
            headline: "Preserve the voices\nthat matter",
            body: "VoiceJournal helps you collect voice-recorded stories from the people you love.",
            button: "Let's go"
        ),
        TutorialStep(
            icon: "person.2.fill",
            iconColor: Color(hex: "5B6B9A"),
            headline: "Add your people",
            body: "Start by adding family members or friends whose stories you want to keep forever.",
            button: "Next"
        ),
        TutorialStep(
            icon: "paperplane.fill",
            iconColor: Color(hex: "FF7A2F"),
            headline: "Ask a meaningful\nquestion",
            body: "Send them a question \u{2014} they'll get a link to record their voice answer from any device.",
            button: "Next"
        ),
        TutorialStep(
            icon: "waveform.circle.fill",
            iconColor: Color(hex: "8B5CF6"),
            headline: "Their voice,\npreserved forever",
            body: "Recordings are saved in your journal. Listen back anytime.",
            button: "Get started"
        ),
    ]

    var body: some View {
        let colors = AppColors(colorScheme)
        let textColors = GlassTextColors(colorScheme: colorScheme)

        ZStack {
            AppBackground()

            // Dimmed overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: finish) {
                        Text("Skip")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                }
                .padding(.top, Theme.Spacing.md)
                .padding(.trailing, Theme.Spacing.sm)

                Spacer()

                // Card content
                VStack(spacing: Theme.Spacing.xl) {
                    // Icon
                    GlassIconCircle(
                        icon: steps[currentStep].icon,
                        iconColor: steps[currentStep].iconColor,
                        size: 72
                    )

                    // Headline
                    Text(steps[currentStep].headline)
                        .font(AppTypography.displayMedium)
                        .foregroundColor(textColors.primary)
                        .multilineTextAlignment(.center)

                    // Body
                    Text(steps[currentStep].body)
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(textColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)

                    // Next button
                    Button(action: nextStep) {
                        Text(steps[currentStep].button)
                            .font(AppTypography.buttonPrimary)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(colors.accentPrimary)
                            .cornerRadius(Theme.Radius.md)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)

                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep
                                    ? colors.accentPrimary
                                    : colors.textSecondary.opacity(0.3))
                                .frame(width: index == currentStep ? 10 : 7,
                                       height: index == currentStep ? 10 : 7)
                                .animation(.easeInOut(duration: 0.2), value: currentStep)
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
                .glassCard(cornerRadius: 22)
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        } else {
            finish()
        }
    }

    private func finish() {
        appState.completeTutorial()
        dismiss()
    }
}

#Preview {
    FirstTimeTutorialView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
