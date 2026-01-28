import SwiftUI

struct RecordingsListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = RecordingViewModel()

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.recordings.isEmpty {
                    EmptyStateView(
                        icon: "waveform",
                        title: "No Recordings Yet",
                        message: "When people respond to your questions, their recordings will appear here",
                        colors: colors
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(viewModel.recordings) { recording in
                                RecordingCard(recording: recording, colors: colors)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Recordings")
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
            await viewModel.loadRecordings()
        }
    }
}

// MARK: - Recording Card
struct RecordingCard: View {
    let recording: Recording
    let colors: AppColors
    @State private var isPlaying = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                if let person = recording.person {
                    AvatarView(name: person.name, size: 40, colors: colors)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.name)
                            .font(AppTypography.labelLarge)
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

            // Question
            if let question = recording.question {
                Text(question.questionText)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(2)
            }

            // Playback Controls
            HStack(spacing: Theme.Spacing.md) {
                Button(action: { isPlaying.toggle() }) {
                    Circle()
                        .fill(colors.accentPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(.white)
                        )
                }

                // Progress bar placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(colors.surface)
                    .frame(height: 4)
                    .overlay(
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors.accentPrimary)
                                .frame(width: geo.size.width * 0.3)
                        },
                        alignment: .leading
                    )
            }
        }
        .padding(Theme.Spacing.md)
        .background(colors.surface)
        .cornerRadius(Theme.Radius.md)
    }
}

// MARK: - Preview
#Preview {
    RecordingsListView()
        .preferredColorScheme(.dark)
}
