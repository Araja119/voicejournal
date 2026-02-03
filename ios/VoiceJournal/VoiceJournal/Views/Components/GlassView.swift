import SwiftUI
import UIKit

// MARK: - Translucent Blur View (UIKit wrapper for precise blur control)
struct TranslucentBlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    var intensity: CGFloat = 0.7  // Default intensity

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = intensity  // Reduce to let more background through
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = intensity
    }
}

// MARK: - Glass Card Style
// True frosted glass that works in both light and dark mode
// Light mode: translucent white glass with background bleed
// Dark mode: translucent dark glass (existing style)

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(borderAndHighlight)
            .shadow(color: primaryShadow, radius: primaryShadowRadius, x: 0, y: primaryShadowY)
            .shadow(color: ambientShadow, radius: 2, x: 0, y: 1)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Glass Background
    @ViewBuilder
    private var glassBackground: some View {
        if colorScheme == .dark {
            ZStack {
                // Dark mode: material blur + tint
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tintColor)
            }
        } else {
            // Light mode: true frosted glass - background colors clearly visible through blur
            ZStack {
                // Layer 1: Light blur with low intensity for vivid background colors
                TranslucentBlurView(style: .light, intensity: 0.38)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                // Layer 2: Very subtle white diffusion
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.22))
            }
        }
    }

    // MARK: - Border and Inner Highlight
    @ViewBuilder
    private var borderAndHighlight: some View {
        ZStack {
            // Outer border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)

            // Inner highlight (top edge glow for glass depth)
            RoundedRectangle(cornerRadius: cornerRadius - 1, style: .continuous)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: innerHighlightColor, location: 0),
                            .init(color: .clear, location: 0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .padding(1)
        }
    }

    // MARK: - Dynamic Colors

    private var tintColor: Color {
        colorScheme == .dark
            ? Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.5)
            : Color.white.opacity(0.08)  // Very subtle tint to maximize background bleed
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.white.opacity(0.45)
    }

    private var innerHighlightColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.6)
    }

    private var primaryShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.35)
            : Color.black.opacity(0.10)
    }

    private var primaryShadowRadius: CGFloat {
        colorScheme == .dark ? 12 : 18
    }

    private var primaryShadowY: CGFloat {
        colorScheme == .dark ? 8 : 10
    }

    private var ambientShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.2)
            : Color.black.opacity(0.06)
    }
}

// MARK: - Glass Card Secondary (for inner/nested cards)
struct GlassCardSecondaryModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(border)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var glassBackground: some View {
        if colorScheme == .dark {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tintColor)
            }
        } else {
            // Light mode: subtle frosted glass for nested cards
            ZStack {
                TranslucentBlurView(style: .light, intensity: 0.32)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.18))
            }
        }
    }

    @ViewBuilder
    private var border: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderColor, lineWidth: 1)
    }

    private var tintColor: Color {
        colorScheme == .dark
            ? Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.25)
            : Color.white.opacity(0.05)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.03)
            : Color.white.opacity(0.5)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.15)
            : Color.black.opacity(0.06)
    }

    private var shadowRadius: CGFloat {
        colorScheme == .dark ? 4 : 6
    }

    private var shadowY: CGFloat {
        colorScheme == .dark ? 2 : 3
    }
}

// MARK: - Glass Icon Circle (for action card icons)
struct GlassIconCircle: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                // Dark mode: material blur + tint
                Circle()
                    .fill(.thinMaterial)
                Circle()
                    .fill(Color.white.opacity(0.08))
            } else {
                // Light mode: frosted glass icon circle
                ZStack {
                    TranslucentBlurView(style: .light, intensity: 0.4)
                        .clipShape(Circle())
                    Circle()
                        .fill(Color.white.opacity(0.22))
                }
            }

            // Icon
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(iconColor.opacity(colorScheme == .dark ? 1.0 : 0.95))
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassCardSecondary(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassCardSecondaryModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Text Colors
struct GlassTextColors {
    let colorScheme: ColorScheme

    var primary: Color {
        colorScheme == .dark
            ? .white
            : .black.opacity(0.82)
    }

    var secondary: Color {
        colorScheme == .dark
            ? .white.opacity(0.6)
            : .black.opacity(0.55)
    }

    var tertiary: Color {
        colorScheme == .dark
            ? .white.opacity(0.4)
            : .black.opacity(0.35)
    }

    var sectionLabel: Color {
        colorScheme == .dark
            ? .white.opacity(0.9)
            : .black.opacity(0.65)
    }
}

// MARK: - Icon Colors
struct GlassIconColors {
    static let sendQuestion = Color(red: 1.0, green: 0.478, blue: 0.184) // #FF7A2F
    static let slate = Color(red: 0.357, green: 0.420, blue: 0.604) // #5B6B9A
}

// MARK: - Preview
#Preview("Glass Cards - Light") {
    ZStack {
        AppBackground()

        ScrollView {
            VStack(spacing: 16) {
                // Primary card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Glass Card")
                        .foregroundColor(.black.opacity(0.82))
                    Text("Secondary text here")
                        .foregroundColor(.black.opacity(0.55))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Secondary card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secondary Glass Card")
                        .foregroundColor(.black.opacity(0.82))
                    Text("Nested card style")
                        .foregroundColor(.black.opacity(0.55))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCardSecondary()

                // Icon examples
                HStack(spacing: 20) {
                    GlassIconCircle(icon: "paperplane.fill", iconColor: GlassIconColors.sendQuestion)
                    GlassIconCircle(icon: "person.2.fill", iconColor: GlassIconColors.slate)
                    GlassIconCircle(icon: "waveform", iconColor: GlassIconColors.slate)
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Glass Cards - Dark") {
    ZStack {
        AppBackground()

        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Glass Card")
                        .foregroundColor(.white)
                    Text("Secondary text here")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Secondary Glass Card")
                        .foregroundColor(.white)
                    Text("Nested card style")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCardSecondary()

                HStack(spacing: 20) {
                    GlassIconCircle(icon: "paperplane.fill", iconColor: GlassIconColors.sendQuestion)
                    GlassIconCircle(icon: "person.2.fill", iconColor: .white.opacity(0.7))
                    GlassIconCircle(icon: "waveform", iconColor: .white.opacity(0.7))
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
