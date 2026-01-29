import SwiftUI

struct AppBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        AppBackground()
        Text("Hello World")
            .foregroundColor(.white)
    }
}
