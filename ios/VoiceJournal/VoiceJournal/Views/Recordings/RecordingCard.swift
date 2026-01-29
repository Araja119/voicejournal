import SwiftUI
import AVFoundation

// Note: This file is kept for reference but RecordingsListView.swift
// contains its own RecordingCard implementation that matches the Recording model.
// This standalone version provides a more feature-complete implementation.

struct RecordingCardFull: View {
    let recording: Recording
    let colors: AppColors

    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var player: AVPlayer?
    @State private var showingPlayer = false

    var body: some View {
        Button(action: { showingPlayer = true }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header
                HStack {
                    if let person = recording.person {
                        AvatarView(
                            name: person.name,
                            size: 40,
                            colors: colors
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name)
                                .font(AppTypography.labelMedium)
                                .foregroundColor(colors.textPrimary)

                            if let recordedAt = recording.recordedAt {
                                Text(recordedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTypography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    Text(recording.formattedDuration)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(colors.textSecondary)
                }

                // Question (if available)
                if let question = recording.question {
                    Text(question.questionText)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Inline playback controls
                HStack(spacing: Theme.Spacing.md) {
                    // Play/Pause button
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(colors.accentPrimary)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(colors.background)
                                .frame(height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(colors.accentPrimary)
                                .frame(width: geo.size.width * playbackProgress, height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.top, Theme.Spacing.xs)

                // Transcription preview
                if let transcription = recording.transcription, !transcription.isEmpty {
                    Text(transcription)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(3)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
            .padding(Theme.Spacing.md)
            .background(colors.surface)
            .cornerRadius(Theme.Radius.md)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPlayer) {
            RecordingPlayerView(recording: recording)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            playRecording()
        }
    }

    private func playRecording() {
        guard let url = URL(string: recording.audioUrl) else { return }

        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true

        // Update progress
        player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { time in
            if let duration = player?.currentItem?.duration.seconds,
               duration.isFinite && duration > 0 {
                playbackProgress = time.seconds / duration
            }

            // Check if finished
            if let duration = player?.currentItem?.duration,
               time >= duration {
                isPlaying = false
                playbackProgress = 0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        RecordingCardFull(
            recording: Recording(
                id: "1",
                question: RecordingQuestionInfo(id: "q1", questionText: "What's your favorite childhood memory?"),
                person: RecordingPersonInfo(id: "p1", name: "Mom"),
                journal: RecordingJournalInfo(id: "j1", title: "Family Stories"),
                audioUrl: "https://example.com/audio.m4a",
                durationSeconds: 125,
                transcription: "This is a sample transcription of the recording...",
                recordedAt: Date()
            ),
            colors: AppColors(.dark)
        )
    }
    .padding()
    .background(Color.Dark.background)
}
