import XCTest
import SwiftData

@testable import EventSnap

// MARK: - EventHistoryTests

@MainActor
final class EventHistoryTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        modelContainer = try! ModelContainer(
            for: EventHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Creation Tests

    func testEventHistoryCreation_AllFields() {
        let history = EventHistory(
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Conference Room A",
            calendarIdentifier: "cal-123",
            inputType: .camera,
            confidence: 0.85,
            eventIdentifier: "evt-456"
        )

        XCTAssertEqual(history.title, "Team Meeting")
        XCTAssertEqual(history.calendarIdentifier, "cal-123")
        XCTAssertEqual(history.inputTypeRaw, "camera")
        XCTAssertEqual(history.confidence, 0.85)
        XCTAssertEqual(history.eventIdentifier, "evt-456")
        XCTAssertNotNil(history.id)
    }

    func testEventHistoryCreation_MinimumFields() {
        let history = EventHistory(
            title: "Quick Event",
            startDate: Date(),
            calendarIdentifier: "cal-abc",
            inputType: .text,
            confidence: 0.6,
            eventIdentifier: "evt-xyz"
        )

        XCTAssertEqual(history.title, "Quick Event")
        XCTAssertNil(history.endDate)
        XCTAssertNil(history.location)
    }

    // MARK: - InputType Tests

    func testInputType_ValidRawValues() {
        let cameraHistory = EventHistory(
            title: "Camera Event",
            startDate: Date(),
            calendarIdentifier: "cal-1",
            inputType: .camera,
            confidence: 0.9,
            eventIdentifier: "evt-1"
        )
        XCTAssertEqual(cameraHistory.inputType, .camera)

        let voiceHistory = EventHistory(
            title: "Voice Event",
            startDate: Date(),
            calendarIdentifier: "cal-2",
            inputType: .voice,
            confidence: 0.8,
            eventIdentifier: "evt-2"
        )
        XCTAssertEqual(voiceHistory.inputType, .voice)

        let textHistory = EventHistory(
            title: "Text Event",
            startDate: Date(),
            calendarIdentifier: "cal-3",
            inputType: .text,
            confidence: 0.7,
            eventIdentifier: "evt-3"
        )
        XCTAssertEqual(textHistory.inputType, .text)
    }

    func testInputType_InvalidRawValue_ReturnsNil() {
        let history = EventHistory(
            title: "Invalid",
            startDate: Date(),
            calendarIdentifier: "cal-x",
            inputType: .text,
            confidence: 0.5,
            eventIdentifier: "evt-x"
        )
        // Manually set to invalid raw value
        history.inputTypeRaw = "invalid_type"
        XCTAssertNil(history.inputType)
    }

    // MARK: - Display Helpers Tests

    func testFormattedDate_NotEmpty() {
        let history = EventHistory(
            title: "Test",
            startDate: Date(),
            calendarIdentifier: "cal-1",
            inputType: .text,
            confidence: 0.8,
            eventIdentifier: "evt-1"
        )
        XCTAssertFalse(history.formattedDate.isEmpty)
    }

    func testRelativeTime_NotEmpty() {
        let history = EventHistory(
            title: "Test",
            startDate: Date(),
            calendarIdentifier: "cal-1",
            inputType: .text,
            confidence: 0.8,
            eventIdentifier: "evt-1"
        )
        XCTAssertFalse(history.relativeTime.isEmpty)
    }

    // MARK: - SwiftData Persistence Tests

    func testSwiftData_InsertAndFetch() {
        let history = EventHistory(
            title: "Persisted Event",
            startDate: Date(),
            calendarIdentifier: "cal-persist",
            inputType: .camera,
            confidence: 0.9,
            eventIdentifier: "evt-persist"
        )

        modelContext.insert(history)
        try! modelContext.save()

        let descriptor = FetchDescriptor<EventHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let fetched = try! modelContext.fetch(descriptor)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Persisted Event")
    }

    func testSwiftData_Delete() {
        let history = EventHistory(
            title: "To Delete",
            startDate: Date(),
            calendarIdentifier: "cal-del",
            inputType: .text,
            confidence: 0.5,
            eventIdentifier: "evt-del"
        )

        modelContext.insert(history)
        try! modelContext.save()

        modelContext.delete(history)
        try! modelContext.save()

        let descriptor = FetchDescriptor<EventHistory>()
        let fetched = try! modelContext.fetch(descriptor)
        XCTAssertEqual(fetched.count, 0)
    }

    func testSwiftData_MultipleEntries() {
        for i in 1...5 {
            let history = EventHistory(
                title: "Event \(i)",
                startDate: Date().addingTimeInterval(Double(i) * 3600),
                calendarIdentifier: "cal-\(i)",
                inputType: i % 2 == 0 ? .voice : .camera,
                confidence: 0.8,
                eventIdentifier: "evt-\(i)"
            )
            modelContext.insert(history)
        }
        try! modelContext.save()

        let descriptor = FetchDescriptor<EventHistory>()
        let fetched = try! modelContext.fetch(descriptor)
        XCTAssertEqual(fetched.count, 5)
    }

    // MARK: - Unique ID Tests

    func testUniqueId_EachEntryDifferent() {
        let h1 = EventHistory(
            title: "Event 1",
            startDate: Date(),
            calendarIdentifier: "cal-1",
            inputType: .camera,
            confidence: 0.8,
            eventIdentifier: "evt-1"
        )
        let h2 = EventHistory(
            title: "Event 2",
            startDate: Date(),
            calendarIdentifier: "cal-2",
            inputType: .voice,
            confidence: 0.7,
            eventIdentifier: "evt-2"
        )

        XCTAssertNotEqual(h1.id, h2.id)
    }

    // MARK: - Sort Descriptor Tests

    func testDefaultSort_NewestFirst() {
        let older = EventHistory(
            title: "Older",
            startDate: Date().addingTimeInterval(-86400),
            calendarIdentifier: "cal-old",
            inputType: .text,
            confidence: 0.6,
            eventIdentifier: "evt-old"
        )
        let newer = EventHistory(
            title: "Newer",
            startDate: Date(),
            calendarIdentifier: "cal-new",
            inputType: .camera,
            confidence: 0.9,
            eventIdentifier: "evt-new"
        )

        modelContext.insert(older)
        modelContext.insert(newer)
        try! modelContext.save()

        let descriptor = EventHistory.defaultSort
        let fetched = try! modelContext.fetch(FetchDescriptor<EventHistory>(sortBy: descriptor))

        XCTAssertEqual(fetched.first?.title, "Newer")
    }
}