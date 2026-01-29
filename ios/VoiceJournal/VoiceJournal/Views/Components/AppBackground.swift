import SwiftUI

struct AppBackground: View {
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Vignette Colors (never pure black)

    // Light mode: warm neutral tones
    private var lightVignetteColor: Color {
        Color(red: 0.45, green: 0.40, blue: 0.38) // Warm gray with slight peach
    }

    // Dark mode: warm charcoal / muted aubergine
    private var darkVignetteColor: Color {
        Color(red: 0.18, green: 0.14, blue: 0.16) // Warm charcoal, hint of purple
    }

    private var vignetteColor: Color {
        colorScheme == .dark ? darkVignetteColor : lightVignetteColor
    }

    // MARK: - Opacity Values

    // Light mode: subtle (6-10% top, 4-7% bottom)
    private var topOpacityLight: Double { 0.08 }
    private var bottomOpacityLight: Double { 0.05 }

    // Dark mode: slightly stronger (10-16% top, 8-12% bottom)
    private var topOpacityDark: Double { 0.13 }
    private var bottomOpacityDark: Double { 0.10 }

    private var topOpacity: Double {
        colorScheme == .dark ? topOpacityDark : topOpacityLight
    }

    private var bottomOpacity: Double {
        colorScheme == .dark ? bottomOpacityDark : bottomOpacityLight
    }

    // MARK: - Falloff Heights (as percentage of screen)

    // Light mode: 18-25% top, 15-22% bottom
    private var topFalloffLight: Double { 0.22 }
    private var bottomFalloffLight: Double { 0.18 }

    // Dark mode: 22-30% top, 20-28% bottom
    private var topFalloffDark: Double { 0.26 }
    private var bottomFalloffDark: Double { 0.24 }

    private var topFalloff: Double {
        colorScheme == .dark ? topFalloffDark : topFalloffLight
    }

    private var bottomFalloff: Double {
        colorScheme == .dark ? bottomFalloffDark : bottomFalloffLight
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base image
                Image("Background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Top atmospheric falloff (ease-out: strongest at top, fades quickly)
                VStack {
                    LinearGradient(
                        stops: [
                            .init(color: vignetteColor.opacity(topOpacity), location: 0),
                            .init(color: vignetteColor.opacity(topOpacity * 0.6), location: 0.3),
                            .init(color: vignetteColor.opacity(topOpacity * 0.2), location: 0.6),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * topFalloff)

                    Spacer()
                }

                // Bottom atmospheric falloff (very gradual, long fade)
                VStack {
                    Spacer()

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: vignetteColor.opacity(bottomOpacity * 0.15), location: 0.3),
                            .init(color: vignetteColor.opacity(bottomOpacity * 0.5), location: 0.6),
                            .init(color: vignetteColor.opacity(bottomOpacity), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * bottomFalloff)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Dark Mode") {
    ZStack {
        AppBackground()
        VStack {
            Text("Welcome back,")
                .font(.body)
            Text("Abdullah")
                .font(.largeTitle)
            Spacer()
            Text("Middle content")
            Spacer()
            Text("Bottom content")
        }
        .foregroundColor(.white)
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    ZStack {
        AppBackground()
        VStack {
            Text("Welcome back,")
                .font(.body)
            Text("Abdullah")
                .font(.largeTitle)
            Spacer()
            Text("Middle content")
            Spacer()
            Text("Bottom content")
        }
        .foregroundColor(.black)
        .padding()
    }
    .preferredColorScheme(.light)
}
