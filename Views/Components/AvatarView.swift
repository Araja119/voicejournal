import SwiftUI

struct AvatarView: View {
    let name: String
    var imageURL: String? = nil
    let size: CGFloat
    let colors: AppColors

    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    private var backgroundColor: Color {
        // Generate consistent color based on name
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let colors: [Color] = [
            Color(hex: "FF7F3E"), // Orange
            Color(hex: "E5AE56"), // Gold
            Color(hex: "6366F1"), // Indigo
            Color(hex: "EC4899"), // Pink
            Color(hex: "14B8A6"), // Teal
            Color(hex: "8B5CF6"), // Purple
        ]
        return colors[hash % colors.count]
    }

    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        initialsView
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        initialsView
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
    }

    @ViewBuilder
    private var initialsView: some View {
        Circle()
            .fill(backgroundColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AvatarView(
            name: "John Doe",
            size: 64,
            colors: AppColors(.dark)
        )

        AvatarView(
            name: "Jane Smith",
            size: 48,
            colors: AppColors(.dark)
        )

        AvatarView(
            name: "Bob",
            size: 40,
            colors: AppColors(.dark)
        )
    }
    .padding()
    .background(Color.Dark.background)
}
