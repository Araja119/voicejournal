import SwiftUI

// MARK: - Hub View Mockup (Retention-Focused Design)
// This is a design mockup only - not connected to the actual app navigation.
// Preview this file in Xcode to see the proposed home screen design.

struct HubViewMockup: View {
    @Environment(\.colorScheme) var colorScheme

    // Mock data for preview
    let userName = "Abdullah"
    let peopleOwingStories = 2

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            AppBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar(colors: colors)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Welcome header with emotional hook
                        welcomeHeader(colors: colors)

                        // In Progress - THE CORE OF THE HOME SCREEN
                        inProgressPanel(colors: colors)

                        // Primary action - Send Question
                        sendQuestionCard(colors: colors)

                        // Secondary actions
                        myPeopleCard(colors: colors)
                        latestRecordingsCard(colors: colors)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(colors: AppColors) -> some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Welcome Header
    @ViewBuilder
    private func welcomeHeader(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Welcome back,")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white.opacity(0.8))

            Text(userName)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            // Emotional hook - this is key for retention
            Text("\(peopleOwingStories) people owe you stories today.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, Theme.Spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - In Progress Panel (THE MOST IMPORTANT ELEMENT)
    @ViewBuilder
    private func inProgressPanel(colors: AppColors) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.accentSecondary)

                Text("In Progress")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.md)

            // Story cards
            VStack(spacing: Theme.Spacing.sm) {
                // Waiting card - highest priority
                InProgressStoryCard(
                    type: .waiting,
                    personName: "Umar",
                    title: "Waiting on Umar",
                    subtitle: "9 questions awaiting responses",
                    timestamp: "Last reply from Abdullah — 1 hr. ago",
                    colors: colors
                )

                // Continue card - story ready to continue
                InProgressStoryCard(
                    type: .continue,
                    personName: "Dad",
                    title: "Continue Dad's Adventures",
                    subtitle: "Answered 4 days ago",
                    timestamp: nil,
                    colors: colors
                )
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.md)
        }
        .background(colors.surface.opacity(0.6))
        .cornerRadius(Theme.Radius.lg)
    }

    // MARK: - Send Question Card
    @ViewBuilder
    private func sendQuestionCard(colors: AppColors) -> some View {
        Button(action: {}) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(colors.accentPrimary.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colors.accentPrimary)
                        .rotationEffect(.degrees(-45))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Send Question")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Prompt a meaningful memory")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .background(colors.surface.opacity(0.6))
            .cornerRadius(Theme.Radius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - My People Card
    @ViewBuilder
    private func myPeopleCard(colors: AppColors) -> some View {
        Button(action: {}) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(colors.textSecondary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("My People")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("The voices that matter")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .background(colors.surface.opacity(0.5))
            .cornerRadius(Theme.Radius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Latest Recordings Card
    @ViewBuilder
    private func latestRecordingsCard(colors: AppColors) -> some View {
        Button(action: {}) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(colors.textSecondary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Latest Recordings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Listen back")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(Theme.Spacing.md)
            .background(colors.surface.opacity(0.5))
            .cornerRadius(Theme.Radius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - In Progress Story Card
struct InProgressStoryCard: View {
    enum CardType {
        case waiting   // Waiting for response
        case `continue` // Story ready to continue
        case listen    // New recording to listen to
    }

    let type: CardType
    let personName: String
    let title: String
    let subtitle: String
    let timestamp: String?
    let colors: AppColors

    private var iconName: String {
        switch type {
        case .waiting: return "paperplane.fill"
        case .continue: return "book.fill"
        case .listen: return "play.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .waiting: return colors.accentPrimary
        case .continue: return colors.accentSecondary
        case .listen: return .green
        }
    }

    private var iconBackgroundColor: Color {
        switch type {
        case .waiting: return colors.accentPrimary.opacity(0.2)
        case .continue: return colors.accentSecondary.opacity(0.2)
        case .listen: return Color.green.opacity(0.2)
        }
    }

    var body: some View {
        Button(action: {}) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon/Avatar
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                        .rotationEffect(type == .waiting ? .degrees(-45) : .degrees(0))
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))

                    if let timestamp = timestamp {
                        Text(timestamp)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.top, 1)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(Theme.Spacing.sm)
            .background(colors.surface.opacity(0.4))
            .cornerRadius(Theme.Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Version with Quick Actions
struct InProgressStoryCardEnhanced: View {
    enum CardType {
        case waiting
        case answered
        case idle
    }

    let type: CardType
    let personName: String
    let personImageURL: String?
    let journalTitle: String
    let unansweredCount: Int?
    let lastActivityText: String
    let colors: AppColors

    private var actionButtonText: String {
        switch type {
        case .waiting: return "Send another"
        case .answered: return "Listen"
        case .idle: return "Continue"
        }
    }

    private var actionButtonIcon: String {
        switch type {
        case .waiting: return "paperplane.fill"
        case .answered: return "play.fill"
        case .idle: return "arrow.right"
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar
            AvatarView(
                name: personName,
                imageURL: personImageURL,
                size: 48,
                colors: colors
            )

            // Content
            VStack(alignment: .leading, spacing: 3) {
                // Status line - emotional hook
                Text("Waiting on \(personName)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                // Story context
                Text("Continue \"\(journalTitle)\"")
                    .font(.system(size: 14))
                    .foregroundColor(colors.accentSecondary)

                // Metadata line
                HStack(spacing: Theme.Spacing.xs) {
                    Text(lastActivityText)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    if let count = unansweredCount, count > 0 {
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        Text("\(count) unanswered")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            Spacer()

            // Quick action button
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: actionButtonIcon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(actionButtonText)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(colors.accentPrimary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(colors.accentPrimary.opacity(0.15))
                .cornerRadius(Theme.Radius.sm)
            }
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface.opacity(0.5))
        .cornerRadius(Theme.Radius.md)
    }
}

// MARK: - Alternative: Minimal In Progress (Maximum Impact)
struct InProgressMinimal: View {
    let colors: AppColors

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colors.accentSecondary)

                Text("In Progress")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("2 active")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Single most urgent item - full width, prominent
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    AvatarView(name: "Dad", size: 40, colors: colors)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Waiting on Dad")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Dad's Adventures • 3 unanswered")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()
                }

                // Timestamp + action in one row
                HStack {
                    Text("Last reply 2 days ago")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))

                    Spacer()

                    Button(action: {}) {
                        Text("Send question")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(colors.accentPrimary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(colors.surface.opacity(0.4))
            .cornerRadius(Theme.Radius.md)
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface.opacity(0.3))
        .cornerRadius(Theme.Radius.lg)
    }
}

// MARK: - Preview
#Preview("Mockup - Dark") {
    HubViewMockup()
        .preferredColorScheme(.dark)
}

#Preview("Mockup - Light") {
    HubViewMockup()
        .preferredColorScheme(.light)
}

#Preview("Enhanced Card") {
    ZStack {
        Color.black.ignoresSafeArea()

        InProgressStoryCardEnhanced(
            type: .waiting,
            personName: "Dad",
            personImageURL: nil,
            journalTitle: "Dad's Adventures",
            unansweredCount: 3,
            lastActivityText: "Last reply 2 days ago",
            colors: AppColors(.dark)
        )
        .padding()
    }
}

#Preview("Minimal Panel") {
    ZStack {
        AppBackground()

        InProgressMinimal(colors: AppColors(.dark))
            .padding()
    }
    .preferredColorScheme(.dark)
}
