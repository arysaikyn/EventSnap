import XCTest
import EventKit

@testable import EventSnap

// MARK: - ParsedEventTests

final class ParsedEventTests: XCTestCase {
    
    // MARK: - Test Cases
    
    func testParsedEventCreation() {
        // Given
        let id = UUID()
        let title = "Test Event"
        let startDate = Date()
        let endDate = Date().addingTimeInterval(3600)
        let location = "Test Location"
        let locationAddress = "123 Test St"
        let notes = "Test Notes"
        let calendar = EKCalendar()
        let confidence: Double = 0.85
        let uncertainFields: Set<EventField> = [.time]
        let sourceText = "Test event text"
        let inputType = InputType.text
        
        // When
        let event = ParsedEvent(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            locationAddress: locationAddress,
            notes: notes,
            calendar: calendar,
            confidence: confidence,
            uncertainFields: uncertainFields,
            sourceText: sourceText,
            inputType: inputType
        )
        
        // Then
        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.title, title)
        XCTAssertEqual(event.startDate, startDate)
        XCTAssertEqual(event.endDate, endDate)
        XCTAssertEqual(event.location, location)
        XCTAssertEqual(event.locationAddress, locationAddress)
        XCTAssertEqual(event.notes, notes)
        XCTAssertEqual(event.calendar, calendar)
        XCTAssertEqual(event.confidence, confidence)
        XCTAssertEqual(event.uncertainFields, uncertainFields)
        XCTAssertEqual(event.sourceText, sourceText)
        XCTAssertEqual(event.inputType, inputType)
    }
    
    func testParsedEventDefaultValues() {
        // When
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertNotNil(event.id)
        XCTAssertEqual(event.title, "Test Event")
        XCTAssertEqual(event.endDate, nil)
        XCTAssertEqual(event.location, nil)
        XCTAssertEqual(event.locationAddress, nil)
        XCTAssertEqual(event.notes, nil)
        XCTAssertEqual(event.calendar, nil)
        XCTAssertEqual(event.confidence, 0.8)
        XCTAssertEqual(event.uncertainFields, [])
        XCTAssertEqual(event.sourceText, "Test event")
        XCTAssertEqual(event.inputType, .text)
    }
    
    func testIsReadyForCalendar_WithValidData() {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertTrue(event.isReadyForCalendar)
    }
    
    func testIsReadyForCalendar_EmptyTitle() {
        // Given
        let event = ParsedEvent(
            title: "   ",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.isReadyForCalendar)
    }
    
    func testIsReadyForCalendar_LowConfidence() {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.2,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.isReadyForCalendar)
    }
    
    func testIsReadyForCalendar_EmptyTitleAndLowConfidence() {
        // Given
        let event = ParsedEvent(
            title: "   ",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.2,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.isReadyForCalendar)
    }
    
    func testConfidencePercent() {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.857,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertEqual(event.confidencePercent, 86) // Should round to nearest integer
    }
    
    func testConfidencePercent_Zero() {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.0,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertEqual(event.confidencePercent, 0)
    }
    
    func testConfidencePercent_One() {
        // Given
        let event = ParsedEvent(
            title: "Test Event",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 1.0,
            uncertainFields: [],
            sourceText: "Test event",
            inputType: .text
        )
        
        // Then
        XCTAssertEqual(event.confidencePercent, 100)
    }
    
    func testSummary_WithAllFields() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        // The app's summary format: "Title · EEE, MMM d · h:mm a · 📍 Location"
        let appFormatter = DateFormatter()
        appFormatter.dateFormat = "EEE, MMM d"
        appFormatter.locale = Locale.current
        let dateStr = appFormatter.string(from: event.startDate)
        
        appFormatter.dateFormat = "h:mm a"
        let timeStr = appFormatter.string(from: event.startDate)
        
        let expectedSummary = "Team Meeting · \(dateStr) · \(timeStr) · 📍 Conference Room A"
        XCTAssertEqual(event.summary, expectedSummary)
    }
    
    func testSummary_WithoutLocation() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        let appFormatter = DateFormatter()
        appFormatter.dateFormat = "EEE, MMM d"
        appFormatter.locale = Locale.current
        let dateStr = appFormatter.string(from: event.startDate)
        
        appFormatter.dateFormat = "h:mm a"
        let timeStr = appFormatter.string(from: event.startDate)
        
        let expectedSummary = "Team Meeting · \(dateStr) · \(timeStr)"
        XCTAssertEqual(event.summary, expectedSummary)
    }
    
    func testSummary_WithEmptyTitle() {
        // Given
        let event = ParsedEvent(
            title: "   ",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        let appFormatter = DateFormatter()
        appFormatter.dateFormat = "EEE, MMM d"
        appFormatter.locale = Locale.current
        let dateStr = appFormatter.string(from: event.startDate)
        
        appFormatter.dateFormat = "h:mm a"
        let timeStr = appFormatter.string(from: event.startDate)
        
        let expectedSummary = "   · \(dateStr) · \(timeStr) · 📍 Conference Room A"
        XCTAssertEqual(event.summary, expectedSummary)
    }
    
    // MARK: - EKEvent Conversion Tests
    
    func testMakeEKEvent_WithAllFields() {
        // Given
        let eventStore = EKEventStore()
        let calendar = createMockCalendar(title: "Test Calendar", identifier: "test-calendar-id")
        
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            locationAddress: "123 Main St",
            notes: "Discuss project updates",
            calendar: calendar,
            confidence: 0.9,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        XCTAssertEqual(ekEvent.title, "Team Meeting")
        XCTAssertEqual(ekEvent.startDate, event.startDate)
        XCTAssertEqual(ekEvent.endDate, event.endDate)
        // makeEKEvent uses location ?? locationAddress, so location takes priority
        XCTAssertEqual(ekEvent.location, "Conference Room A")
        // buildNotes includes notes + "\n\n—\nAdded via EventSnap (text)"
        let expectedNotes = "Discuss project updates\n\n—\nAdded via EventSnap (text)"
        XCTAssertEqual(ekEvent.notes, expectedNotes)
        XCTAssertEqual(ekEvent.calendar, calendar)
        XCTAssertEqual(ekEvent.availability, .busy) // confidence 0.9 >= 0.7
    }
    
    func testMakeEKEvent_WithoutEndDate() {
        // Given
        let eventStore = EKEventStore()
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        XCTAssertEqual(ekEvent.title, "Team Meeting")
        XCTAssertEqual(ekEvent.startDate, event.startDate)
        XCTAssertNotNil(ekEvent.endDate)
        XCTAssertEqual(ekEvent.endDate, event.startDate.addingTimeInterval(3600))
    }
    
    func testMakeEKEvent_WithoutNotes() {
        // Given
        let eventStore = EKEventStore()
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        XCTAssertEqual(ekEvent.title, "Team Meeting")
        XCTAssertEqual(ekEvent.startDate, event.startDate)
        XCTAssertEqual(ekEvent.endDate, event.endDate)
        XCTAssertNil(ekEvent.location)
        // buildNotes with nil notes produces: "\n—\nAdded via EventSnap (text)"
        let expectedNotes = "\n—\nAdded via EventSnap (text)"
        XCTAssertEqual(ekEvent.notes, expectedNotes)
    }
    
    func testMakeEKEvent_WithoutLocation() {
        // Given
        let eventStore = EKEventStore()
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: "123 Main St",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        // makeEKEvent uses location ?? locationAddress, so since location is nil,
        // it falls back to locationAddress
        XCTAssertEqual(ekEvent.location, "123 Main St")
        let expectedNotes = "Discuss project updates\n\n—\nAdded via EventSnap (text)"
        XCTAssertEqual(ekEvent.notes, expectedNotes)
    }
    
    func testMakeEKEvent_LowConfidence() {
        // Given
        let eventStore = EKEventStore()
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.5,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        XCTAssertEqual(ekEvent.availability, .free) // confidence 0.5 < 0.7
    }
    
    func testMakeEKEvent_HighConfidence() {
        // Given
        let eventStore = EKEventStore()
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        XCTAssertEqual(ekEvent.availability, .busy) // confidence 0.8 >= 0.7
    }
    
    func testMakeEKEvent_DefaultCalendar() {
        // Given
        let eventStore = EKEventStore()
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let ekEvent = event.makeEKEvent(in: eventStore)
        
        // Then
        XCTAssertEqual(ekEvent.calendar, eventStore.defaultCalendarForNewEvents)
    }
    
    // MARK: - Codable Tests
    
    func testParsedEvent_EncodeDecode() {
        // Given
        let originalEvent = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            locationAddress: "123 Main St",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.85,
            uncertainFields: [.time],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let encodedData = try! JSONEncoder().encode(originalEvent)
        let decodedEvent = try! JSONDecoder().decode(ParsedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedEvent.title, originalEvent.title)
        XCTAssertEqual(decodedEvent.startDate, originalEvent.startDate)
        XCTAssertEqual(decodedEvent.endDate, originalEvent.endDate)
        XCTAssertEqual(decodedEvent.location, originalEvent.location)
        XCTAssertEqual(decodedEvent.locationAddress, originalEvent.locationAddress)
        XCTAssertEqual(decodedEvent.notes, originalEvent.notes)
        XCTAssertEqual(decodedEvent.confidence, originalEvent.confidence)
        XCTAssertEqual(decodedEvent.uncertainFields, originalEvent.uncertainFields)
        XCTAssertEqual(decodedEvent.sourceText, originalEvent.sourceText)
        XCTAssertEqual(decodedEvent.inputType, originalEvent.inputType)
    }
    
    func testParsedEvent_EncodeDecode_WithCalendar() {
        // Given
        let calendar = createMockCalendar(title: "Test Calendar", identifier: "test-calendar-id")
        
        let originalEvent = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            locationAddress: "123 Main St",
            notes: "Discuss project updates",
            calendar: calendar,
            confidence: 0.85,
            uncertainFields: [.time],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let encodedData = try! JSONEncoder().encode(originalEvent)
        let decodedEvent = try! JSONDecoder().decode(ParsedEvent.self, from: encodedData)
        
        // Then
        // Note: EKCalendar is not Codable, so this will be nil after decode
        XCTAssertNil(decodedEvent.calendar)
        XCTAssertEqual(decodedEvent.title, originalEvent.title)
        XCTAssertEqual(decodedEvent.startDate, originalEvent.startDate)
        XCTAssertEqual(decodedEvent.endDate, originalEvent.endDate)
        XCTAssertEqual(decodedEvent.location, originalEvent.location)
        XCTAssertEqual(decodedEvent.locationAddress, originalEvent.locationAddress)
        XCTAssertEqual(decodedEvent.notes, originalEvent.notes)
        XCTAssertEqual(decodedEvent.confidence, originalEvent.confidence)
        XCTAssertEqual(decodedEvent.uncertainFields, originalEvent.uncertainFields)
        XCTAssertEqual(decodedEvent.sourceText, originalEvent.sourceText)
        XCTAssertEqual(decodedEvent.inputType, originalEvent.inputType)
    }
    
    func testParsedEvent_EncodeDecode_EmptyFields() {
        // Given
        let originalEvent = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: nil,
            location: nil,
            locationAddress: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.8,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // When
        let encodedData = try! JSONEncoder().encode(originalEvent)
        let decodedEvent = try! JSONDecoder().decode(ParsedEvent.self, from: encodedData)
        
        // Then
        XCTAssertEqual(decodedEvent.title, originalEvent.title)
        XCTAssertEqual(decodedEvent.startDate, originalEvent.startDate)
        XCTAssertNil(decodedEvent.endDate)
        XCTAssertNil(decodedEvent.location)
        XCTAssertNil(decodedEvent.locationAddress)
        XCTAssertNil(decodedEvent.notes)
        XCTAssertNil(decodedEvent.calendar)
        XCTAssertEqual(decodedEvent.confidence, originalEvent.confidence)
        XCTAssertEqual(decodedEvent.uncertainFields, originalEvent.uncertainFields)
        XCTAssertEqual(decodedEvent.sourceText, originalEvent.sourceText)
        XCTAssertEqual(decodedEvent.inputType, originalEvent.inputType)
    }
    
    // MARK: - Uncertain Fields Tests
    
    func testUncertainFields_NoUncertainty() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.uncertainFields.contains(.title))
        XCTAssertFalse(event.uncertainFields.contains(.date))
        XCTAssertFalse(event.uncertainFields.contains(.time))
        XCTAssertFalse(event.uncertainFields.contains(.location))
        XCTAssertFalse(event.uncertainFields.contains(.notes))
    }
    
    func testUncertainFields_TitleUncertain() {
        // Given
        let event = ParsedEvent(
            title: "",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [.title],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertTrue(event.uncertainFields.contains(.title))
        XCTAssertFalse(event.uncertainFields.contains(.date))
        XCTAssertFalse(event.uncertainFields.contains(.time))
        XCTAssertFalse(event.uncertainFields.contains(.location))
        XCTAssertFalse(event.uncertainFields.contains(.notes))
    }
    
    func testUncertainFields_DateUncertain() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [.date],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.uncertainFields.contains(.title))
        XCTAssertTrue(event.uncertainFields.contains(.date))
        XCTAssertFalse(event.uncertainFields.contains(.time))
        XCTAssertFalse(event.uncertainFields.contains(.location))
        XCTAssertFalse(event.uncertainFields.contains(.notes))
    }
    
    func testUncertainFields_TimeUncertain() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [.time],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.uncertainFields.contains(.title))
        XCTAssertFalse(event.uncertainFields.contains(.date))
        XCTAssertTrue(event.uncertainFields.contains(.time))
        XCTAssertFalse(event.uncertainFields.contains(.location))
        XCTAssertFalse(event.uncertainFields.contains(.notes))
    }
    
    func testUncertainFields_LocationUncertain() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: "Discuss project updates",
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [.location],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.uncertainFields.contains(.title))
        XCTAssertFalse(event.uncertainFields.contains(.date))
        XCTAssertFalse(event.uncertainFields.contains(.time))
        XCTAssertTrue(event.uncertainFields.contains(.location))
        XCTAssertFalse(event.uncertainFields.contains(.notes))
    }
    
    func testUncertainFields_NotesUncertain() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            notes: nil,
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [.notes],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.uncertainFields.contains(.title))
        XCTAssertFalse(event.uncertainFields.contains(.date))
        XCTAssertFalse(event.uncertainFields.contains(.time))
        XCTAssertFalse(event.uncertainFields.contains(.location))
        XCTAssertTrue(event.uncertainFields.contains(.notes))
    }
    
    func testUncertainFields_MultipleUncertain() {
        // Given
        let event = ParsedEvent(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: nil,
            notes: nil,
            calendar: nil,
            confidence: 0.9,
            uncertainFields: [.location, .notes],
            sourceText: "Team meeting",
            inputType: .text
        )
        
        // Then
        XCTAssertFalse(event.uncertainFields.contains(.title))
        XCTAssertFalse(event.uncertainFields.contains(.date))
        XCTAssertFalse(event.uncertainFields.contains(.time))
        XCTAssertTrue(event.uncertainFields.contains(.location))
        XCTAssertTrue(event.uncertainFields.contains(.notes))
    }
    
    // MARK: - Helper Methods
    
    private func createMockCalendar(title: String, identifier: String) -> EKCalendar {
        let calendar = EKCalendar()
        calendar.title = title
        // calendarIdentifier is read-only, so we'll use a different approach for testing
        return calendar
    }
}