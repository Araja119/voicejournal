import SwiftUI

struct HubActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let colors: AppColors
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(accentColor)
                    )

                // Text
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(colors.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(colors.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colors.textSecondary)
            }
            .padding(Theme.Spacing.lg)
            .background(colors.surface)
            .cornerRadius(Theme.Radius.lg)
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
                subtitle: "Ask someone meaningful",
                icon: "paperplane.fill",
                accentColor: Color.Dark.accentPrimary,
                colors: AppColors(.dark)
            ) {}

            HubActionCard(
                title: "New Journal",
                subtitle: "Start collecting stories",
                icon: "book.fill",
                accentColor: Color.Dark.accentSecondary,
                colors: AppColors(.dark)
            ) {}
        }
        .padding()
    }
}
