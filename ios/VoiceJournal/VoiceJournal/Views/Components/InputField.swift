import SwiftUI

struct InputField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    let colors: AppColors
    var error: String? = nil

    @State private var isShowingPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Label
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(colors.textSecondary)

            // Input
            HStack {
                if isSecure && !isShowingPassword {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                        .autocorrectionDisabled(keyboardType == .emailAddress)
                }

                if isSecure {
                    Button(action: { isShowingPassword.toggle() }) {
                        Image(systemName: isShowingPassword ? "eye.slash" : "eye")
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
            .font(AppTypography.bodyLarge)
            .foregroundColor(colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(colors.surface)
            .cornerRadius(Theme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1)
            )

            // Error
            if let error = error {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.Dark.background.ignoresSafeArea()

        VStack(spacing: 20) {
            InputField(
                title: "Email",
                text: .constant("test@example.com"),
                placeholder: "your@email.com",
                keyboardType: .emailAddress,
                colors: AppColors(.dark)
            )

            InputField(
                title: "Password",
                text: .constant(""),
                placeholder: "Enter password",
                isSecure: true,
                colors: AppColors(.dark),
                error: "Password must be at least 8 characters"
            )
        }
        .padding()
    }
}
