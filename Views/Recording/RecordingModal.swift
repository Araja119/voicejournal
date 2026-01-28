import SwiftUI

struct RecordingModal: View {
    let questionText: String
    var onComplete: (Data, Int) -> Void
    var onCancel: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var recorder = AudioRecorder()
    @State private var recordingState: RecordingState = .idle
    @State private var showingPermissionAlert = false

    enum RecordingState {
        case idle
        case recording
        case review
        case uploading
    }

    var body: some View {
        let colors = AppColors(colorScheme)

        ZStack {
            // Dimmed background
            colors.background.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(colors.textSecondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, Theme.Spacing.md)

                // Question
                Text(questionText)
                    .font(AppTypography.headlineMedium)
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.xl)

                // Status
                Text(statusText)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(recordingState == .recording ? colors.accentPrimary : colors.textSecondary)
                    .padding(.top, Theme.Spacing.lg)

                // Waveform
                WaveformView(
                    level: recorder.audioLevel,
                    isRecording: recordingState == .recording,
                    colors: colors
                )
                .frame(height: 80)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.md)

                // Time indicators
                HStack {
                    Text(recorder.formattedTime)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(colors.textSecondary)

                    Spacer()

                    Text(recorder.formattedRemainingTime)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(colors.textSecondary)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)

                Spacer()

                // Controls
                controlsView(colors: colors)

                // Instructions
                Text(instructionText)
                    .font(AppTypography.caption)
                    .foregroundColor(colors.textSecondary)
                    .padding(.top, Theme.Spacing.md)

                // Progress bar
                GeometryReader { geo in
                    Rectangle()
                        .fill(colors.surface)
                        .frame(height: 4)
                        .overlay(
                            Rectangle()
                                .fill(colors.accentPrimary)
                                .frame(width: geo.size.width * recorder.progress),
                            alignment: .leading
                        )
                }
                .frame(height: 4)
                .padding(.top, Theme.Spacing.lg)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { gesture in
                    if gesture.translation.height > 100 && recordingState == .idle {
                        onCancel()
                    }
                }
        )
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
    }

    // MARK: - Status Text
    private var statusText: String {
        switch recordingState {
        case .idle: return "Tap to record"
        case .recording: return "Recording..."
        case .review: return "Review"
        case .uploading: return "Uploading..."
        }
    }

    // MARK: - Instruction Text
    private var instructionText: String {
        switch recordingState {
        case .idle: return "Slide down to cancel"
        case .recording: return "Tap to stop"
        case .review: return "Submit or re-record"
        case .uploading: return "Please wait..."
        }
    }

    // MARK: - Controls
    @ViewBuilder
    private func controlsView(colors: AppColors) -> some View {
        switch recordingState {
        case .idle:
            recordButton(colors: colors)

        case .recording:
            stopButton(colors: colors)

        case .review:
            reviewControls(colors: colors)

        case .uploading:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: colors.accentPrimary))
                .scaleEffect(1.5)
                .frame(height: 72)
        }
    }

    @ViewBuilder
    private func recordButton(colors: AppColors) -> some View {
        Button(action: startRecording) {
            Circle()
                .fill(colors.accentPrimary)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                )
                .shadow(Theme.Shadow.lg)
        }
    }

    @ViewBuilder
    private func stopButton(colors: AppColors) -> some View {
        Button(action: stopRecording) {
            Circle()
                .fill(colors.accentPrimary)
                .frame(width: 72, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                )
                .overlay(
                    Circle()
                        .stroke(colors.accentPrimary.opacity(0.3), lineWidth: 4)
                        .frame(width: 88, height: 88)
                        .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recorder.isRecording)
                )
        }
    }

    @ViewBuilder
    private func reviewControls(colors: AppColors) -> some View {
        HStack(spacing: Theme.Spacing.xl) {
            // Re-record
            Button(action: reRecord) {
                VStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .stroke(colors.textSecondary, lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                                .foregroundColor(colors.textSecondary)
                        )

                    Text("Re-record")
                        .font(AppTypography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }

            // Submit
            Button(action: submit) {
                VStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(colors.accentSecondary)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        )

                    Text("Submit")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(colors.accentSecondary)
                }
            }
        }
    }

    // MARK: - Actions
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
        recorder.cancelRecording()
        recordingState = .idle
    }

    private func submit() {
        guard let data = recorder.getRecordingData() else { return }

        recordingState = .uploading

        let duration = recorder.getDurationSeconds()
        onComplete(data, duration)
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
