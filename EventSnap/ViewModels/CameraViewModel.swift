import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class CameraViewModel: NSObject {
    // MARK: - Published State

    var capturedImage: UIImage?
    var isProcessing = false
    var extractedTextPreview = ""
    var isFlashOn = false
    var captureError: String?

    // MARK: - Capture Session

    let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?
    private var cameraPosition: AVCaptureDevice.Position = .back
    private var isConfigured = false

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

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Prevent duplicate configuration
        if !isConfigured {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                captureError = "Camera not available on this device."
                captureSession.commitConfiguration()
                return
            }

            guard captureSession.canAddInput(input) else {
                captureError = "Cannot attach camera input."
                captureSession.commitConfiguration()
                return
            }
            captureSession.addInput(input)

            guard captureSession.canAddOutput(photoOutput) else {
                captureError = "Cannot attach photo output."
                captureSession.removeInput(input)
                captureSession.commitConfiguration()
                return
            }
            captureSession.addOutput(photoOutput)

            isConfigured = true
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    /// Stop the capture session.
    func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    /// Full teardown — used in deinit and when leaving the camera view permanently.
    private func tearDownSession() {
        captureSession.stopRunning()
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        isConfigured = false
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
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto?,
        error: Error?
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

        guard let photo,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureError = "Could not process captured photo data."
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }

        capturedImage = image
        photoContinuation?.resume(returning: image)
        photoContinuation = nil

        // Run OCR on the captured image for a live preview
        Task { @MainActor in
            do {
                let ocrResult = try await ocrService.recognizeText(from: image)
                extractedTextPreview = ocrResult.fullText
            } catch {
                extractedTextPreview = ""
            }
        }
    }
}