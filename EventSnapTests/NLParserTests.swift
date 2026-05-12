import XCTest

@testable import EventSnap

// MARK: - NLParserTests

final class NLParserTests: XCTestCase {
    
    // MARK: - Test Cases
    
    func testParseBasicEventWithTimeAndLocation() async throws {
        // Given
        let text = "Dinner with Sarah tomorrow at 7pm at The Italian Place"
        let inputType = InputType.text
        
        // When
        let result = NLParser.parse(text, inputType: inputType)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Dinner with Sarah")
        XCTAssertNotNil(result?.location)
        XCTAssertEqual(result?.location, "The Italian Place")
        XCTAssertNotNil(result?.sourceText)
        XCTAssertEqual(result?.inputType, inputType)
        XCTAssertGreaterThan(result?.confidence ?? 0, 0.5)
    }
    
    func testParseTodayAndTomorrow() async throws {
        // Given
        let todayText = "Meeting today at 3pm"
        let tomorrowText = "Coffee tomorrow morning"
        
        // When
        let todayResult = NLParser.parse(todayText, inputType: .text)
        let tomorrowResult = NLParser.parse(tomorrowText, inputType: .text)
        
        // Then
        XCTAssertNotNil(todayResult)
        XCTAssertNotNil(tomorrowResult)
        XCTAssertEqual(todayResult?.title, "Meeting")
        // Note: "morning" is not consumed as a time span (requires "in the morning"),
        // so it remains in the title text
        XCTAssertEqual(tomorrowResult?.title, "Coffee morning")
        
        // Verify dates are different (today vs tomorrow)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        XCTAssertNotNil(todayResult?.startDate)
        XCTAssertNotNil(tomorrowResult?.startDate)
        
        // Check that tomorrow result is actually tomorrow
        let daysDiff = calendar.dateComponents([.day], from: todayResult!.startDate, to: tomorrowResult!.startDate).day
        XCTAssertEqual(daysDiff, 1)
    }
    
    func testParseNextWeekday() async throws {
        // Given
        let text = "Lunch next Thursday at noon"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Lunch")
        XCTAssertNil(result?.location) // "noon" is parsed as time, not location
        
        // Verify it's actually next Thursday (not today or last Thursday)
        let calendar = Calendar.current
        let thursday = calendar.dateComponents([.weekday], from: result!.startDate).weekday
        XCTAssertEqual(thursday, 5) // Thursday
    }
    
    func testParseInXDays() async throws {
        // Given
        let text = "Doctor appointment in 3 days at 2:30 PM"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Doctor appointment")
        XCTAssertNil(result?.location) // "2:30 PM" is parsed as time, not location
        
        // Verify it's actually 3 days from now
        let calendar = Calendar.current
        let now = Date()
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: now)!
        
