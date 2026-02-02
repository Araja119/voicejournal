import SwiftUI
import AVFoundation

extension Notification.Name {
    static let playbackDidFinish = Notification.Name("playbackDidFinish")
}

struct RecordingModal: View {
    let questionText: String
    var onComplete: (Data, Int) -> Void
    var onCancel: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var recorder = AudioRecorder()
    @State private var recordingState: RecordingState = .idle
    @State private var showingPermissionAlert = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackDelegate: PlaybackDelegate?
    @State private var playbackTime: TimeInterval = 0
    @State private var playbackTimer: Timer?

    enum RecordingState {
        case idle
        case recording
        case review
        case uploading
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            // Gradient background fallback
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.75, blue: 0.55),  // Warm peach/orange
                    Color(red: 0.75, green: 0.55, blue: 0.70),  // Purple/pink
                    Color(red: 0.35, green: 0.25, blue: 0.45)   // Deep purple
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Background image overlay (if available)
            Image("Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // Dark overlay for dimming
            Color.black.opacity(0.40)
                .ignoresSafeArea()

            // Content layer
            VStack(spacing: 0) {
                // Top bar
                topBar(colors: colors)
                    .padding(.top, 16)

                Spacer()

                // Main content
                mainContent(colors: colors)

                Spacer()

                // Bottom controls
                bottomControls(colors: colors)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        } message: {
            Text("Please enable microphone access in Settings to record audio.")
        }
        .task {
            let hasPermission = await recorder.requestPermission()
            if !hasPermission {
                showingPermissionAlert = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playbackDidFinish)) { _ in
            playbackTimer?.invalidate()
            playbackTimer = nil
            isPlaying = false
            playbackTime = 0
        }
    }

    // MARK: - Top Bar
    @ViewBuilder
    private func topBar(colors: AppColors) -> some View {
        HStack {
            // Close button
            Button(action: handleCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Spacer()

            // Recording time indicator
            if recordingState == .recording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)

                    Text(recorder.formattedTime)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private func mainContent(colors: AppColors) -> some View {
        VStack(spacing: 24) {
            // Question being answered
            VStack(spacing: 8) {
                Text("Answering:")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))

                Text(questionText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 12)

            // State-specific content
            switch recordingState {
            case .idle:
                idleContent(colors: colors)

            case .recording:
                recordingContent(colors: colors)

            case .review:
                reviewContent(colors: colors)

            case .uploading:
                uploadingContent(colors: colors)
            }
        }
    }

    // MARK: - Idle Content
    @ViewBuilder
    private func idleContent(colors: AppColors) -> some View {
        VStack(spacing: 20) {
            // Static waveform bars
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let heights: [CGFloat] = [0.3, 0.5, 0.7, 1.0, 0.7, 0.5, 0.3]
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 80 * heights[index] * 0.3)
                }
            }
            .frame(height: 80)

            Text("Tap the button below to start")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Recording Content
    @ViewBuilder
    private func recordingContent(colors: AppColors) -> some View {
        VStack(spacing: 24) {
            // Audio level waveform
            RecordingWaveform(level: recorder.audioLevel, accentColor: colors.accentRecord)
                .frame(height: 100)

            // Recording in progress text
            Text("Recording in progress")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(colors.accentRecord)

            // Time remaining
            Text(recorder.formattedRemainingTime + " remaining")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))

