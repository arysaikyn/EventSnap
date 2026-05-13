import SwiftUI
import AVFoundation

@Observable
final class VoiceViewModel {
    // MARK: - Published State

    var isRecording = false
    var isProcessing = false
    var liveTranscription = ""
    var audioLevels: [Float] = Array(repeating: 0, count: 60)
    var silenceCountdown: Int?
    var recordingError: String?
    var statusMessage = "Tap the microphone to start"

    // MARK: - Dependencies

    private let speechService: SpeechService

    // MARK: - Private State

    private var monitorTask: Task<Void, Never>?
    private var onTranscriptionComplete: ((String) -> Void)?
    private var previousTranscription = ""

    // MARK: - Constants

    private static let waveformBufferSize = 60
    private static let monitorInterval: UInt64 = 100_000_000

    // MARK: - Init

    init(speechService: SpeechService) {
        self.speechService = speechService
    }

    deinit {
        monitorTask?.cancel()
    }

    // MARK: - Recording Control

    /// Start recording with a completion handler that receives the final transcription.
    func startRecording(onTranscription: @escaping (String) -> Void) {
        guard !isRecording && !isProcessing else { return }

        onTranscriptionComplete = onTranscription
        liveTranscription = ""
        audioLevels = Array(repeating: 0, count: Self.waveformBufferSize)
        silenceCountdown = nil
        recordingError = nil
        previousTranscription = ""
        statusMessage = "Requesting microphone access..."

        Task { @MainActor [weak self] in
            guard let self else { return }

            guard await self.requestMicrophonePermission() else {
                self.recordingError = "Microphone access is required for voice input."
                self.statusMessage = "Microphone access needed"
                return
            }

            guard await self.speechService.requestAuthorization() else {
                self.recordingError = "Speech recognition access is required for voice input."
                self.statusMessage = "Speech recognition access needed"
                return
            }

            do {
                self.isRecording = true
                self.statusMessage = "Listening..."
                try await self.speechService.startRecording()
                self.startMonitoringSpeechService()
            } catch {
                self.isRecording = false
                self.recordingError = error.localizedDescription
                self.statusMessage = "Could not start listening"
            }
        }
    }

    /// Stop recording manually (user taps stop button).
    func stopRecording() {
        guard isRecording else { return }
        finishRecording()
    }

    func cancelRecording() {
        monitorTask?.cancel()
        speechService.cancelRecording()
        isRecording = false
        isProcessing = false
        liveTranscription = ""
        previousTranscription = ""
        statusMessage = "Cancelled"
        onTranscriptionComplete = nil
    }

    // MARK: - Private Implementation

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startMonitoringSpeechService() {
        monitorTask?.cancel()
        monitorTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled && self.isRecording {
                try? await Task.sleep(nanoseconds: Self.monitorInterval)

                self.appendAudioLevel(self.speechService.audioLevel)

                let current = self.speechService.transcript
                if current != self.previousTranscription && !current.isEmpty {
                    self.liveTranscription = current
                    self.previousTranscription = current
                    self.statusMessage = "Listening..."
                }

                if !self.speechService.isRecording {
                    self.finishRecording()
                    break
                }
            }
        }
    }

    private func finishRecording() {
        monitorTask?.cancel()
        speechService.stopRecording()

        isRecording = false
        isProcessing = true
        silenceCountdown = nil

        let finalText = speechService.finalTranscript.isEmpty
            ? liveTranscription
            : speechService.finalTranscript
        let trimmed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            isProcessing = false
            statusMessage = "No speech detected"
            recordingError = "I couldn't hear any event details. Try again closer to the microphone."
            onTranscriptionComplete = nil
            return
        }

        liveTranscription = trimmed
        statusMessage = "Processing..."
        let completion = onTranscriptionComplete
        onTranscriptionComplete = nil

        Task { @MainActor in
            isProcessing = false
            statusMessage = "Done"
            completion?(trimmed)
        }
    }

    private func appendAudioLevel(_ level: Float) {
        audioLevels.append(level)
        if audioLevels.count > Self.waveformBufferSize {
            audioLevels = Array(audioLevels.suffix(Self.waveformBufferSize))
        }
    }
}
