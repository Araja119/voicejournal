import SwiftUI

enum CardProminence {
    case primary   // The ONE action - larger, more elevated
    case standard  // Normal action cards
}

struct HubActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let colors: AppColors
    var prominence: CardProminence = .standard
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    // Size adjustments based on prominence
    private var iconSize: CGFloat {
        prominence == .primary ? 64 : 52
    }

    private var iconFontSize: CGFloat {
        prominence == .primary ? 28 : 22
    }

    private var verticalPadding: CGFloat {
        prominence == .primary ? Theme.Spacing.xl : Theme.Spacing.lg
    }

    private var cardOpacity: Double {
        // Slightly more transparent in dark mode per feedback
        colorScheme == .dark ? 0.92 : 1.0
    }

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon - larger and more vibrant for primary
                Circle()
                    .fill(accentColor.opacity(prominence == .primary ? 0.2 : 0.12))
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: iconFontSize, weight: .semibold))
                            .foregroundColor(accentColor)
                    )

                // Text
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(prominence == .primary ? AppTypography.headlineMedium : AppTypography.headlineSmall)
                        .foregroundColor(colors.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(colors.textSecondary)
                }

                Spacer()

                // Arrow - more prominent for primary
                Image(systemName: "chevron.right")
                    .font(.system(size: prominence == .primary ? 16 : 14, weight: .semibold))
                    .foregroundColor(prominence == .primary ? accentColor.opacity(0.7) : colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, verticalPadding)
            .background(colors.surface.opacity(cardOpacity))
            .cornerRadius(Theme.Radius.lg)
            .shadow(
                color: prominence == .primary ? accentColor.opacity(0.15) : .black.opacity(0.05),
                radius: prominence == .primary ? 12 : 4,
                x: 0,
                y: prominence == .primary ? 4 : 2
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.Dark.background.ignoresSafeArea()

        VStack(spacing: 16) {
            HubActionCard(
                title: "Send Question",
                subtitle: "Prompt a meaningful memory",
                icon: "paperplane.fill",
                accentColor: Color.Dark.accentPrimary,
                colors: AppColors(.dark),
                prominence: .primary
            ) {}

            HubActionCard(
                title: "New Journal",
                subtitle: "Start a living story",
                icon: "book.fill",
                accentColor: Color.Dark.accentSecondary,
                colors: AppColors(.dark),
                prominence: .standard
            ) {}
        }
        .padding()
    }
}
