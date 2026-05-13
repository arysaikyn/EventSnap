import Foundation
import AVFoundation
import Speech
import EventKit
import Photos

// MARK: - PermissionManager

/// Manages all privacy-sensitive permission requests for EventSnap.
///
/// **Privacy-first philosophy:**
/// - Permissions are NEVER requested at launch.
/// - Each permission is requested only when the user explicitly triggers the
///   corresponding feature.
/// - Usage descriptions are user-friendly and explain WHY the access is needed.
/// - Calendar uses **write-only** access (`requestWriteOnlyAccessToEvents()`)
///   as recommended by Apple security audit guidelines.
/// - Speech recognition is forced to on-device processing only.
/// - All methods are async and return `Bool` for easy SwiftUI integration.
@Observable
@MainActor
final class PermissionManager {

    // MARK: - Authorization States

    /// The current authorization status for calendar (write-only) access.
    private(set) var calendarStatus: EKAuthorizationStatus = .notDetermined

    /// The current authorization status for camera access.
    private(set) var cameraStatus: AVAuthorizationStatus = .notDetermined

    /// The current authorization status for microphone access.
    private(set) var microphoneStatus: AVAuthorizationStatus = .notDetermined

    /// The current authorization status for speech recognition.
    private(set) var speechStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    /// The current authorization status for photo library access.
    private(set) var photoLibraryStatus: PHAuthorizationStatus = .notDetermined

    /// Whether any permission is currently being requested (prevents double-taps).
    private(set) var isRequesting = false

    /// Whether the user has been shown a pre-request explanation for each type.
    private var hasShownExplanation: Set<String> = []

    // MARK: - Initialization

    init() {
        refreshAllStatuses()
    }

