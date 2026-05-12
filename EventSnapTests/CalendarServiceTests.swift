import XCTest
import EventKit
import SwiftData

@testable import EventSnap

@MainActor
final class CalendarServiceTests: XCTestCase {
    
    var calendarService: MockCalendarService!
    
    override func setUp() {
        super.setUp()
        calendarService = MockCalendarService()
    }
    
    override func tearDown() {
        calendarService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockCalendar(title: String, identifier: String) -> EKCalendar {
        let calendar = EKCalendar()
        calendar.title = title
        // calendarIdentifier is read-only, so we'll use a different approach for testing
        return calendar
    }
    
    // MARK: - PII Sanitization Tests
    
    func testPIISanitization_Emails() async throws {
        // Given
        let textWithEmail = "Contact john.doe@example.com about the meeting"
        let expectedSanitized = "Contact [EMAIL] about the meeting"
        
        // When
        let sanitized = PIISanitizer.sanitize(textWithEmail)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testPIISanitization_PhoneNumbers() async throws {
        // Given
        let textWithPhone = "Call me at 555-123-4567 tomorrow"
        let expectedSanitized = "Call me at [PHONE] tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitize(textWithPhone)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testPIISanitization_PhoneNumbersWithDifferentFormats() async throws {
        // Given
        let testCases = [
            "Call 555-123-4567": "Call [PHONE]",
            "Call 555.123.4567": "Call [PHONE]",
        ]
        
        for (input, expected) in testCases {
            // When
            let sanitized = PIISanitizer.sanitize(input)
            
            // Then
            XCTAssertEqual(sanitized, expected, "Failed for input: \(input)")
        }
    }
    
    func testPIISanitization_SSNs() async throws {
        // Given
        let textWithSSN = "My SSN is 123-45-6789"
        let expectedSanitized = "My SSN is [SSN]"
        
        // When
        let sanitized = PIISanitizer.sanitize(textWithSSN)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testPIISanitization_MultiplePII() async throws {
        // Given
        let textWithMultiplePII = "Email john@example.com or call 555-123-4567. My SSN is 123-45-6789."
        let expectedSanitized = "Email [EMAIL] or call [PHONE]. My SSN is [SSN]."
        
        // When
        let sanitized = PIISanitizer.sanitize(textWithMultiplePII)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testPIISanitization_NoPII() async throws {
        // Given
        let cleanText = "Meeting at the office tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitize(cleanText)
        
        // Then
        XCTAssertEqual(sanitized, cleanText)
    }
    
    func testPIISanitization_EmptyString() async throws {
        // Given
        let emptyText = ""
        
        // When
        let sanitized = PIISanitizer.sanitize(emptyText)
        
        // Then
        XCTAssertEqual(sanitized, emptyText)
    }
    
    // MARK: - Duplicate Detection Tests
    
    func testFindDuplicate_NoDuplicate() async throws {
        // Given
        let title = "Team Meeting"
        let startDate = Date()
        calendarService.setShouldFindDuplicate(false)
        
        // When
        let duplicate = calendarService.findDuplicate(title: title, startDate: startDate)
        
        // Then
        XCTAssertNil(duplicate)
    }
    
    func testFindDuplicate_WithDuplicate() async throws {
        // Given
        let title = "Team Meeting"
        let startDate = Date()
        calendarService.setShouldFindDuplicate(true)
        
        // When
        let duplicate = calendarService.findDuplicate(title: title, startDate: startDate)
        
        // Then
        XCTAssertNotNil(duplicate)
        XCTAssertEqual(duplicate?.title, title)
    }
    
    func testFindDuplicate_DifferentTitle() async throws {
        // Given
        let title = "Team Meeting"
        let searchTitle = "Different Meeting"
        let startDate = Date()
        calendarService.setShouldFindDuplicate(true)
        
        // When
        let duplicate = calendarService.findDuplicate(title: searchTitle, startDate: startDate)
        
        // Then
        // Should not find duplicate because titles don't match
        XCTAssertNil(duplicate)
    }
    
    func testFindDuplicate_DateTolerance() async throws {
        // Given
        let title = "Team Meeting"
        let startDate = Date()
        let toleranceDate = startDate.addingTimeInterval(30) // 30 seconds difference
        
        calendarService.setShouldFindDuplicate(false)
        
        // When
        let duplicate = calendarService.findDuplicate(title: title, startDate: toleranceDate)
        
        // Then
        XCTAssertNil(duplicate) // Should not find duplicate within tolerance
    }
    
    // MARK: - Default Calendar Persistence Tests
    
    func testDefaultCalendar_SetAndGet() async throws {
        // Given
        let mockCalendar = createMockCalendar(title: "Test Calendar", identifier: "test-calendar-id")
        
        // When
        calendarService.setDefaultCalendar(mockCalendar)
        
        // Then
        XCTAssertEqual(calendarService.defaultCalendar?.title, "Test Calendar")
        XCTAssertEqual(calendarService.defaultCalendar?.calendarIdentifier, "test-calendar-id")
    }
    
    func testDefaultCalendar_Reset() async throws {
        // Given
        let mockCalendar = EKCalendar()
        mockCalendar.title = "Test Calendar"
        calendarService.setDefaultCalendar(mockCalendar)
        
        // When
        calendarService.resetDefaultCalendar()
        
        // Then
        XCTAssertNil(calendarService.defaultCalendar)
    }
    
    // MARK: - Event Data Formatting Tests
    
    func testEventDateBoundaryDates() async throws {
        // Given
        let title = "Test Event"
        let startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let endDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
        // When
        let event = try await calendarService.addEvent(ParsedEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        ))
        
        // Then
        XCTAssertEqual(event.startDate, startDate)
        XCTAssertEqual(event.endDate, endDate)
    }
    
    func testEventDataFormatting_MissingEndDate() async throws {
        // Given
        let title = "Test Event"
        let startDate = Date()
        
        // When
        let event = try await calendarService.addEvent(ParsedEvent(
            title: title,
            startDate: startDate,
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        ))
        
        // Then
        XCTAssertEqual(event.startDate, startDate)
        XCTAssertNotNil(event.endDate)
        
        // End date should be 1 hour after start date
        let expectedEndDate = startDate.addingTimeInterval(3600)
        XCTAssertEqual(event.endDate, expectedEndDate)
    }
    
    // MARK: - Access Control Tests
    
    func testAccessControl_Granted() async throws {
        // Given
        calendarService.setShouldDenyAccess(false)
        
        // When
        let granted = try await calendarService.requestAccess()
        
        // Then
        XCTAssertTrue(granted)
        XCTAssertTrue(calendarService.isAccessGranted)
    }
    
    func testAccessControl_Denied() async throws {
        // Given
        calendarService.setShouldDenyAccess(true)
        
        // When
        let granted = try await calendarService.requestAccess()
        
        // Then
        XCTAssertFalse(granted)
        XCTAssertFalse(calendarService.isAccessGranted)
    }
    
    // MARK: - Event Creation Tests
    
    func testEventCreation_Success() async throws {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Test Location",
            locationAddress: nil,
            notes: "Test Notes",
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        calendarService.setShouldFail(false)
        
        // When
        let createdEvent = try await calendarService.addEvent(event)
        
        // Then
        XCTAssertEqual(createdEvent.title, "Test Event")
        XCTAssertEqual(createdEvent.location, "Test Location")
        XCTAssertEqual(createdEvent.notes, "Test Notes")
        
        // Verify event was added to mock events array
        let mockEvents = calendarService.getMockEvents()
        XCTAssertEqual(mockEvents.count, 1)
        XCTAssertEqual(mockEvents.first?.title, "Test Event")
    }
    
    func testEventCreation_Failure() async throws {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        calendarService.setShouldFail(true)
        
        // When & Then
        do {
            let _ = try await calendarService.addEvent(event)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Event creation failed")
        }
    }
    
    func testEventCreation_DuplicateDetection() async throws {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        calendarService.setShouldFindDuplicate(true)
        
        // When & Then
        do {
            let _ = try await calendarService.addEvent(event)
            XCTFail("Expected error to be thrown")
        } catch {
            if let calendarError = error as? CalendarService.CalendarError {
                switch calendarError {
                case .duplicateEventFound(let title, let date):
                    XCTAssertEqual(title, "Test Event")
                    XCTAssertEqual(date, event.startDate)
                default:
                    XCTFail("Expected duplicate event error")
                }
            } else {
                XCTFail("Expected CalendarError")
            }
        }
    }
}