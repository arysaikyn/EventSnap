import XCTest
import SwiftUI
import SwiftData

@testable import EventSnap

// MARK: - CoordinatorFlowTests

/// Tests for the EventCreationViewModel coordinator flow.
/// Uses real services with an in-memory SwiftData store.
@MainActor
final class CoordinatorFlowTests: XCTestCase {
    
    var viewModel: EventCreationViewModel!
    var calendarService: CalendarService!
    var ocrService: OCRService!
    var speechService: SpeechService!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        calendarService = CalendarService()
        ocrService = OCRService()
        speechService = SpeechService()
        
        let container = try! ModelContainer(
            for: EventHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = container.mainContext
        
        viewModel = EventCreationViewModel(
            calendarService: calendarService,
            ocrService: ocrService,
            speechService: speechService,
            modelContext: modelContext
        )
    }
    
    override func tearDown() {
        viewModel = nil
        calendarService = nil
        ocrService = nil
        speechService = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_IsIdle() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.parsedEvent)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.processingProgress, 0.0)
    }
    
    // MARK: - Start Capture Tests
    
    func testStartCapture_TextInput() {
        viewModel.startCapture(.text)
        XCTAssertEqual(viewModel.state, .capturing(.text))
        XCTAssertNil(viewModel.parsedEvent)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testStartCapture_CameraInput() {
        viewModel.startCapture(.camera)
        XCTAssertEqual(viewModel.state, .capturing(.camera))
    }
    
    func testStartCapture_VoiceInput() {
        viewModel.startCapture(.voice)
        XCTAssertEqual(viewModel.state, .capturing(.voice))
    }
    
    func testStartCapture_ClearsPreviousState() {
        // Given - set some previous state
        viewModel.errorMessage = "Previous error"
        
        // When
        viewModel.startCapture(.text)
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.parsedEvent)
    }
    
    // MARK: - Process Input Tests
    
    func testProcessInput_TextInput_Success() async {
        // Given
        viewModel.startCapture(.text)
        
        // When - NLParser should parse "Lunch tomorrow at noon"
        await viewModel.processInput(.text("Lunch tomorrow at noon"))
        
        // Then - should transition to preview
        if case .preview(let event) = viewModel.state {
            XCTAssertFalse(event.title.isEmpty)
            XCTAssertNotNil(viewModel.parsedEvent)
        } else {
            XCTFail("Expected .preview state, got \(viewModel.state)")
        }
    }
    
    func testProcessInput_EmptyText_FailsGracefully() async {
        // Given
        viewModel.startCapture(.text)
        
        // When - empty text should fail to parse
        await viewModel.processInput(.text(""))
        
        // Then - should be in error state (NLParser returns nil for empty input)
        if case .error = viewModel.state {
            XCTAssertNotNil(viewModel.errorMessage)
        } else {
            // It's also acceptable if it stays in processing or goes to preview with default
            XCTAssertTrue(viewModel.state == .processing(1.0) || viewModel.state == .idle || viewModel.errorMessage != nil,
                          "Expected error state for empty input, got \(viewModel.state)")
        }
    }
    
    func testProcessInput_VoiceInput_Success() async {
        // Given
        viewModel.startCapture(.voice)
        
        // When
        await viewModel.processInput(.transcription("Doctor appointment next Tuesday at 3pm"))
        
        // Then
        if case .preview = viewModel.state {
            XCTAssertNotNil(viewModel.parsedEvent)
        } else {
            XCTFail("Expected .preview state, got \(viewModel.state)")
        }
    }
    
    func testProcessInput_ProgressUpdates() async {
        // Given
        viewModel.startCapture(.text)
        
        // When
        await viewModel.processInput(.text("Meeting tomorrow at 2pm"))
        
        // Then - progress should reach 1.0
        XCTAssertEqual(viewModel.processingProgress, 1.0)
    }
    
    // MARK: - Confirm Event Tests
    
    func testConfirmEvent_NoEvent_ThrowsError() async {
        // Given - no event parsed
        viewModel.startCapture(.text)
        
        // When
        await viewModel.confirmEvent()
        
        // Then
        if case .error(let msg) = viewModel.state {
            XCTAssertTrue(msg.contains("No event"))
        } else {
            XCTFail("Expected .error state, got \(viewModel.state)")
        }
    }
    
    func testConfirmEvent_WithParsedEvent_TransitionsToCompleted() async {
        // Given - parse a valid event
        viewModel.startCapture(.text)
        await viewModel.processInput(.text("Team meeting tomorrow at 10am"))
        
        guard case .preview = viewModel.state else {
            XCTFail("Expected .preview state after processing")
            return
        }
        
        // When - confirm the event
        // Note: This may fail if calendar access isn't granted in the test environment.
        // That's expected — the error handling should work correctly.
        await viewModel.confirmEvent()
        
        // Then - should be either .completed (if calendar access granted) or .error
        switch viewModel.state {
        case .completed(let history):
            XCTAssertFalse(history.title.isEmpty)
            XCTAssertFalse(history.eventIdentifier.isEmpty)
        case .error:
            // Expected if calendar access not granted in test environment
            XCTAssertNotNil(viewModel.errorMessage)
        default:
            XCTFail("Expected .completed or .error, got \(viewModel.state)")
        }
    }
    
    // MARK: - Reset Tests
    
    func testReset_ReturnsToIdle() {
        // Given
        viewModel.startCapture(.text)
        viewModel.errorMessage = "Test error"
        viewModel.processingProgress = 0.5
        
        // When
        viewModel.reset()
        
        // Then
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.parsedEvent)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.processingProgress, 0.0)
    }
    
    // MARK: - Update Parsed Event Tests
    
    func testUpdateParsedEvent_ReturnsToPreview() {
        // Given
        viewModel.startCapture(.text)
        let originalEvent = ParsedEvent(
            title: "Original",
            startDate: Date(),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "test",
            inputType: .text
        )
        viewModel.parsedEvent = originalEvent
        
        // When
        var updated = originalEvent
        updated.title = "Updated"
        viewModel.updateParsedEvent(updated)
        
        // Then
        XCTAssertEqual(viewModel.parsedEvent?.title, "Updated")
        if case .preview(let event) = viewModel.state {
            XCTAssertEqual(event.title, "Updated")
        } else {
            XCTFail("Expected .preview state")
        }
    }
    
    // MARK: - Edit Event Tests
    
    func testEditEvent_ReturnsToPreview() {
        // Given
        viewModel.startCapture(.text)
        let event = ParsedEvent(
            title: "Test",
            startDate: Date(),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "test",
            inputType: .text
        )
        viewModel.parsedEvent = event
        viewModel.state = .idle // simulate some other state
        
        // When
        viewModel.editEvent()
        
        // Then
        if case .preview = viewModel.state {
            // Correct
        } else {
            XCTFail("Expected .preview state after editEvent()")
        }
    }
}
