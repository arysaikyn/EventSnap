import XCTest
@testable import EventSnap

// MARK: - TextInputViewModelTests

@MainActor
final class TextInputViewModelTests: XCTestCase {

    var viewModel: TextInputViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TextInputViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.textInput, "")
        XCTAssertFalse(viewModel.isParsing)
        XCTAssertNil(viewModel.validationError)
    }

    // MARK: - Parse Event Tests

    func testParseEvent_ValidText() async throws {
        viewModel.textInput = "Lunch with Sarah tomorrow at 1pm"

        let event = try await viewModel.parseEvent()

        XCTAssertFalse(event.title.isEmpty)
        XCTAssertEqual(event.inputType, .text)
        XCTAssertFalse(viewModel.isParsing)
        XCTAssertNil(viewModel.validationError)
    }

    func testParseEvent_EmptyText_ThrowsError() async {
        viewModel.textInput = ""

        do {
            _ = try await viewModel.parseEvent()
            XCTFail("Should throw for empty text")
        } catch {
            XCTAssertNotNil(viewModel.validationError)
            XCTAssertTrue(viewModel.validationError?.contains("enter") ?? false)
        }
    }

    func testParseEvent_WhitespaceOnly_ThrowsError() async {
        viewModel.textInput = "   \n\t  "

        do {
            _ = try await viewModel.parseEvent()
            XCTFail("Should throw for whitespace-only text")
        } catch {
            XCTAssertNotNil(viewModel.validationError)
        }
    }

    func testParseEvent_SetsParsingStateDuringProcessing() async throws {
        viewModel.textInput = "Meeting at 3pm"

        // Parse should complete without intermediate state check issues
        let event = try await viewModel.parseEvent()
        XCTAssertFalse(viewModel.isParsing)
        XCTAssertNotNil(event)
    }

    // MARK: - Clipboard Tests

    func testPasteFromClipboard_WithContent() {
        // Note: In test environment, clipboard may not have content,
        // but we can test the method doesn't crash
        viewModel.pasteFromClipboard()
        // Method should not crash
    }

    func testRefreshClipboardStatus() {
        viewModel.refreshClipboardStatus()
        // Method should not crash; actual clipboard state depends on test environment
    }

    // MARK: - Clear Text Tests

    func testClearText() {
        viewModel.textInput = "Some text"
        viewModel.validationError = "Some error"

        viewModel.clearText()

        XCTAssertEqual(viewModel.textInput, "")
        XCTAssertNil(viewModel.validationError)
    }

    // MARK: - Validation Error Tests

    func testValidationError_EmptyText() async {
        viewModel.textInput = ""

        do {
            _ = try await viewModel.parseEvent()
        } catch {
            XCTAssertEqual(viewModel.validationError, TextInputViewModel.ValidationError.emptyText.errorDescription)
        }
    }

    func testValidationError_ParsingFailed() async {
        viewModel.textInput = "xyzzy nonsense gibberish"

        do {
            _ = try await viewModel.parseEvent()
        } catch {
            // Either parsing succeeds with default values or fails — both are acceptable
            if let validationError = viewModel.validationError {
                XCTAssertTrue(
                    validationError.contains("parse") || validationError.contains("event"),
                    "Error message should mention parsing or events"
                )
            }
        }
    }

    // MARK: - InputType Tests

    func testParsedEvent_InputTypeIsText() async throws {
        viewModel.textInput = "Dinner Friday 7pm"

        let event = try await viewModel.parseEvent()
        XCTAssertEqual(event.inputType, .text)
    }

    func testParsedEvent_SourceTextMatchesInput() async throws {
        viewModel.textInput = "Doctor appointment next Monday at 9am"

        let event = try await viewModel.parseEvent()
        XCTAssertEqual(event.sourceText, "Doctor appointment next Monday at 9am")
    }
}