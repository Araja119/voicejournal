import SwiftUI

struct LaunchView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            AppBackground()

            VStack(spacing: Theme.Spacing.lg) {
                // App Icon / Logo
                Circle()
                    .fill(colors.accentPrimary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.5)

                Text("VoiceJournal")
                    .font(AppTypography.headlineLarge)
                    .foregroundColor(colors.textPrimary)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchView()
        .preferredColorScheme(.dark)
}
