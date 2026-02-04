import SwiftUI
import UIKit

// MARK: - Translucent Blur View (UIKit wrapper for precise blur control)
struct TranslucentBlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    var intensity: CGFloat = 0.7

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.alpha = intensity
        return blurView
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = intensity
    }
}

// MARK: - Glass Card Style (Primary/Outer containers)
// Light mode: neutral blur + tiny white tint + shadow + subtle edge
// Dark mode: translucent dark glass

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(borderOverlay)
            .shadow(color: primaryShadow, radius: primaryShadowRadius, x: 0, y: primaryShadowY)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Glass Background
    @ViewBuilder
    private var glassBackground: some View {
        if colorScheme == .dark {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.5))
            }
        } else {
            // Light mode: neutral blur + TINY white tint (0.12, not 0.22)
            ZStack {
                TranslucentBlurView(style: .light, intensity: 0.45)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.12))  // Reduced from 0.22 - removes fog
            }
        }
    }

    // MARK: - Border (subtle, not drawn)
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderColor, lineWidth: 1)
    }

    private var borderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.white.opacity(0.18)  // Reduced from 0.45 - glass edges are subtle
    }

    private var primaryShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.35)
            : Color.black.opacity(0.12)  // Slightly stronger for depth
    }

    private var primaryShadowRadius: CGFloat {
        colorScheme == .dark ? 12 : 22  // Larger radius for parent cards
    }

    private var primaryShadowY: CGFloat {
        colorScheme == .dark ? 8 : 14  // More lift for parent cards
    }
}

// MARK: - Glass Card Secondary (Inner/nested cards - journal rows)
// Shallower depth than parent for visual hierarchy

struct GlassCardSecondaryModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
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
                    .fill(Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.25))
            }
        } else {
            // Light mode: even subtler for nested cards (0.08 tint)
            ZStack {
                TranslucentBlurView(style: .light, intensity: 0.35)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.08))  // Less than parent - creates depth
            }
        }
    }

    // No border on secondary cards - let shadow create separation

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.15)
            : Color.black.opacity(0.08)  // Subtle shadow for child depth
    }

    private var shadowRadius: CGFloat {
        colorScheme == .dark ? 4 : 10  // Less than parent
    }

    private var shadowY: CGFloat {
        colorScheme == .dark ? 2 : 6  // Less lift than parent
    }
}

// MARK: - Glass Icon Circle
struct GlassIconCircle: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Circle()
                    .fill(.thinMaterial)
                Circle()
                    .fill(Color.white.opacity(0.08))
            } else {
                // Light mode: subtle glass circle
                ZStack {
                    TranslucentBlurView(style: .light, intensity: 0.4)
                        .clipShape(Circle())
                    Circle()
                        .fill(Color.white.opacity(0.10))  // Reduced tint
                }
            }

            // Icon - full opacity for visibility
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(iconColor)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06), radius: 4, x: 0, y: 2)
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

// MARK: - Glass Text Colors (increased ink for light mode)
struct GlassTextColors {
    let colorScheme: ColorScheme

    var primary: Color {
        colorScheme == .dark
            ? .white
            : .black.opacity(0.88)  // Increased from 0.82 - crisp text
    }

    var secondary: Color {
        colorScheme == .dark
            ? .white.opacity(0.6)
            : .black.opacity(0.60)  // Increased from 0.55
    }

    var tertiary: Color {
        colorScheme == .dark
            ? .white.opacity(0.4)
            : .black.opacity(0.45)  // Increased from 0.35 - visible chevrons/icons
    }

    var sectionLabel: Color {
        colorScheme == .dark
            ? .white.opacity(0.9)
            : .black.opacity(0.70)  // Increased from 0.65
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
                // Primary card (parent)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary Glass Card")
                        .foregroundColor(.black.opacity(0.88))
                    Text("Secondary text here")
                        .foregroundColor(.black.opacity(0.60))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Secondary card (child)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secondary Glass Card")
                        .foregroundColor(.black.opacity(0.88))
                    Text("Nested card style - less depth")
                        .foregroundColor(.black.opacity(0.60))
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
