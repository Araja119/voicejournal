import SwiftUI

// MARK: - Theme Configuration
struct Theme {
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows
    struct Shadow {
        static let sm = ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let md = ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let lg = ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }

    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)
    }

    // MARK: - Icon Sizes
    struct IconSize {
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
    }

    // MARK: - Button Sizes
    struct ButtonSize {
        static let small = CGSize(width: 32, height: 32)
        static let medium = CGSize(width: 44, height: 44)
        static let large = CGSize(width: 56, height: 56)
        static let xlarge = CGSize(width: 72, height: 72)
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Shadow Modifier
extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Card Style Modifier
extension View {
    func cardStyle(colorScheme: ColorScheme) -> some View {
        let colors = AppColors(colorScheme)
        return self
            .background(colors.surface)
            .cornerRadius(Theme.Radius.lg)
    }
}

// MARK: - Primary Card Style
struct PrimaryCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let colors = AppColors(colorScheme)
        content
            .padding(Theme.Spacing.lg)
            .background(colors.surface)
            .cornerRadius(Theme.Radius.lg)
    }
}

extension View {
    func primaryCard() -> some View {
        modifier(PrimaryCardStyle())
    }
}