        // Should be close to 3 days from now (within 24 hours)
        let daysDiff = calendar.dateComponents([.day], from: now, to: result!.startDate).day
        XCTAssertEqual(daysDiff, 3)
    }
    
    func testParse12HourTime() async throws {
        // Given
        let testCases = [
            ("Brunch at 10am", "10am"),
            ("Dinner at 7pm", "7pm"),
            ("Meeting at 12:30pm", "12:30pm")
        ]
        
        for (text, expectedTime) in testCases {
            // When
            let result = NLParser.parse(text, inputType: .text)
            
            // Then
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result?.title, text.replacingOccurrences(of: " at \(expectedTime)", with: ""))
        }
    }
    
    func testParse24HourTime() async throws {
        // Given
        let testCases = [
            ("Meeting at 14:00", "14:00"),
            ("Flight at 09:30", "09:30")
        ]
        
        for (text, expectedTime) in testCases {
            // When
            let result = NLParser.parse(text, inputType: .text)
            
            // Then
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result?.title, text.replacingOccurrences(of: " at \(expectedTime)", with: ""))
        }
    }
    
    func testParseTimeWords() async throws {
        // Given
        let testCases = [
            ("Meeting at noon", "noon"),
            ("midnight deadline", "midnight"),
        ]
        
        for (text, expectedTime) in testCases {
            // When
            let result = NLParser.parse(text, inputType: .text)
            
            // Then
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result?.title, text.replacingOccurrences(of: " at \(expectedTime)", with: "").replacingOccurrences(of: " \(expectedTime)", with: ""))
        }
    }
    
    func testParseDuration() async throws {
        // Given
        let text = "Yoga today for 1 hour"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Yoga")
        
        // Should have end date calculated based on duration
        XCTAssertNotNil(result?.endDate)
        let duration = result?.endDate?.timeIntervalSince(result?.startDate ?? Date()) ?? 0
        XCTAssertEqual(duration, 3600) // 1 hour in seconds
    }
    
    func testParseTimeRange() async throws {
        // Given
        let text = "Meeting at 2pm for 1 hour"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Meeting")
        XCTAssertNotNil(result?.endDate)
        
        // End date should be 1 hour after start date
        let duration = result!.endDate!.timeIntervalSince(result!.startDate)
        XCTAssertEqual(duration, 3600, accuracy: 1)
    }
    
    func testParseLocationExtraction() async throws {
        // Given
        let testCases = [
            ("Coffee at Starbucks", "Starbucks"),
        ]
        
        for (text, expectedLocation) in testCases {
            // When
            let result = NLParser.parse(text, inputType: .text)
            
            // Then
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result?.title, text.replacingOccurrences(of: " at \(expectedLocation)", with: ""))
            XCTAssertEqual(result?.location, expectedLocation)
        }
    }
    
    func testParseNotesExtraction() async throws {
        // Given
        let text = "Standup every weekday"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Standup")
        XCTAssertEqual(result?.notes, "Recurrence: every weekday")
    }
    
    func testParseRecurringEvents() async throws {
        // Given
        let testCases = [
            ("Standup every weekday", "every weekday"),
            ("Lunch every Monday", "every Monday"),
            ("Gym every day", "every day")
        ]
        
        for (text, expectedRecurrence) in testCases {
            // When
            let result = NLParser.parse(text, inputType: .text)
            
            // Then
            XCTAssertNotNil(result, "Failed to parse: \(text)")
            XCTAssertEqual(result?.notes, "Recurrence: \(expectedRecurrence)")
        }
    }
    
    func testParseAmbiguousDates() async throws {
        // Given
        let text = "Meeting next Thursday"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Meeting")
        
        // Verify it resolves to the upcoming Thursday (never in the past)
        let calendar = Calendar.current
        let now = Date()
        let thursday = calendar.dateComponents([.weekday], from: result!.startDate).weekday
        XCTAssertEqual(thursday, 5) // Thursday
        
        // Should be in the future or today
        XCTAssertGreaterThanOrEqual(result!.startDate, calendar.startOfDay(for: now))
    }
    
    func testParseMixedFormats() async throws {
        // Given
        let text = "Team meeting next Tuesday at Grand Central at 2pm for 1 hour"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Team meeting")
        XCTAssertEqual(result?.location, "Grand Central")
        XCTAssertNotNil(result?.endDate)
        
        // Verify time
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let time = formatter.string(from: result!.startDate)
        XCTAssert(time.contains("2:"))
    }
    
    func testParseEmptyAndEdgeCases() async throws {
        // Given
        let testCases = [
            ("", "Empty string should return nil"),
            ("   ", "Whitespace should return nil"),
            ("gibberish text", "Gibberish should return nil")
        ]
        
        for (text, description) in testCases {
            // When
            let result = NLParser.parse(text, inputType: .text)
            
            // Then
            XCTAssertNil(result, "\(description): \(text)")
        }
    }
    
    func testParseConfidenceScoring() async throws {
        // Given
        let clearText = "Team meeting tomorrow at 3pm at conference room"
        let ambiguousText = "something"
        
        // When
        let clearResult = NLParser.parse(clearText, inputType: .text)
        let ambiguousResult = NLParser.parse(ambiguousText, inputType: .text)
        
        // Then
        XCTAssertNotNil(clearResult)
        XCTAssertNotNil(ambiguousResult)
        
        // Clear input should have higher confidence
        XCTAssertGreaterThan(clearResult!.confidence, ambiguousResult!.confidence)
        
        // Both should have confidence between 0 and 1
        XCTAssertGreaterThanOrEqual(clearResult!.confidence, 0.0)
        XCTAssertLessThanOrEqual(clearResult!.confidence, 1.0)
        XCTAssertGreaterThanOrEqual(ambiguousResult!.confidence, 0.0)
        XCTAssertLessThanOrEqual(ambiguousResult!.confidence, 1.0)
    }
    
    func testParsePIISanitization() async throws {
        // Given
        let text = "Contact john@example.com or call 555-123-4567"
        
        // When
        let result = NLParser.parse(text, inputType: .text)
        
        // Then
        XCTAssertNotNil(result)
        // PII should be sanitized in the title
        XCTAssertFalse(result!.title.contains("john@example.com"))
        XCTAssertFalse(result!.title.contains("555-123-4567"))
    }
    
    func testParseWithDateFormatHint() async throws {
        // Given
        let text = "Meeting on 25/12/2024 at 10am"
        let inputType = InputType.text
        
        // When
        let result = NLParser.parse(text, inputType: inputType)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Meeting")
        XCTAssertEqual(result?.inputType, inputType)
    }
    
    func testParseUncertainFields() async throws {
        // Given
        let textWithMissingDateAndTime = "Meeting at Grand Central"
        let textWithMissingTime = "Meeting tomorrow"
        
        // When
        let missingEverythingResult = NLParser.parse(textWithMissingDateAndTime, inputType: .text)
        let missingTimeResult = NLParser.parse(textWithMissingTime, inputType: .text)
        
        // Then
        XCTAssertNotNil(missingEverythingResult)
        XCTAssertNotNil(missingTimeResult)
        
        // Check uncertain fields: when no date, time is also uncertain
        XCTAssertTrue(missingEverythingResult!.uncertainFields.contains(.date))
        XCTAssertTrue(missingEverythingResult!.uncertainFields.contains(.time))
        
        // When only time is missing but date exists, only time is uncertain
        XCTAssertFalse(missingTimeResult!.uncertainFields.contains(.date))
        XCTAssertTrue(missingTimeResult!.uncertainFields.contains(.time))
    }
    
    func testParseNormalization() async throws {
        // Given
        let textWithExtraSpaces = "   Meeting    tomorrow    at    3pm   "
        let textWithNewlines = "Meeting\ntomorrow\nat 3pm"
        
        // When
        let normalizedResult1 = NLParser.parse(textWithExtraSpaces, inputType: .text)
        let normalizedResult2 = NLParser.parse(textWithNewlines, inputType: .text)
        
        // Then
        XCTAssertNotNil(normalizedResult1)
        XCTAssertNotNil(normalizedResult2)
        
        // Both should parse the same way
        XCTAssertEqual(normalizedResult1?.title, "Meeting")
        XCTAssertEqual(normalizedResult2?.title, "Meeting")
    }
}