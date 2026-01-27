import SwiftUI
import AVFoundation

struct RecordingPlayerView: View {
    let recording: Recording

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isLoading = true

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    // Person info
                    if let person = recording.person {
                        VStack(spacing: Theme.Spacing.md) {
                            AvatarView(
                                name: person.name,
                                size: 96,
                                colors: colors
                            )

                            Text(person.name)
                                .font(AppTypography.headlineMedium)
                                .foregroundColor(colors.textPrimary)
                        }
                    }

                    // Question
                    if let question = recording.question {
                        Text(question.questionText)
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                    }

                    Spacer()

                    // Waveform placeholder
                    StaticWaveformView(
                        progress: duration > 0 ? currentTime / duration : 0,
                        colors: colors
                    )
                    .frame(height: 60)
                    .padding(.horizontal, Theme.Spacing.xl)

                    // Time display
                    HStack {
                        Text(formatTime(currentTime))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)

                        Spacer()

                        Text(formatTime(duration))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    // Playback controls
                    HStack(spacing: Theme.Spacing.xl) {
                        // Rewind 15s
                        Button(action: rewind) {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 28))
                                .foregroundColor(colors.textSecondary)
                        }

                        // Play/Pause
                        Button(action: togglePlayback) {
                            if isLoading {
                                ProgressView()
                                    .frame(width: 72, height: 72)
                            } else {
                                Circle()
                                    .fill(colors.accentPrimary)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.white)
                                            .offset(x: isPlaying ? 0 : 2)
                                    )
                            }
                        }
                        .disabled(isLoading)

                        // Forward 15s
                        Button(action: forward) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 28))
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.lg)

                    // Transcription
                    if let transcription = recording.transcription, !transcription.isEmpty {
                        ScrollView {
                            Text(transcription)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(colors.textPrimary)
                                .padding(Theme.Spacing.md)
                        }
                        .frame(maxHeight: 150)
                        .background(colors.surface)
                        .cornerRadius(Theme.Radius.md)
                        .padding(.horizontal, Theme.Spacing.lg)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
        }
        .task {
            await loadAudio()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func loadAudio() async {
        guard let url = URL(string: recording.audioUrl) else {
            isLoading = false
            return
        }

        await MainActor.run {
            player = AVPlayer(url: url)

            // Observe duration
            player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                Task { @MainActor in
                    if let item = player?.currentItem {
                        duration = item.asset.duration.seconds
                    }
                    isLoading = false
                }
            }

            // Observe time
            player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                queue: .main
            ) { time in
                currentTime = time.seconds

                // Check if finished
                if let dur = player?.currentItem?.duration,
                   time >= dur {
                    isPlaying = false
                    currentTime = 0
                    player?.seek(to: .zero)
                }
            }
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    private func rewind() {
        let newTime = max(0, currentTime - 15)
        player?.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }

    private func forward() {
        let newTime = min(duration, currentTime + 15)
        player?.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
}

// MARK: - Preview
#Preview {
    RecordingPlayerView(
        recording: Recording(
            id: "1",
            question: RecordingQuestionInfo(id: "q1", questionText: "What's your favorite childhood memory?"),
            person: RecordingPersonInfo(id: "p1", name: "Mom"),
            journal: RecordingJournalInfo(id: "j1", title: "Family Stories"),
            audioUrl: "https://example.com/audio.m4a",
            durationSeconds: 125,
            transcription: "This is a sample transcription of the recording that goes on for a bit to show how it would look in the player view.",
            recordedAt: Date()
        )
    )
    .preferredColorScheme(.dark)
}
