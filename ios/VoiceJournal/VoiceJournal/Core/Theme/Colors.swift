import SwiftUI

// MARK: - App Colors
extension Color {
    // MARK: - Dark Mode Colors
    struct Dark {
        /// Deep Charcoal - Primary background (#121417)
        static let background = Color(hex: "121417")

        /// Slate Gray - Cards, surfaces (#2A2D31)
        static let surface = Color(hex: "2A2D31")

        /// Soft White - Primary text (#EDEDED)
        static let textPrimary = Color(hex: "EDEDED")

        /// Muted Gray - Secondary text, metadata (#9A9A9A)
        static let textSecondary = Color(hex: "9A9A9A")

        /// Warm Orange - Voice/action accent (#FF7F3E)
        static let accentPrimary = Color(hex: "FF7F3E")

        /// Warm Gold - Completion/confirmation accent (#E5AE56)
        static let accentSecondary = Color(hex: "E5AE56")
    }

    // MARK: - Light Mode Colors
    struct Light {
        /// Soft White - Primary background (#FAFAFA)
        static let background = Color(hex: "FAFAFA")

        /// Light Gray - Cards, surfaces (#F3F4F6)
        static let surface = Color(hex: "F3F4F6")

        /// Deep Navy - Primary text (#1C2A4A)
        static let textPrimary = Color(hex: "1C2A4A")

        /// Cool Gray - Secondary text, metadata (#6B7280)
        static let textSecondary = Color(hex: "6B7280")

        /// Coral Orange - Primary accent (#FF735A)
        static let accentPrimary = Color(hex: "FF735A")

        /// Amber - Secondary accent (#C47F17)
        static let accentSecondary = Color(hex: "C47F17")
    }
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme-Aware Colors
struct AppColors {
    let colorScheme: ColorScheme

    init(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    var background: Color {
        colorScheme == .dark ? Color.Dark.background : Color.Light.background
    }

    var surface: Color {
        colorScheme == .dark ? Color.Dark.surface : Color.Light.surface
    }

    var textPrimary: Color {
        colorScheme == .dark ? Color.Dark.textPrimary : Color.Light.textPrimary
    }

    var textSecondary: Color {
        colorScheme == .dark ? Color.Dark.textSecondary : Color.Light.textSecondary
    }

    var accentPrimary: Color {
        colorScheme == .dark ? Color.Dark.accentPrimary : Color.Light.accentPrimary
    }

    var accentSecondary: Color {
        colorScheme == .dark ? Color.Dark.accentSecondary : Color.Light.accentSecondary
    }
}

// MARK: - Environment Key
private struct AppColorsKey: EnvironmentKey {
    static let defaultValue = AppColors(.dark)
}

extension EnvironmentValues {
    var appColors: AppColors {
        get { self[AppColorsKey.self] }
        set { self[AppColorsKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func appColors(_ colorScheme: ColorScheme) -> some View {
        self.environment(\.appColors, AppColors(colorScheme))
    }
}
