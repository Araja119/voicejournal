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
    @State private var isScrubbing = false
    @State private var wasPlayingBeforeScrub = false
    @State private var timeObserver: Any?
    @State private var statusObserver: NSKeyValueObservation?

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
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

                    // Question
                    if let question = recording.question {
                        Text("\"\(question.questionText)\"")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.top, Theme.Spacing.md)
                    }

                    Spacer()

                    // Waveform visualization with scrubbing
                    StaticWaveformView(
                        progress: duration > 0 ? currentTime / duration : 0,
                        colors: colors,
                        onScrub: { progress in
                            if !isScrubbing {
                                isScrubbing = true
                                wasPlayingBeforeScrub = isPlaying
                                player?.pause()
                                isPlaying = false
                            }
                            let targetTime = progress * duration
                            currentTime = targetTime
                            player?.seek(
                                to: CMTime(seconds: targetTime, preferredTimescale: 600),
                                toleranceBefore: .zero,
                                toleranceAfter: .zero
                            )
                        },
                        onScrubEnd: {
                            isScrubbing = false
                            if wasPlayingBeforeScrub {
                                player?.play()
                                isPlaying = true
                            }
                        }
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
                        // Rewind 5s
                        Button(action: rewind) {
                            Image(systemName: "gobackward.5")
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

                        // Forward 5s
                        Button(action: forward) {
                            Image(systemName: "goforward.5")
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
            cleanup()
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func loadAudio() async {
        guard let url = URL(string: recording.audioUrl) else {
            isLoading = false
            return
        }

        let playerItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: playerItem)
        self.player = avPlayer

        // Use API duration first (measured at recording time, always accurate).
        // Asset metadata can be wrong for browser-recorded audio streamed from R2.
        if let apiDuration = recording.durationSeconds, apiDuration > 0 {
            duration = Double(apiDuration)
        }

        // Observe player item status for readiness
        statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            Task { @MainActor in
                if item.status == .readyToPlay {
                    // Only use asset duration if we don't have an API duration
                    if recording.durationSeconds == nil || recording.durationSeconds == 0 {
                        let assetDuration = item.duration.seconds
                        if !assetDuration.isNaN && !assetDuration.isInfinite && assetDuration > 0 {
                            duration = assetDuration
                        }
                    }
                    isLoading = false
                } else if item.status == .failed {
                    isLoading = false
                }
            }
        }

        // Observe end of playback — correct duration if asset metadata was wrong
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                // If playback ended well before displayed duration, the metadata was wrong
                if currentTime > 0 && currentTime < duration * 0.9 {
                    duration = currentTime
                }
                isPlaying = false
                currentTime = 0
                player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }

        // Periodic time observer
        let observer = avPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { time in
            if !isScrubbing {
                currentTime = time.seconds
            }
        }
        timeObserver = observer
    }

    private func cleanup() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
        player = nil
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
        let newTime = max(0, currentTime - 5)
        currentTime = newTime
        player?.seek(
            to: CMTime(seconds: newTime, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    private func forward() {
        let newTime = min(duration, currentTime + 5)
        currentTime = newTime
        player?.seek(
            to: CMTime(seconds: newTime, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
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
