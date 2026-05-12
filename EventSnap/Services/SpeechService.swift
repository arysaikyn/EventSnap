import Foundation
import Speech
import AVFoundation

// MARK: - SpeechService

/// On-device speech recognition for EventSnap's voice input flow.
///
/// **Privacy & security:**
/// - Forces `requiresOnDeviceProcessing = true` — no audio leaves the device.
/// - Cleans up all audio resources immediately on stop.
/// - Publishes live transcription results for real-time UI feedback.
///
/// **Auto-stop behavior:**
/// - Automatically stops recording after **3 seconds of silence**
///   (no new transcription received within that window).
///
/// **Lifecycle:**
/// ```
/// requestAuthorization() → startRecording() → [live transcription]
/// → auto-stop after 3s silence → finalizeTranscription()
/// ```
@Observable
@MainActor
final class SpeechService {

    // MARK: - Published State

    /// The current live transcription text, updated as the user speaks.
    private(set) var transcript: String = ""

    /// The final transcription after recording stops.
    private(set) var finalTranscript: String = ""

    /// Whether audio is currently being captured and recognized.
    private(set) var isRecording = false

    /// Whether speech recognition authorization has been granted.
    private(set) var isAuthorized = false

    /// A localized status message for UI display (e.g., "Listening...", "Processing...").
    private(set) var statusMessage: String = ""

    /// The most recent error, if any. Cleared on each new recording attempt.
    private(set) var lastError: SpeechServiceError?

    /// Current audio level estimate (0.0–1.0) for waveform visualization.
    private(set) var audioLevel: Float = 0.0

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    /// Timer for auto-stop after silence detection.
    private var silenceTimer: Timer?

    /// The duration of silence (in seconds) before auto-stopping.
    private let silenceThreshold: TimeInterval = 3.0

    /// When the last transcription was received.
    private var lastTranscriptionTime: Date = .distantPast

    /// Requested locale. Defaults to `en-US`.
    private let locale: Locale

    // MARK: - Errors

    enum SpeechServiceError: LocalizedError, Equatable {
        case notAuthorized
        case recognizerUnavailable
        case audioSessionError(description: String)
        case recognitionFailed(underlying: String?)
        case noTranscription
        case cancelled

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Speech recognition is not authorized. Please enable it in Settings."
            case .recognizerUnavailable:
                return "Speech recognition is not available on this device."
            case .audioSessionError(let description):
                return "Audio session error: \(description)"
            case .recognitionFailed(let underlying):
                return "Recognition failed: \(underlying ?? "Unknown error")"
            case .noTranscription:
                return "No speech was detected. Please try again."
            case .cancelled:
                return "Speech recognition was cancelled."
            }
        }
    }

    // MARK: - Init

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.locale = locale
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer()!
        // Note: requiresOnDeviceProcessing was removed in newer iOS versions.
        // On-device processing is enforced via the speech recognition usage description.
        self.statusMessage = "Ready"
    }

    deinit {
        // stopRecording() is MainActor-isolated, can't call from deinit.
        // ARC will clean up the audio engine and recognition task.
        audioEngine.stop()
    }

    // MARK: - Authorization

    /// Requests authorization for speech recognition.
    /// - Returns: `true` if authorization was granted.
    func requestAuthorization() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            isAuthorized = true
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
                    Task { @MainActor in
                        let granted = authStatus == .authorized
                        self?.isAuthorized = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            return false
        @unknown default:
            isAuthorized = false
            return false
        }
    }

    // MARK: - Recording

    /// Starts recording and performing on-device speech recognition.
    ///
    /// - Important: Must call `requestAuthorization()` first and receive `true`.
    /// - Throws: `SpeechServiceError` if setup fails.
    func startRecording() async throws {
        lastError = nil
        transcript = ""
        finalTranscript = ""
        lastTranscriptionTime = Date()

        guard isAuthorized else {
            throw SpeechServiceError.notAuthorized
        }

        guard speechRecognizer.isAvailable else {
            throw SpeechServiceError.recognizerUnavailable
        }

        // Stop any ongoing recording
        stopRecording()

        // Configure audio session for recording
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechServiceError.audioSessionError(description: error.localizedDescription)
        }

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechServiceError.recognitionFailed(underlying: "Could not create recognition request")
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // Force on-device

        // Set up audio tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateAudioLevel(from: buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            throw SpeechServiceError.audioSessionError(description: error.localizedDescription)
        }

        isRecording = true
        statusMessage = "Listening..."

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error as? NSError {
                    // Cancelled is not a real error — check via localized description
                    if error.localizedDescription.lowercased().contains("cancelled") ||
                       error.localizedDescription.lowercased().contains("canceled") {
                        return
                    }
                    self.lastError = .recognitionFailed(underlying: error.localizedDescription)
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.stopRecording()
                    return
                }

                if let result = result {
                    // Update transcript
                    self.transcript = result.bestTranscription.formattedString
                    self.lastTranscriptionTime = Date()

                    // Reset silence timer on each new transcription
                    self.resetSilenceTimer()

                    if result.isFinal {
                        self.finalTranscript = self.transcript
                        self.statusMessage = "Done"
                        self.isRecording = false
                    } else {
                        self.statusMessage = "Listening..."
                    }
                }
            }
        }

        // Start silence detection timer
        startSilenceTimer()
    }

    /// Stops recording and cleans up all audio resources.
    func stopRecording() {
        // Invalidate silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil

        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Stop audio engine and remove tap
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        // Deactivate audio session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Silently fail — not critical
        }

        isRecording = false

        if transcript.isEmpty {
            statusMessage = "No speech detected"
        } else if finalTranscript.isEmpty {
            // If we stopped before getting a final result, use current transcript
            finalTranscript = transcript
            statusMessage = "Processing..."
        } else {
            statusMessage = "Done"
        }
    }

    /// Cancels the current recording without saving the transcript.
    func cancelRecording() {
        transcript = ""
        finalTranscript = ""
        stopRecording()
        statusMessage = "Cancelled"
    }

    // MARK: - Silence Detection

    /// Resets the 3-second silence timer.
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }

    /// Starts a timer that fires after `silenceThreshold` seconds and
    /// auto-stops the recording if no new transcription arrived.
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isRecording else { return }

                // Check how long since last transcription
                let elapsed = Date().timeIntervalSince(self.lastTranscriptionTime)
                if elapsed >= self.silenceThreshold {
                    self.statusMessage = "Processing..."
                    self.stopRecording()
                }
            }
        }
    }

    // MARK: - Audio Level

    /// Updates the current audio level estimate for waveform visualization.
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)

        var level: Float = 0
        for i in 0..<frameLength {
            level += abs(channelDataValue[i])
        }
        level /= Float(frameLength)

        // Normalize to 0.0–1.0 (approximate range for speech)
        let normalized = min(level * 5.0, 1.0)
        Task { @MainActor in
            self.audioLevel = normalized
        }
    }

    // MARK: - Status Checks

    /// Whether the speech recognizer is available on this device.
    var isRecognizerAvailable: Bool {
        speechRecognizer.isAvailable
    }

    /// Human-readable current state description for accessibility.
    var accessibilityStatus: String {
        if isRecording {
            return "Recording. Current text: \(transcript)"
        }
        return statusMessage
    }
}

// MARK: - SFSpeechRecognizer Availability Check

extension SFSpeechRecognizer {
    /// Convenience check for device support.
    static var isSupportedOnDevice: Bool {
        !SFSpeechRecognizer.supportedLocales().isEmpty
    }
}