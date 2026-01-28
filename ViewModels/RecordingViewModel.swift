import SwiftUI
import Combine
import AVFoundation

// MARK: - Recording View Model
@MainActor
class RecordingViewModel: ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentRecording: Recording?
    @Published var isPlaying = false

    private let recordingService = RecordingService.shared
    private var audioPlayer: AVPlayer?

    func loadRecordings(journalId: String? = nil, personId: String? = nil) async {
        isLoading = true
        error = nil

        do {
            let response = try await recordingService.listRecordings(
                journalId: journalId,
                personId: personId
            )
            recordings = response.recordings
        } catch {
            self.error = "Failed to load recordings"
        }

        isLoading = false
    }

    func playRecording(_ recording: Recording) {
        guard let url = URL(string: recording.audioUrl) else { return }

        // Stop current playback
        stopPlayback()

        // Start new playback
        audioPlayer = AVPlayer(url: url)
        audioPlayer?.play()
        currentRecording = recording
        isPlaying = true
    }

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }

    func stopPlayback() {
        audioPlayer?.pause()
        audioPlayer = nil
        currentRecording = nil
        isPlaying = false
    }

    func deleteRecording(_ recording: Recording) async -> Bool {
        do {
            try await recordingService.deleteRecording(id: recording.id)
            recordings.removeAll { $0.id == recording.id }
            return true
        } catch {
            self.error = "Failed to delete recording"
            return false
        }
    }
}
