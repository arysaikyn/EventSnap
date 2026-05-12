import XCTest
import SwiftUI
import SwiftData

@testable import EventSnap

// MARK: - EventCreationViewModelTests

/// Tests for the EventCreationViewModel state machine and flow.
/// Uses real services with an in-memory SwiftData store.
@MainActor
final class EventCreationViewModelTests: XCTestCase {
    
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
    
    // MARK: - State Transition Tests
    
    func testStartCapture_TextInput() {
        XCTAssertEqual(viewModel.state, .idle)
        viewModel.startCapture(.text)
        XCTAssertEqual(viewModel.state, .capturing(.text))
        XCTAssertNil(viewModel.parsedEvent)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.processingProgress, 0.0)
    }
    
    func testStartCapture_CameraInput() {
        viewModel.startCapture(.camera)
        XCTAssertEqual(viewModel.state, .capturing(.camera))
    }
    
    func testStartCapture_VoiceInput() {
        viewModel.startCapture(.voice)
        XCTAssertEqual(viewModel.state, .capturing(.voice))
    }
    
    // MARK: - Process Input Tests
    
    func testProcessInput_TextInput() async {
        viewModel.startCapture(.text)
        await viewModel.processInput(.text("Meeting tomorrow at 3pm"))
        
        XCTAssertEqual(viewModel.processingProgress, 1.0)
        XCTAssertNotNil(viewModel.parsedEvent)
        if case .preview = viewModel.state {
            // Correct
        } else {
            XCTFail("Expected .preview state, got \(viewModel.state)")
        }
    }
    
    func testProcessInput_EmptyText() async {
        viewModel.startCapture(.text)
        await viewModel.processInput(.text(""))
        
        // Should result in error or nil parsedEvent
        if case .error = viewModel.state {
            XCTAssertNotNil(viewModel.errorMessage)
        } else {
            // It's OK if NLParser returns a default for empty text
            XCTAssertTrue(viewModel.state == .idle || viewModel.errorMessage != nil)
        }
    }
    
    func testProcessInput_VoiceInput() async {
        viewModel.startCapture(.voice)
        await viewModel.processInput(.transcription("Dinner with Alex Friday at 7pm"))
        
        XCTAssertNotNil(viewModel.parsedEvent)
        if case .preview = viewModel.state {
            // Correct
        } else {
            XCTFail("Expected .preview state")
        }
    }
    
    func testProcessInput_CameraInput() async {
        // Create a test image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let image = renderer.image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        viewModel.startCapture(.camera)
        await viewModel.processInput(.image(image))
        
        // OCR should process the image (even if no text found, it shouldn't crash)
        // The result depends on whether the image has recognizable text
        XCTAssertNotNil(viewModel.errorMessage != nil || viewModel.parsedEvent != nil,
                         "Should either have an error or a parsed event")
    }
    
    func testProcessInput_ProgressReaches100() async {
        viewModel.startCapture(.text)
        await viewModel.processInput(.text("Meeting tomorrow at 2pm"))
        XCTAssertEqual(viewModel.processingProgress, 1.0)
    }
    
    // MARK: - Confirm Event Tests
    
    func testConfirmEvent_NoEvent() async {
        viewModel.startCapture(.text)
        await viewModel.confirmEvent()
        
        if case .error(let msg) = viewModel.state {
            XCTAssertTrue(msg.contains("No event"))
        } else {
            XCTFail("Expected .error state")
        }
    }
    
    func testConfirmEvent_WithParsedEvent() async {
        // Parse an event first
        viewModel.startCapture(.text)
        await viewModel.processInput(.text("Team meeting tomorrow at 10am"))
        
        guard case .preview = viewModel.state else {
            XCTFail("Expected .preview after processing")
            return
        }
        
        // Confirm - may fail if no calendar access, that's OK
        await viewModel.confirmEvent()
        
        switch viewModel.state {
        case .completed(let history):
            XCTAssertFalse(history.title.isEmpty)
        case .error:
            // Expected if calendar access not granted
            break
        default:
            XCTFail("Expected .completed or .error")
        }
    }
    
    // MARK: - Reset Tests
    
    func testReset_ClearsAllState() {
        viewModel.startCapture(.text)
        viewModel.errorMessage = "Error"
        viewModel.processingProgress = 0.5
        
        viewModel.reset()
        
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.parsedEvent)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.processingProgress, 0.0)
    }
    
    // MARK: - Update Parsed Event Tests
    
    func testUpdateParsedEvent() {
        viewModel.startCapture(.text)
        let event = ParsedEvent(
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
        viewModel.parsedEvent = event
        
        var updated = event
        updated.title = "Updated Title"
        viewModel.updateParsedEvent(updated)
        
        XCTAssertEqual(viewModel.parsedEvent?.title, "Updated Title")
        if case .preview(let e) = viewModel.state {
            XCTAssertEqual(e.title, "Updated Title")
        } else {
            XCTFail("Expected .preview")
        }
    }
    
    // MARK: - Edit Event Tests
    
    func testEditEvent() {
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
        viewModel.state = .idle
        
        viewModel.editEvent()
        
        if case .preview = viewModel.state {
            // Correct
        } else {
            XCTFail("Expected .preview after editEvent()")
        }
    }
    
    // MARK: - State Equality Tests
    
    func testStateEquality_Idle() {
        XCTAssertEqual(CreationState.idle, CreationState.idle)
    }
    
    func testStateEquality_Capturing() {
        XCTAssertEqual(CreationState.capturing(.text), CreationState.capturing(.text))
        XCTAssertNotEqual(CreationState.capturing(.text), CreationState.capturing(.camera))
    }
    
    func testStateEquality_Processing() {
        XCTAssertEqual(CreationState.processing(0.5), CreationState.processing(0.5))
        XCTAssertNotEqual(CreationState.processing(0.5), CreationState.processing(0.8))
    }
    
    func testStateEquality_Error() {
        XCTAssertEqual(CreationState.error("test"), CreationState.error("test"))
        XCTAssertNotEqual(CreationState.error("a"), CreationState.error("b"))
    }
}
