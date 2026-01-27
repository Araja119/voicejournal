import Foundation
import AVFoundation
import Combine

// MARK: - Audio Recorder
@MainActor
class AudioRecorder: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var recordingURL: URL?
    @Published var error: AudioRecorderError?

    // MARK: - Configuration
    let maxDuration: TimeInterval = 180 // 3 minutes

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var startTime: Date?

    // MARK: - Audio Settings
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    // MARK: - Permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func hasPermission() -> Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Recording Controls
    func startRecording() {
        guard !isRecording else { return }

        // Setup audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            self.error = .sessionSetupFailed(error)
            return
        }

        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioURL = documentsPath.appendingPathComponent(fileName)

        // Initialize recorder
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            recordingURL = audioURL
            isRecording = true
            isPaused = false
            startTime = Date()
            recordingTime = 0

            // Start timers
            startTimers()

        } catch {
            self.error = .recordingFailed(error)
        }
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        audioRecorder?.pause()
        isPaused = true
        stopTimers()
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }
        audioRecorder?.record()
        isPaused = false
        startTimers()
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        audioRecorder?.stop()
        stopTimers()

        isRecording = false
        isPaused = false

        // Deactivate session
        try? AVAudioSession.sharedInstance().setActive(false)

        return recordingURL
    }

    func cancelRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        stopTimers()

        // Delete the file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        isRecording = false
        isPaused = false
        recordingURL = nil
        recordingTime = 0

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Timer Management
    private func startTimers() {
        // Recording time timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.recordingTime = self.audioRecorder?.currentTime ?? 0

                // Auto-stop at max duration
                if self.recordingTime >= self.maxDuration {
                    _ = self.stopRecording()
                }
            }
        }

        // Audio level timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let level = recorder.averagePower(forChannel: 0)
                // Normalize from -160..0 to 0..1
                self.audioLevel = max(0, (level + 60) / 60)
            }
        }
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    // MARK: - Utility
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedRemainingTime: String {
        let remaining = max(0, maxDuration - recordingTime)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "-%d:%02d", minutes, seconds)
    }

    var progress: Double {
        recordingTime / maxDuration
    }

    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }

    func getDurationSeconds() -> Int {
        Int(recordingTime)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                self.error = .recordingFailed(nil)
            }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.error = .encodingFailed(error)
        }
    }
}

// MARK: - Audio Recorder Error
enum AudioRecorderError: Error, LocalizedError {
    case permissionDenied
    case sessionSetupFailed(Error?)
    case recordingFailed(Error?)
    case encodingFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access is required to record audio."
        case .sessionSetupFailed(let error):
            return "Failed to setup audio session: \(error?.localizedDescription ?? "Unknown error")"
        case .recordingFailed(let error):
            return "Recording failed: \(error?.localizedDescription ?? "Unknown error")"
        case .encodingFailed(let error):
            return "Audio encoding failed: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}
