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
                // Use app background for consistent aesthetic
                AppBackground()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    // Person info
                    if let person = recording.person {
                        VStack(spacing: Theme.Spacing.md) {
                            AvatarView(
                                name: person.name,
                                imageURL: person.profilePhotoUrl,
                                size: 120,
                                colors: colors
                            )

                            Text(person.name)
                                .font(AppTypography.headlineLarge)
                                .foregroundColor(.white)
                        }
                    }

                    // Question - prominent white bold text
                    if let question = recording.question {
                        Text("\"\(question.questionText)\"")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.top, Theme.Spacing.md)
                    }

                    Spacer()

                    // Waveform visualization
                    StaticWaveformView(
                        progress: duration > 0 ? currentTime / duration : 0,
                        colors: colors
                    )
                    .frame(height: 70)
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Time display
                    HStack {
                        Text(formatTime(currentTime))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Text(formatTime(duration))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    // Playback controls
                    HStack(spacing: Theme.Spacing.xxl) {
                        // Rewind 15s
                        Button(action: rewind) {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        // Play/Pause
                        Button(action: togglePlayback) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 80, height: 80)
                            } else {
                                Circle()
                                    .fill(colors.accentPrimary)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: colors.accentPrimary.opacity(0.4), radius: 12, x: 0, y: 4)
                                    .overlay(
                                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white)
                                            .offset(x: isPlaying ? 0 : 3)
                                    )
                            }
                        }
                        .disabled(isLoading)

                        // Forward 15s
                        Button(action: forward) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xl)

                    // Transcription
                    if let transcription = recording.transcription, !transcription.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Transcription")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(.white.opacity(0.6))

                            ScrollView {
                                Text(transcription)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Theme.Spacing.md)
                            }
                            .frame(maxHeight: 150)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(Theme.Radius.md)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Recording")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(.white)
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
        print("🔊 Loading audio from URL: \(recording.audioUrl)")

        guard let url = URL(string: recording.audioUrl) else {
            print("🔊 ERROR: Invalid URL!")
            isLoading = false
            return
        }

        print("🔊 Created URL object: \(url)")

        await MainActor.run {
            player = AVPlayer(url: url)
            print("🔊 Created AVPlayer")

            // Observe duration
            player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                Task { @MainActor in
                    if let item = player?.currentItem {
                        let assetDuration = item.asset.duration
                        duration = assetDuration.seconds
                        print("🔊 Asset duration: \(assetDuration.seconds) seconds, isValid: \(!assetDuration.seconds.isNaN)")
                    }
                    isLoading = false
                }
            }

            // Also observe player errors
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { notification in
                print("🔊 Player failed: \(notification)")
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
            person: RecordingPersonInfo(id: "p1", name: "Mom", profilePhotoUrl: nil),
            journal: RecordingJournalInfo(id: "j1", title: "Family Stories"),
            audioUrl: "https://example.com/audio.m4a",
            durationSeconds: 125,
            transcription: "This is a sample transcription of the recording that goes on for a bit to show how it would look in the player view.",
            recordedAt: Date()
        )
    )
    .preferredColorScheme(.dark)
}
