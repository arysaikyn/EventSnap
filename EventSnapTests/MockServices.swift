import Foundation
import EventKit
import XCTest
import SwiftData

@testable import EventSnap

// MARK: - MockOCRService

/// Mock implementation of OCRService for testing.
actor MockOCRService {
    
    // MARK: - Configuration
    
    var shouldFail = false
    var delay: TimeInterval = 0.0
    var mockText = "Sample event text\nMeeting at 3pm"
    
    // MARK: - Public API
    
    func recognizeText(from image: UIImage) async throws -> OCRService.OCRResult {
        if shouldFail {
            throw OCRService.OCRServiceError.recognitionFailed(underlying: NSError(domain: "MockError", code: 1))
        }
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        return OCRService.OCRResult(
            fullText: mockText,
            observations: [
                OCRService.TextObservation(
                    id: UUID(),
                    text: "Sample event text",
                    confidence: 0.95,
                    boundingBox: CGRect(x: 0, y: 0, width: 1, height: 0.1),
                    topLeft: CGPoint(x: 0, y: 0.9),
                    bottomRight: CGPoint(x: 1, y: 1)
                ),
                OCRService.TextObservation(
                    id: UUID(),
                    text: "Meeting at 3pm",
                    confidence: 0.88,
                    boundingBox: CGRect(x: 0, y: 0.1, width: 1, height: 0.1),
                    topLeft: CGPoint(x: 0, y: 0.8),
                    bottomRight: CGPoint(x: 1, y: 0.9)
                )
            ],
            averageConfidence: 0.915,
            sanitizedText: mockText
        )
    }
    
    func fastScan(from image: UIImage) async throws -> OCRService.OCRResult {
        return try await recognizeText(from: image)
    }
    
    func detailedScan(from image: UIImage) async throws -> OCRService.OCRResult {
        return try await recognizeText(from: image)
    }
    
    func recognizeText(from cgImage: CGImage, tier: OCRService.RecognitionTier = .accurate) async throws -> OCRService.OCRResult {
        return try await recognizeText(from: UIImage(cgImage: cgImage))
    }
    
    // MARK: - Test Helpers
    
    func setMockText(_ text: String) {
        mockText = text
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func setDelay(_ seconds: TimeInterval) {
        delay = seconds
    }
}

// MARK: - MockCalendarService

/// Mock implementation of CalendarService for testing.
@MainActor
class MockCalendarService {
    
    // MARK: - Configuration
    
    var shouldFail = false
    var shouldDenyAccess = false
    var shouldFindDuplicate = false
    var mockEvents: [EKEvent] = []
    
    // MARK: - Properties
    
    var defaultCalendar: EKCalendar?
    var isAccessGranted: Bool = true
    var writableCalendars: [EKCalendar] = []
    var availableCalendars: [EKCalendar] {
        writableCalendars
    }
    
    // MARK: - Public API
    
    func requestAccess() async throws -> Bool {
        if shouldDenyAccess {
            throw CalendarService.CalendarError.accessDenied
        }
        return true
    }
    
    func addEvent(_ parsedEvent: ParsedEvent) async throws -> EKEvent {
        if shouldFail {
            throw CalendarService.CalendarError.eventCreationFailed(underlying: NSError(domain: "MockError", code: 1))
        }
        
        if shouldFindDuplicate {
            throw CalendarService.CalendarError.duplicateEventFound(
                title: parsedEvent.title,
                existingDate: parsedEvent.startDate
            )
        }
        
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.title = parsedEvent.title
        event.startDate = parsedEvent.startDate
        event.endDate = parsedEvent.endDate ?? parsedEvent.startDate.addingTimeInterval(3600)
        event.notes = parsedEvent.notes
        event.location = parsedEvent.location
        event.calendar = defaultCalendar
        
        mockEvents.append(event)
        return event
    }
    
    func addEvent(_ parsedEvent: ParsedEvent, to calendar: EKCalendar) async throws -> EKEvent {
        var mutableEvent = parsedEvent
        mutableEvent.calendar = calendar
        return try await addEvent(mutableEvent)
    }
    
    func findDuplicate(title: String, startDate: Date) -> EKEvent? {
        if shouldFindDuplicate {
            return EKEvent(eventStore: EKEventStore())
        }
        return nil
    }
    
    func setDefaultCalendar(_ calendar: EKCalendar?) {
        defaultCalendar = calendar
    }
    
    func resetDefaultCalendar() {
        defaultCalendar = nil
    }
    
    func openEventInCalendar(with eventIdentifier: String) {
        // No-op for mock
    }
    
    // MARK: - Test Helpers
    
    @MainActor
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    @MainActor
    func setShouldDenyAccess(_ deny: Bool) {
        shouldDenyAccess = deny
        isAccessGranted = !deny
    }
    
    @MainActor
    func setShouldFindDuplicate(_ find: Bool) {
        shouldFindDuplicate = find
    }
    
    @MainActor
    func getMockEvents() -> [EKEvent] {
        return mockEvents
    }
    
    @MainActor
    func clearMockEvents() {
        mockEvents.removeAll()
    }
}

// MARK: - MockSpeechService

/// Mock implementation of SpeechService for testing.
@Observable
@MainActor
final class MockSpeechService {
    
    // MARK: - Published State
    
    private(set) var transcript: String = ""
    private(set) var finalTranscript: String = ""
    private(set) var isRecording = false
    private(set) var isAuthorized = true
    private(set) var statusMessage: String = "Ready"
    private(set) var lastError: SpeechService.SpeechServiceError?
    private(set) var audioLevel: Float = 0.0
    
    // MARK: - Private Properties
    
    private var mockTranscription = "Meeting tomorrow at 3pm"
    private var delay: TimeInterval = 0.0
    private var shouldFail = false
    
    // MARK: - Public API
    
    func startRecording() async throws {
        if shouldFail {
            throw SpeechService.SpeechServiceError.recognitionFailed(underlying: "Mock error")
        }
        
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        isRecording = true
        statusMessage = "Listening..."
        
        // Simulate transcription after a delay
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        transcript = mockTranscription
        finalTranscript = mockTranscription
        isRecording = false
        statusMessage = "Done"
    }
    
    func stopRecording() {
        isRecording = false
        statusMessage = "Done"
    }
    
    func cancelRecording() {
        transcript = ""
        finalTranscript = ""
        stopRecording()
        statusMessage = "Cancelled"
    }
    
    func requestAuthorization() async -> Bool {
        return true
    }
    
    // MARK: - Test Helpers
    
    func setMockTranscription(_ transcription: String) {
        mockTranscription = transcription
    }
    
    func setShouldFail(_ fail: Bool) {
        shouldFail = fail
    }
    
    func setDelay(_ seconds: TimeInterval) {
        delay = seconds
    }
}

// MARK: - MockPermissionManager

/// Mock implementation of PermissionManager for testing.
@Observable
@MainActor
final class MockPermissionManager {
    
    // MARK: - Configuration
    
    var shouldDenyCalendar = false
    var shouldDenyCamera = false
    var shouldDenyMicrophone = false
    var shouldDenySpeech = false
    var shouldDenyPhotoLibrary = false
    
    // MARK: - Properties
    
    private(set) var calendarStatus: Int = 0 // EKAuthorizationStatus
    private(set) var cameraStatus: Int = 0 // AVAuthorizationStatus
    private(set) var microphoneStatus: Int = 0 // AVAuthorizationStatus
    private(set) var speechStatus: Int = 0 // SFSpeechRecognizerAuthorizationStatus
    private(set) var photoLibraryStatus: Int = 0 // PHAuthorizationStatus
    private(set) var isRequesting = false
    
    // MARK: - Public API
    
    func requestCalendarAccess() async -> Bool {
        isRequesting = true
        defer { isRequesting = false }
        
        if shouldDenyCalendar {
            calendarStatus = 2 // .denied
            return false
        }
        
        calendarStatus = 3 // .authorized
        return true
    }
    
    func requestCameraAccess() async -> Bool {
        isRequesting = true
        defer { isRequesting = false }
        
        if shouldDenyCamera {
            cameraStatus = 2 // .denied
            return false
        }
        
        cameraStatus = 3 // .authorized
        return true
    }
    
    func requestMicrophoneAccess() async -> Bool {
        isRequesting = true
        defer { isRequesting = false }
        
        if shouldDenyMicrophone {
            microphoneStatus = 2 // .denied
            return false
        }
        
        microphoneStatus = 3 // .authorized
        return true
    }
    
    func requestSpeechAccess() async -> Bool {
        isRequesting = true
        defer { isRequesting = false }
        
        if shouldDenySpeech {
            speechStatus = 2 // .denied
            return false
        }
        
        speechStatus = 3 // .authorized
        return true
    }
    
    func requestPhotoLibraryAccess() async -> Bool {
        isRequesting = true
        defer { isRequesting = false }
        
        if shouldDenyPhotoLibrary {
            photoLibraryStatus = 2 // .denied
            return false
        }
        
        photoLibraryStatus = 3 // .authorized
        return true
    }
    
    func requestVoicePermissions() async -> Bool {
        let mic = await requestMicrophoneAccess()
        let speech = await requestSpeechAccess()
        let cal = await requestCalendarAccess()
        return mic && speech && cal
    }
    
    func requestCameraPermissions() async -> Bool {
        let cam = await requestCameraAccess()
        let cal = await requestCalendarAccess()
        return cam && cal
    }
    
    func requestTextPermissions() async -> Bool {
        return await requestCalendarAccess()
    }
    
    func refreshAllStatuses() {
        // No-op for mock
    }
    
    // MARK: - Test Helpers
    
    func setShouldDenyCalendar(_ deny: Bool) {
        shouldDenyCalendar = deny
    }
    
    func setShouldDenyCamera(_ deny: Bool) {
        shouldDenyCamera = deny
    }
    
    func setShouldDenyMicrophone(_ deny: Bool) {
        shouldDenyMicrophone = deny
    }
    
    func setShouldDenySpeech(_ deny: Bool) {
        shouldDenySpeech = deny
    }
    
    func setShouldDenyPhotoLibrary(_ deny: Bool) {
        shouldDenyPhotoLibrary = deny
    }
    
    func setAllPermissionsGranted(_ granted: Bool) {
        shouldDenyCalendar = !granted
        shouldDenyCamera = !granted
        shouldDenyMicrophone = !granted
        shouldDenySpeech = !granted
        shouldDenyPhotoLibrary = !granted
        
        if granted {
            calendarStatus = 3 // .authorized
            cameraStatus = 3 // .authorized
            microphoneStatus = 3 // .authorized
            speechStatus = 3 // .authorized
            photoLibraryStatus = 3 // .authorized
        } else {
            calendarStatus = 2 // .denied
            cameraStatus = 2 // .denied
            microphoneStatus = 2 // .denied
            speechStatus = 2 // .denied
            photoLibraryStatus = 2 // .denied
        }
    }
}

// NOTE: OCRServiceError, SpeechServiceError, and RecognitionTier are defined
// in the app module (OCRService.swift, SpeechService.swift) and accessed via
// @testable import EventSnap. No need to re-define them here.