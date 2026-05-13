import XCTest
@testable import EventSnap

// MARK: - DateExtensionsTests

final class DateExtensionsTests: XCTestCase {

    // MARK: - Display Format Tests

    func testEventDisplayDate() {
        // Given
        let date = Date() // today

        // When
        let display = date.eventDisplayDate

        // Then
        XCTAssertFalse(display.isEmpty)
        // Should be in format "EEE, MMM d" like "Mon, Jun 9"
        XCTAssertTrue(display.contains(","))
    }

    func testEventDisplayTime() {
        // Given
        let date = Date()

        // When
        let display = date.eventDisplayTime

        // Then
        XCTAssertFalse(display.isEmpty)
        // Should be in format "h:mm a" like "7:00 PM"
        XCTAssertTrue(display.contains(":"))
    }

    func testEventDisplayDateTime_Combined() {
        // Given
        let date = Date()

        // When
        let display = date.eventDisplayDateTime

        // Then
        XCTAssertFalse(display.isEmpty)
        XCTAssertTrue(display.contains("·"), "Combined display should use · separator")
    }

    // MARK: - Relative Date Tests

    func testIsToday() {
        XCTAssertTrue(Date().isToday)
        XCTAssertFalse(Date().addingTimeInterval(-86400).isToday)
    }

    func testIsYesterday() {
        XCTAssertTrue(Date().addingTimeInterval(-86400).isYesterday)
        XCTAssertFalse(Date().isYesterday)
    }

    func testIsTomorrow() {
        XCTAssertTrue(Date().addingTimeInterval(86400).isTomorrow)
        XCTAssertFalse(Date().isTomorrow)
    }

    // MARK: - Next Weekday Tests

    func testNextWeekday_SameWeekday_ReturnsToday() {
        // Given - find what weekday today is
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())

        // When
        let result = Date().nextWeekday(Weekday(rawValue: todayWeekday)!)

        // Then - should return today since the method returns today if today matches
        let resultWeekday = calendar.component(.weekday, from: result)
        XCTAssertEqual(resultWeekday, todayWeekday)
    }

    func testNextWeekday_DifferentWeekday_ReturnsFutureDate() {
        // Given
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())

        // Find a weekday that's different from today
        let targetWeekday = todayWeekday == 2 ? Weekday.friday : Weekday.monday

        // When
        let result = Date().nextWeekday(targetWeekday)

        // Then
        let resultWeekday = calendar.component(.weekday, from: result)
        XCTAssertEqual(resultWeekday, targetWeekday.rawValue)
        XCTAssertTrue(result > Date() || calendar.isDateInToday(result))
    }

    // MARK: - Weekday Enum Tests

    func testWeekday_AllCases() {
        XCTAssertEqual(Weekday.allCases.count, 7)
    }

    func testWeekday_DisplayNames() {
        for weekday in Weekday.allCases {
            XCTAssertFalse(weekday.displayName.isEmpty)
            XCTAssertFalse(weekday.shortDisplayName.isEmpty)
        }
    }

    func testWeekday_RawValues() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.monday.rawValue, 2)
        XCTAssertEqual(Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(Weekday.thursday.rawValue, 5)
        XCTAssertEqual(Weekday.friday.rawValue, 6)
        XCTAssertEqual(Weekday.saturday.rawValue, 7)
    }
}