    private var currentCalendarAccessStatus: EKAuthorizationStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            return status
        }
        return legacyCalendarStatus(status)
    }

    private func legacyCalendarStatus(_ status: EKAuthorizationStatus) -> EKAuthorizationStatus {
        if status.rawValue == 3 {
            return .fullAccess
        }
        return status
    }

    /// Refreshes all cached authorization statuses without prompting the user.
    func refreshAllStatuses() {
        calendarStatus = currentCalendarAccessStatus
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        speechStatus = SFSpeechRecognizer.authorizationStatus()
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Calendar (Write-Only)

    /// Requests write-only calendar access.
    /// Uses iOS 17+'s `requestWriteOnlyAccessToEvents()` API to minimize data exposure.
    /// - Returns: `true` if access was granted.
    func requestCalendarAccess() async -> Bool {
        guard !isRequesting else { return calendarStatus == .writeOnly || calendarStatus == .fullAccess }
        isRequesting = true
        defer { isRequesting = false }

        let status = currentCalendarAccessStatus
        switch status {
        case .notDetermined:
            markExplanationShown(for: "calendar")
            do {
                let store = EKEventStore()
                let granted = try await store.requestWriteOnlyAccessToEvents()
                calendarStatus = granted ? .writeOnly : .denied
                return granted
            } catch {
                calendarStatus = .denied
                return false
            }
        case .writeOnly, .fullAccess:
            calendarStatus = status
            return true
        case .restricted, .denied:
            calendarStatus = status
            return false
        @unknown default:
            calendarStatus = .denied
            return false
        }
    }

    // MARK: - Camera

    /// Requests camera access for the OCR / camera input flow.
    /// - Returns: `true` if access was granted.
    func requestCameraAccess() async -> Bool {
        guard !isRequesting else { return cameraStatus == .authorized }
        isRequesting = true
        defer { isRequesting = false }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            markExplanationShown(for: "camera")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraStatus = granted ? .authorized : .denied
            return granted
        case .authorized:
            cameraStatus = .authorized
            return true
        case .denied, .restricted:
            cameraStatus = status
            return false
        @unknown default:
            cameraStatus = .denied
            return false
        }
    }

    // MARK: - Microphone

    /// Requests microphone access for speech-to-text input.
    /// - Returns: `true` if access was granted.
    func requestMicrophoneAccess() async -> Bool {
        guard !isRequesting else { return microphoneStatus == .authorized }
        isRequesting = true
        defer { isRequesting = false }

        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .notDetermined:
            markExplanationShown(for: "microphone")
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            microphoneStatus = granted ? .authorized : .denied
            return granted
        case .authorized:
            microphoneStatus = .authorized
            return true
        case .denied, .restricted:
            microphoneStatus = status
            return false
        @unknown default:
            microphoneStatus = .denied
            return false
        }
    }

    // MARK: - Speech Recognition

    /// Requests speech recognition authorization.
    /// Speech processing is forced on-device in the `SpeechService`.
    /// - Returns: `true` if access was granted.
    func requestSpeechAccess() async -> Bool {
        guard !isRequesting else { return speechStatus == .authorized }
        isRequesting = true
        defer { isRequesting = false }

        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .notDetermined:
            markExplanationShown(for: "speech")
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    continuation.resume(returning: authStatus == .authorized)
                }
            }
            speechStatus = granted ? .authorized : .denied
            if !granted { speechStatus = .denied }
            return granted
        case .authorized:
            speechStatus = .authorized
            return true
        case .denied, .restricted:
            speechStatus = status
            return false
        @unknown default:
            speechStatus = .denied
            return false
        }
    }

    // MARK: - Photo Library

    /// Requests read-write photo library access (for OCR from saved photos).
    /// - Returns: `true` if access was granted (limited or full).
    func requestPhotoLibraryAccess() async -> Bool {
        guard !isRequesting else { return photoLibraryStatus == .authorized || photoLibraryStatus == .limited }
        isRequesting = true
        defer { isRequesting = false }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            markExplanationShown(for: "photoLibrary")
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            photoLibraryStatus = newStatus
            return newStatus == .authorized || newStatus == .limited
        case .authorized, .limited:
            photoLibraryStatus = status
            return true
        case .denied, .restricted:
            photoLibraryStatus = status
            return false
        @unknown default:
            photoLibraryStatus = .denied
            return false
        }
    }

    // MARK: - Batch Authorization (for voice flow)

    /// Requests all permissions needed for the voice input flow in one user-initiated sequence.
    /// - Returns: `true` if ALL required permissions were granted.
    func requestVoicePermissions() async -> Bool {
        let mic = await requestMicrophoneAccess()
        let speech = await requestSpeechAccess()
        let cal = await requestCalendarAccess()
        return mic && speech && cal
    }

    /// Requests all permissions needed for the camera input flow.
    /// - Returns: `true` if ALL required permissions were granted.
    func requestCameraPermissions() async -> Bool {
        let cam = await requestCameraAccess()
        let cal = await requestCalendarAccess()
        return cam && cal
    }

    /// Requests all permissions needed for the text input flow.
    /// - Returns: `true` if calendar access was granted.
    func requestTextPermissions() async -> Bool {
        return await requestCalendarAccess()
    }

    // MARK: - Explanation Tracking

    /// Whether the user has already been shown a pre-permission explanation
    /// for the given permission type.
    /// - Parameter type: The permission type key.
    /// - Returns: `true` if explanation was already shown this session.
    func hasShownExplanation(for type: String) -> Bool {
        hasShownExplanation.contains(type)
    }

    private func markExplanationShown(for type: String) {
        hasShownExplanation.insert(type)
    }

    // MARK: - Settings Redirect Helpers

    /// Returns `true` if the user has denied this permission and needs to be
    /// redirected to Settings to grant it.
    func needsSettingsRedirect(for type: PermissionType) -> Bool {
        switch type {
        case .calendar:
            return calendarStatus == .denied || calendarStatus == .restricted
        case .camera:
            return cameraStatus == .denied || cameraStatus == .restricted
        case .microphone:
            return microphoneStatus == .denied || microphoneStatus == .restricted
        case .speech:
            return speechStatus == .denied || speechStatus == .restricted
        case .photoLibrary:
            return photoLibraryStatus == .denied || photoLibraryStatus == .restricted
        }
    }

    /// Human-readable reason why a permission is needed, for use in alerts
    /// that direct users to Settings.
    func settingsReason(for type: PermissionType) -> String {
        switch type {
        case .calendar:
            return "EventSnap needs calendar access to add events to your calendar. You can enable this in Settings."
        case .camera:
            return "EventSnap needs camera access to scan event flyers and posters. You can enable this in Settings."
        case .microphone:
            return "EventSnap needs microphone access to capture voice input for events. You can enable this in Settings."
        case .speech:
            return "EventSnap needs speech recognition to convert your voice into event details. All processing is on-device. You can enable this in Settings."
        case .photoLibrary:
            return "EventSnap needs photo library access to scan event images you've already taken. You can enable this in Settings."
        }
    }
}

// MARK: - PermissionType

/// Enumeration of all permission types managed by `PermissionManager`.
enum PermissionType: String, CaseIterable {
    case calendar
    case camera
    case microphone
    case speech
    case photoLibrary
}
