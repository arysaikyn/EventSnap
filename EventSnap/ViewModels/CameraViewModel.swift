import SwiftUI
import AVFoundation
import CoreImage
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class CameraViewModel: NSObject {
    enum ScanReadiness: Equatable {
        case idle
        case looking
        case noText
        case textDetected
        case needsMoreDetail
        case eventReady
        case processing
        case error(String)

        var message: String {
            switch self {
            case .idle, .looking:
                return "Point at an event flyer"
            case .noText:
                return "No readable text yet"
            case .textDetected:
                return "Text found — hold steady"
            case .needsMoreDetail:
                return "Move closer for date and time"
            case .eventReady:
                return "Event details found"
            case .processing:
                return "Scanning..."
            case .error(let message):
                return message
            }
        }

        var tintColor: Color {
            switch self {
            case .eventReady:
                return Color.semanticSuccess
            case .textDetected, .needsMoreDetail, .processing:
                return Color.brandAccent
            case .error:
                return Color.semanticError
            case .idle, .looking, .noText:
                return Color.semanticError
            }
        }
    }

    // MARK: - Published State

    var capturedImage: UIImage?
    var isProcessing = false
    var extractedTextPreview = ""
    var scanReadiness: ScanReadiness = .idle
    var bestDetectedText = ""
    var detectedEventTitle: String?
    var isFlashOn = false
    var captureError: String?

    // MARK: - Capture Session

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.eventsnap.camera.session", qos: .userInitiated)
    private let sampleQueue = DispatchQueue(label: "com.eventsnap.camera.samples", qos: .userInitiated)
    private let ciContext = CIContext()
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?
    private var cameraPosition: AVCaptureDevice.Position = .back
    private var isConfigured = false
    private var isLiveScanning = false
    private var isAnalyzingFrame = false
    private var lastFrameAnalysisDate = Date.distantPast
    private let frameAnalysisInterval: TimeInterval = 0.75

    // MARK: - Dependencies

    private let ocrService: OCRService

    // MARK: - Init

    init(ocrService: OCRService) {
        self.ocrService = ocrService
        super.init()
    }

    deinit {
        tearDownSession()
    }

    // MARK: - Session Lifecycle

    /// Configure and start the capture session on a background thread.
    func startSession() {
        guard !captureSession.isRunning else { return }

        scanReadiness = .looking
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSessionIfNeeded()
            guard self.isConfigured else { return }
            self.captureSession.startRunning()
        }
    }

    /// Stop the capture session.
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    func startLiveScanning() {
        isLiveScanning = true
        if scanReadiness == .idle {
            scanReadiness = .looking
        }
    }

    func stopLiveScanning() {
        isLiveScanning = false
        isAnalyzingFrame = false
    }

    func clearScanResult() {
        capturedImage = nil
        extractedTextPreview = ""
        bestDetectedText = ""
        detectedEventTitle = nil
        scanReadiness = .looking
    }

    /// Full teardown — used in deinit and when leaving the camera view permanently.
    private func tearDownSession() {
        stopLiveScanning()
        captureSession.stopRunning()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        isConfigured = false
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            Task { @MainActor in
                self.captureError = "Camera not available on this device."
                self.scanReadiness = .error("Camera unavailable")
            }
            captureSession.commitConfiguration()
            return
        }

        guard captureSession.canAddInput(input) else {
            Task { @MainActor in
                self.captureError = "Cannot attach camera input."
                self.scanReadiness = .error("Camera input failed")
            }
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(input)

        guard captureSession.canAddOutput(photoOutput) else {
            Task { @MainActor in
                self.captureError = "Cannot attach photo output."
                self.scanReadiness = .error("Photo capture failed")
            }
            captureSession.removeInput(input)
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(photoOutput)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.connection(with: .video)?.videoRotationAngle = 90
        }

        isConfigured = true
        captureSession.commitConfiguration()
    }

    // MARK: - Capture

    /// Capture a photo and return the UIImage asynchronously.
    /// Returns `nil` if the session is not running or capture fails.
    func capturePhoto() async -> UIImage? {
        guard captureSession.isRunning else {
            captureError = "Camera session is not running."
            return nil
        }

        isProcessing = true
        scanReadiness = .processing
        capturedImage = nil

        let settings = AVCapturePhotoSettings()
        if isFlashOn, let device = AVCaptureDevice.default(for: .video), device.hasFlash {
            settings.flashMode = .on
        }

        // Suspend the capture output queue so the delegate fires reliably
        photoOutput.connection(with: .video)?.isEnabled = true

        return await withCheckedContinuation { continuation in
            photoContinuation = continuation
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func toggleFlash() {
        isFlashOn.toggle()
    }

    /// Switch between front and back camera by rebuilding the session input.
    func switchCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back

        captureSession.beginConfiguration()

        // Remove existing video inputs, saving them for potential restoration
        let removedInputs = captureSession.inputs

        for input in removedInputs {
            captureSession.removeInput(input)
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(newInput) else {
            captureError = "Camera not available for selected position."
            // Restore removed inputs on failure so the session isn't left in a broken state
            for input in removedInputs {
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            }
            captureSession.commitConfiguration()
            return
        }

        captureSession.addInput(newInput)
        captureSession.commitConfiguration()
    }

    private func updateReadiness(with result: OCRService.OCRResult) {
        let trimmed = result.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        extractedTextPreview = trimmed

        guard !trimmed.isEmpty else {
            scanReadiness = .noText
            return
        }

        bestDetectedText = trimmed
        if let parsed = NLParser.parse(trimmed, inputType: .camera) {
            detectedEventTitle = parsed.title
            if parsed.confidence >= 0.55 && parsed.startDate > Date.distantPast {
                scanReadiness = .eventReady
            } else {
                scanReadiness = .needsMoreDetail
            }
        } else {
            detectedEventTitle = nil
            scanReadiness = result.averageConfidence >= 0.45 ? .needsMoreDetail : .textDetected
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        defer {
            isProcessing = false
        }

        if let error {
            captureError = "Photo capture failed: \(error.localizedDescription)"
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureError = "Could not process captured photo data."
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        capturedImage = image
        photoContinuation?.resume(returning: image)
        photoContinuation = nil

        // OCR is handled by EventCreationVM — only update readiness from live scan,
        // not from capture, to avoid redundant double-processing
        isProcessing = false
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isLiveScanning, !isProcessing, !isAnalyzingFrame else { return }

        let now = Date()
        guard now.timeIntervalSince(lastFrameAnalysisDate) >= frameAnalysisInterval else { return }
        lastFrameAnalysisDate = now
        isAnalyzingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isAnalyzingFrame = false
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            isAnalyzingFrame = false
            return
        }

        Task { @MainActor in
            do {
                let result = try await ocrService.recognizeText(from: cgImage, tier: .fast)
                updateReadiness(with: result)
            } catch {
                if bestDetectedText.isEmpty {
                    scanReadiness = .noText
                }
            }
            isAnalyzingFrame = false
        }
    }
}
