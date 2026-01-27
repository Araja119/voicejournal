import SwiftUI

struct WaveformView: View {
    let level: Float
    let isRecording: Bool
    let colors: AppColors

    @State private var animationPhase: Double = 0

    private let barCount = 40
    private let barSpacing: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        height: barHeight(for: index, in: geometry.size.height),
                        color: barColor(for: index),
                        isAnimating: isRecording
                    )
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startAnimation()
            }
        }
    }

    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        if !isRecording {
            // Idle state - small static bars
            return maxHeight * 0.1
        }

        // Create wave pattern based on audio level and animation
        let normalizedIndex = Double(index) / Double(barCount)
        let wave = sin((normalizedIndex * 4 * .pi) + animationPhase)

        // Combine wave with audio level
        let baseHeight = 0.1 + (Double(level) * 0.6)
        let waveHeight = baseHeight + (wave * 0.15 * Double(level))

        return maxHeight * CGFloat(max(0.05, min(0.95, waveHeight)))
    }

    private func barColor(for index: Int) -> Color {
        if !isRecording {
            return colors.textSecondary.opacity(0.3)
        }

        // Gradient effect from center
        let center = barCount / 2
        let distance = abs(index - center)
        let normalizedDistance = Double(distance) / Double(center)

        return colors.accentPrimary.opacity(1.0 - (normalizedDistance * 0.5))
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

// MARK: - Waveform Bar
struct WaveformBar: View {
    let height: CGFloat
    let color: Color
    let isAnimating: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(height: height)
            .animation(isAnimating ? .easeInOut(duration: 0.1) : .none, value: height)
    }
}

// MARK: - Static Waveform (for playback)
struct StaticWaveformView: View {
    let progress: Double
    let colors: AppColors

    private let barCount = 60

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let height = randomHeight(for: index, maxHeight: geometry.size.height)
                    let isFilled = Double(index) / Double(barCount) <= progress

                    RoundedRectangle(cornerRadius: 1)
                        .fill(isFilled ? colors.accentPrimary : colors.textSecondary.opacity(0.3))
                        .frame(height: height)
                }
            }
        }
    }

    private func randomHeight(for index: Int, maxHeight: CGFloat) -> CGFloat {
        // Seeded pseudo-random based on index for consistent appearance
        let seed = Double(index * 7 + 13)
        let random = (sin(seed) + 1) / 2 // 0-1 range
        return maxHeight * CGFloat(0.2 + (random * 0.6))
    }
}

// MARK: - Preview
#Preview("Recording Waveform") {
    VStack(spacing: 40) {
        // Idle state
        WaveformView(level: 0, isRecording: false, colors: AppColors(.dark))
            .frame(height: 60)

        // Recording state
        WaveformView(level: 0.6, isRecording: true, colors: AppColors(.dark))
            .frame(height: 60)

        // Static playback
        StaticWaveformView(progress: 0.4, colors: AppColors(.dark))
            .frame(height: 40)
    }
    .padding()
    .background(Color.Dark.background)
}
