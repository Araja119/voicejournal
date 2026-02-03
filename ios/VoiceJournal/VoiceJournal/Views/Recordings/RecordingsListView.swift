import SwiftUI
import AVFoundation
import Combine

struct RecordingsListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = RecordingViewModel()
    @StateObject private var quickPlayer = QuickPlayManager()
    @State private var collapsedSections: Set<String> = []
    @State private var selectedRecording: Recording?

    var body: some View {
        let colors = AppColors(colorScheme)

        NavigationStack {
            ZStack {
                AppBackground()

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
                        LazyVStack(spacing: 0) {
                            ForEach(recordingsByPerson, id: \.personId) { section in
                                PersonRecordingSection(
                                    section: section,
                                    isCollapsed: collapsedSections.contains(section.personId),
                                    quickPlayer: quickPlayer,
                                    onToggleCollapse: { toggleCollapse(sectionId: section.personId) },
                                    onSelectRecording: { recording in
                                        quickPlayer.stop()
                                        selectedRecording = recording
                                    },
                                    colors: colors
                                )
                            }
                        }
                        .padding(.top, Theme.Spacing.sm)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                            .padding(10)
                            .background(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                            .clipShape(Circle())
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Recordings")
                        .font(AppTypography.headlineSmall)
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                }
            }
            .fullScreenCover(item: $selectedRecording) { recording in
                RecordingPlayerView(recording: recording)
            }
        }
        .task {
            await viewModel.loadRecordings()
        }
        .refreshable {
            await viewModel.loadRecordings()
        }
    }

    // MARK: - Grouped Data

    private var recordingsByPerson: [RecordingSection] {
        var grouped: [String: [Recording]] = [:]

        for recording in viewModel.recordings {
            let personId = recording.person?.id ?? "unknown"
            grouped[personId, default: []].append(recording)
        }

        // Create sections and sort by person name
        return grouped.compactMap { personId, recordings -> RecordingSection? in
            guard let firstRecording = recordings.first else { return nil }
            let person = firstRecording.person ?? RecordingPersonInfo(id: "unknown", name: "Unknown", profilePhotoUrl: nil)
            // Sort recordings by date (most recent first)
            let sortedRecordings = recordings.sorted { ($0.recordedAt ?? .distantPast) > ($1.recordedAt ?? .distantPast) }
            return RecordingSection(personId: personId, person: person, recordings: sortedRecordings)
        }.sorted { $0.person.name.lowercased() < $1.person.name.lowercased() }
    }

    private func toggleCollapse(sectionId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if collapsedSections.contains(sectionId) {
                collapsedSections.remove(sectionId)
            } else {
                collapsedSections.insert(sectionId)
            }
        }
    }
}

// MARK: - Recording Section Model
struct RecordingSection {
    let personId: String
    let person: RecordingPersonInfo
    let recordings: [Recording]

    var totalDuration: Int {
        recordings.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    var formattedTotalDuration: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Person Recording Section
struct PersonRecordingSection: View {
    @Environment(\.colorScheme) var colorScheme

    let section: RecordingSection
    let isCollapsed: Bool
    @ObservedObject var quickPlayer: QuickPlayManager
    let onToggleCollapse: () -> Void
    let onSelectRecording: (Recording) -> Void
    let colors: AppColors

    private var recordingCountText: String {
        let count = section.recordings.count
        return "\(count) recording\(count == 1 ? "" : "s")"
    }

    // Surface color - matches HubView and JournalsListView
    private var sectionSurface: Color {
        colorScheme == .dark
            ? Color(red: 0.094, green: 0.102, blue: 0.125).opacity(0.68)
            : Color.white.opacity(0.75)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: onToggleCollapse) {
                HStack(spacing: Theme.Spacing.md) {
                    // Avatar
                    AvatarView(
                        name: section.person.name,
                        imageURL: section.person.profilePhotoUrl,
                        size: 44,
                        colors: colors
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.person.name)
                            .font(AppTypography.headlineSmall)
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))

                        HStack(spacing: Theme.Spacing.xs) {
                            Text(recordingCountText)
                                .font(AppTypography.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))

                            Text("•")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.25))

