import SwiftUI

// MARK: - Typography
struct AppTypography {
    // MARK: - Display
    /// Large display text - 34pt, light weight
    static let displayLarge = Font.system(size: 34, weight: .light, design: .default)

    /// Medium display text - 28pt, light weight
    static let displayMedium = Font.system(size: 28, weight: .light, design: .default)

    // MARK: - Headlines
    /// Large headline - 24pt, semibold
    static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .default)

    /// Medium headline - 20pt, semibold
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)

    /// Small headline - 17pt, semibold
    static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .default)

    // MARK: - Body
    /// Large body text - 17pt, regular
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// Medium body text - 15pt, regular
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    /// Small body text - 13pt, regular
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Labels
    /// Large label - 15pt, medium
    static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)

    /// Medium label - 13pt, medium
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)

    /// Small label - 11pt, medium
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Button
    /// Primary button text - 17pt, semibold
    static let buttonPrimary = Font.system(size: 17, weight: .semibold, design: .default)

    /// Secondary button text - 15pt, medium
    static let buttonSecondary = Font.system(size: 15, weight: .medium, design: .default)

    // MARK: - Caption
    /// Caption text - 12pt, regular
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption bold - 12pt, medium
    static let captionBold = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Text Style Modifiers
extension View {
    func textStyle(_ font: Font, color: Color) -> some View {
        self.font(font).foregroundColor(color)
    }
}

// MARK: - Predefined Text Styles
extension Text {
    func displayLarge(_ color: Color = .primary) -> some View {
        self.font(AppTypography.displayLarge).foregroundColor(color)
    }

    func headlineLarge(_ color: Color = .primary) -> some View {
        self.font(AppTypography.headlineLarge).foregroundColor(color)
    }

    func headlineMedium(_ color: Color = .primary) -> some View {
        self.font(AppTypography.headlineMedium).foregroundColor(color)
    }

    func bodyLarge(_ color: Color = .primary) -> some View {
        self.font(AppTypography.bodyLarge).foregroundColor(color)
    }

    func bodyMedium(_ color: Color = .primary) -> some View {
        self.font(AppTypography.bodyMedium).foregroundColor(color)
    }

    func labelMedium(_ color: Color = .secondary) -> some View {
        self.font(AppTypography.labelMedium).foregroundColor(color)
    }

    func caption(_ color: Color = .secondary) -> some View {
        self.font(AppTypography.caption).foregroundColor(color)
    }
}
