import SwiftUI
import AVFoundation

@Observable
final class VoiceViewModel {
    // MARK: - Published State

    var isRecording = false
    var liveTranscription = ""
    var audioLevels: [Float] = Array(repeating: 0, count: 60)
    var silenceCountdown: Int?
    var recordingError: String?

    // MARK: - Dependencies

    private let speechService: SpeechService

    // MARK: - Private State

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var silenceDuration: TimeInterval = 0
    private let silenceThreshold: Float = 0.025
    private let maxSilenceDuration: TimeInterval = 3.0
    private var onTranscriptionComplete: ((String) -> Void)?
    private var previousTranscription = ""

    // MARK: - Init

    init(speechService: SpeechService) {
        self.speechService = speechService
    }

    deinit {
        tearDown()
    }

    // MARK: - Recording Control

    /// Start recording with a completion handler that receives the final transcription.
    func startRecording(onTranscription: @escaping (String) -> Void) {
        guard !isRecording else { return }

        onTranscriptionComplete = onTranscription
        liveTranscription = ""
        audioLevels = Array(repeating: 0, count: 60)
        silenceCountdown = nil
        silenceDuration = 0
        recordingError = nil
        previousTranscription = ""

        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { [weak self] granted in
            guard let self else { return }

            if granted {
                self.setupAudioSession()
                self.startAudioLevelMonitoring()
                self.startSpeechRecognition()
            } else {
                DispatchQueue.main.async {
                    self.recordingError = "Microphone access is required for voice input."
                }
            }
        }
    }

    /// Stop recording manually (user taps stop button).
    func stopRecording() {
        guard isRecording else { return }
        performStop()
    }

    // MARK: - Private Implementation

    private func startSpeechRecognition() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.speechService.startRecording()
            } catch {
                self.recordingError = error.localizedDescription
                self.performStop()
                return
            }

            // Poll for transcript updates from the @Observable SpeechService
            while self.isRecording && self.speechService.isRecording {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                let current = self.speechService.transcript
                if current != self.previousTranscription && !current.isEmpty {
                    self.liveTranscription = current
                    self.previousTranscription = current
                    self.silenceDuration = 0
                    self.silenceCountdown = nil
                }

                // Check for final transcript (recording stopped externally)
                if !self.speechService.isRecording && !self.speechService.finalTranscript.isEmpty {
                    self.liveTranscription = self.speechService.finalTranscript
                    break
                }
            }
        }

        DispatchQueue.main.async {
            self.isRecording = true
        }
    }

    private func performStop() {
        speechService.stopRecording()
        stopAudioLevelMonitoring()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isRecording = false
            self.silenceCountdown = nil

            let trimmed = self.liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                self.onTranscriptionComplete?(trimmed)
            }
            self.onTranscriptionComplete = nil
        }
    }

    // MARK: - Audio Level Monitoring

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async {
                self.recordingError = "Failed to configure audio session: \(error.localizedDescription)"
            }
        }
    }

    private func startAudioLevelMonitoring() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("eventsnap_recording_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            // Poll audio levels at 50ms intervals (60 samples = 3 seconds of waveform)
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.audioRecorder?.updateMeters()
                let rawPower = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                let normalized = self.normalizedLevel(from: rawPower)

                DispatchQueue.main.async {
                    // Append and keep buffer at exactly 60 samples
                    self.audioLevels.append(normalized)
                    if self.audioLevels.count > 60 {
                        self.audioLevels = Array(self.audioLevels.suffix(60))
                    }

                    // Silence detection
                    if normalized < self.silenceThreshold {
                        self.silenceDuration += 0.05

                        // Show countdown in the last 3 seconds
                        if self.silenceDuration >= self.maxSilenceDuration - 3.0 {
                            let remaining = Int(self.maxSilenceDuration - self.silenceDuration) + 1
                            if (1...3).contains(remaining) {
                                self.silenceCountdown = remaining
                            }
                        }

                        // Auto-stop after max silence
                        if self.silenceDuration >= self.maxSilenceDuration {
                            self.performStop()
                        }
                    } else {
                        self.silenceDuration = 0
                        self.silenceCountdown = nil
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.recordingError = "Failed to start audio monitoring: \(error.localizedDescription)"
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        audioRecorder = nil
    }

    /// Convert decibel power (-160…0 dB) to a 0.0–1.0 normalized float.
    private func normalizedLevel(from power: Float) -> Float {
        let minDb: Float = -60.0
        let maxDb: Float = 0.0
        guard power > minDb else { return 0.0 }
        return min(1.0, max(0.0, (power - minDb) / (maxDb - minDb)))
    }

    private func tearDown() {
        if isRecording {
            speechService.stopRecording()
        }
        stopAudioLevelMonitoring()
    }
}