            // Progress bar
            ProgressBar(progress: recorder.progress, color: colors.accentRecord)
                .frame(height: 4)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Review Content
    @ViewBuilder
    private func reviewContent(colors: AppColors) -> some View {
        VStack(spacing: 20) {
            // Playback waveform visualization
            if isPlaying {
                PlaybackWaveform(accentColor: colors.accentRecord)
                    .frame(height: 80)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(colors.accentSecondary)
            }

            Text(isPlaying ? "Playing back..." : "Recording complete!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            // Time display with skip controls (shown during playback)
            if isPlaying {
                HStack(spacing: 32) {
                    // Skip backward 10s
                    Button(action: skipBackward) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Current time / duration
                    Text(formatPlaybackTime(playbackTime) + " / " + recorder.formattedTime)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))

                    // Skip forward 10s
                    Button(action: skipForward) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            } else {
                Text(recorder.formattedTime)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Uploading Content
    @ViewBuilder
    private func uploadingContent(colors: AppColors) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Saving recording...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Bottom Controls
    @ViewBuilder
    private func bottomControls(colors: AppColors) -> some View {
        switch recordingState {
        case .idle:
            // Start recording button
            Button(action: startRecording) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(colors.accentRecord)
                            .frame(width: 80, height: 80)
                            .shadow(color: colors.accentRecord.opacity(0.5), radius: 16, x: 0, y: 8)

                        Image(systemName: "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }

                    Text("Start Recording")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }

        case .recording:
            // Stop button
            Button(action: stopRecording) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.red.opacity(0.5), radius: 16, x: 0, y: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                    }

                    Text("Stop Recording")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }

        case .review:
            // Review controls - Re-record and Replay side by side, Save below
            VStack(spacing: 24) {
                // Top row: Re-record and Replay
                HStack(spacing: 48) {
                    // Re-record button
                    Button(action: reRecord) {
                        VStack(spacing: 8) {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white.opacity(0.8))
                                )

                            Text("Re-record")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    // Replay button
                    Button(action: togglePlayback) {
                        VStack(spacing: 8) {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white.opacity(0.8))
                                )

                            Text(isPlaying ? "Pause" : "Replay")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                // Save button centered below
                Button(action: submit) {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(colors.accentRecord)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: colors.accentRecord.opacity(0.5), radius: 16, x: 0, y: 8)

                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.accentRecord)
                    }
                }
            }

        case .uploading:
            EmptyView()
        }
    }

    // MARK: - Actions
    private func handleCancel() {
        stopPlayback()
        if recorder.isRecording {
            recorder.cancelRecording()
        }
        onCancel()
    }

    private func startRecording() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        recorder.startRecording()
        recordingState = .recording
    }

    private func stopRecording() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        _ = recorder.stopRecording()
        recordingState = .review
    }

    private func reRecord() {
        stopPlayback()
        recorder.cancelRecording()
        recordingState = .idle
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard let data = recorder.getRecordingData() else { return }

        do {
            audioPlayer = try AVAudioPlayer(data: data)
            let delegate = PlaybackDelegate {
                DispatchQueue.main.async {
                    // Note: This closure captures nothing - the state binding
                    // is managed through NotificationCenter instead
                    NotificationCenter.default.post(name: .playbackDidFinish, object: nil)
                }
            }
            playbackDelegate = delegate
            audioPlayer?.delegate = delegate
            audioPlayer?.play()
            isPlaying = true

            // Start timer to track playback time
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = audioPlayer {
                    playbackTime = player.currentTime
                }
            }
        } catch {
            print("Playback error: \(error)")
        }
    }

    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        playbackDelegate = nil
        isPlaying = false
        playbackTime = 0
    }

    private func skipBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(0, player.currentTime - 10)
        player.currentTime = newTime
        playbackTime = newTime
    }

    private func skipForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(player.duration, player.currentTime + 10)
        player.currentTime = newTime
        playbackTime = newTime
    }

    private func formatPlaybackTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func submit() {
        stopPlayback()
        guard let data = recorder.getRecordingData() else { return }

        recordingState = .uploading

        let duration = recorder.getDurationSeconds()
        onComplete(data, duration)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(progress)))
            }
        }
    }
}

// MARK: - Recording Waveform (Sleeker with more bars)
struct RecordingWaveform: View {
    let level: Float
    let accentColor: Color

    @State private var animationPhase: Double = 0

    private let barCount = 11

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RecordingBar(
                    height: barHeight(for: index),
                    color: barColor(for: index)
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let center = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - center) / center

        // Base curve - taller in center
        let base = 1.0 - (distance * 0.6)

        // Multiple wave frequencies for organic feel
        let wave1 = sin(Double(index) * 0.8 + animationPhase) * 0.2
        let wave2 = sin(Double(index) * 1.3 + animationPhase * 1.5) * 0.1

        // Audio level responsiveness
        let levelMultiplier = CGFloat(0.3 + (level * 0.7))
        let waveIntensity = CGFloat(level) * CGFloat(wave1 + wave2)

        return max(0.12, CGFloat(base) * levelMultiplier + waveIntensity)
    }

    private func barColor(for index: Int) -> Color {
        let center = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - center) / center
        let opacity = 1.0 - (distance * 0.3)
        return accentColor.opacity(opacity)
    }
}

struct RecordingBar: View {
    let height: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 6, height: 100 * height)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: height)
    }
}

// MARK: - Playback Waveform (Animated during playback)
struct PlaybackWaveform: View {
    let accentColor: Color

    @State private var animationPhase: Double = 0

    private let barCount = 11

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(accentColor.opacity(barOpacity(for: index)))
                    .frame(width: 6, height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.2), value: animationPhase)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let center = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - center) / center
        let base = 1.0 - (distance * 0.5)

        let wave = sin(Double(index) * 0.7 + animationPhase)
        return CGFloat(40 + base * 40 + wave * 15)
    }

    private func barOpacity(for index: Int) -> Double {
        let center = Double(barCount - 1) / 2.0
        let distance = abs(Double(index) - center) / center
        return 1.0 - (distance * 0.3)
    }
}

// MARK: - Playback Delegate
class PlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onComplete()
    }
}

// MARK: - Preview
#Preview {
    RecordingModal(
        questionText: "What was one of the most fun moments you had in your childhood?",
        onComplete: { _, _ in },
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