                            Text(section.formattedTotalDuration)
                                .font(AppTypography.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        }
                    }

                    Spacer()

                    // Collapse indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
            .buttonStyle(PlainButtonStyle())

            // Recordings (collapsible)
            if !isCollapsed {
                VStack(spacing: Theme.Spacing.xs) {
                    ForEach(section.recordings) { recording in
                        CompactRecordingCard(
                            recording: recording,
                            quickPlayer: quickPlayer,
                            onTapCard: { onSelectRecording(recording) },
                            colors: colors
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(sectionSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.12), radius: 12, x: 0, y: 6)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
    }
}

// MARK: - Compact Recording Card
struct CompactRecordingCard: View {
    @Environment(\.colorScheme) var colorScheme

    let recording: Recording
    @ObservedObject var quickPlayer: QuickPlayManager
    let onTapCard: () -> Void
    let colors: AppColors

    private var isPlaying: Bool {
        quickPlayer.currentRecordingId == recording.id && quickPlayer.isPlaying
    }

    private var isThisRecording: Bool {
        quickPlayer.currentRecordingId == recording.id
    }

    // Inner card surface
    private var cardSurface: Color {
        colorScheme == .dark
            ? Color.white.opacity(isThisRecording ? 0.08 : 0.05)
            : Color.white.opacity(isThisRecording ? 0.9 : 0.6)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Play/Pause button - quick listen
            ZStack {
                // Progress ring when playing
                if isThisRecording {
                    Circle()
                        .stroke(colors.accentPrimary.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: quickPlayer.progress)
                        .stroke(colors.accentPrimary, lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }

                Circle()
                    .fill(colors.accentPrimary)
                    .frame(width: isThisRecording ? 26 : 32, height: isThisRecording ? 26 : 32)
                    .overlay(
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: isThisRecording ? 10 : 12))
                            .foregroundColor(.white)
                            .offset(x: isPlaying ? 0 : 1)
                    )
            }
            .frame(width: 40, height: 40)
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        if isPlaying {
                            quickPlayer.pause()
                        } else if isThisRecording {
                            quickPlayer.resume()
                        } else {
                            quickPlayer.play(recording: recording)
                        }
                    }
            )

            // Question and date
            VStack(alignment: .leading, spacing: 2) {
                if let question = recording.question {
                    Text(question.questionText)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.85))
                        .lineLimit(1)
                }

                if isThisRecording {
                    // Show current time when playing
                    Text(quickPlayer.formattedCurrentTime + " / " + recording.formattedDuration)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(colors.accentPrimary)
                } else if let recordedAt = recording.recordedAt {
                    Text(recordedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.45))
                }
            }

            Spacer()

            // Duration (hide when showing progress)
            if !isThisRecording {
                Text(recording.formattedDuration)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.25))
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(cardSurface)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTapCard()
        }
        .animation(.easeInOut(duration: 0.2), value: isThisRecording)
    }
}

// MARK: - Quick Play Manager
class QuickPlayManager: ObservableObject {
    @Published var currentRecordingId: String?
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0

    private var player: AVPlayer?
    private var timeObserver: Any?

    var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func play(recording: Recording) {
        // Stop any current playback
        stop()

        guard let url = URL(string: recording.audioUrl) else { return }

        currentRecordingId = recording.id
        player = AVPlayer(url: url)

        // Observe time updates
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds

            if let duration = self.player?.currentItem?.duration.seconds,
               !duration.isNaN && duration > 0 {
                self.progress = time.seconds / duration
            }

            // Check if finished
            if let duration = self.player?.currentItem?.duration,
               time >= duration {
                self.stop()
            }
        }

        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
        currentRecordingId = nil
        isPlaying = false
        progress = 0
        currentTime = 0
    }

    deinit {
        stop()
    }
}

// MARK: - Preview
#Preview {
    RecordingsListView()
        .preferredColorScheme(.dark)
}
