import SwiftUI

struct AppleSignInButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: colorScheme == .dark ? .black : .white
                        ))
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .medium))
                    Text("Sign in with Apple")
                        .font(AppTypography.buttonPrimary)
                }
            }
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(colorScheme == .dark ? Color.white : Color.black)
            .cornerRadius(Theme.Radius.md)
        }
        .disabled(isLoading)
    }
}
