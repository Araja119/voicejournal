import SwiftUI

struct AppBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base image with slight opacity reduction
                Image("Background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(0.92)

                // Vertical gradient overlay to sharpen focus
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), location: 0),
                        .init(color: .clear, location: 0.3),
                        .init(color: .clear, location: 0.7),
                        .init(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.12), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack {
            Text("Top")
            Spacer()
            Text("Middle")
            Spacer()
            Text("Bottom")
        }
        .foregroundColor(.white)
        .padding()
    }
}
