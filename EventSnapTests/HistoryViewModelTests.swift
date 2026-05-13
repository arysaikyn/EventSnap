import XCTest
import SwiftData

@testable import EventSnap

// MARK: - HistoryViewModelTests

@MainActor
final class HistoryViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var calendarService: CalendarService!
    var viewModel: HistoryViewModel!

    override func setUp() {
        super.setUp()

        calendarService = CalendarService()
        modelContainer = try! ModelContainer(
            for: EventHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = modelContainer.mainContext

        viewModel = HistoryViewModel(
            modelContext: modelContext,
            calendarService: calendarService
        )
    }

    override func tearDown() {
        viewModel = nil
        calendarService = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.filteredEvents.count, 0)
        XCTAssertEqual(viewModel.allEvents.count, 0)
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertNil(viewModel.loadError)
    }

    // MARK: - Load Events Tests

    func testLoadEvents_EmptyDatabase() {
        viewModel.loadEvents()
        XCTAssertEqual(viewModel.allEvents.count, 0)
        XCTAssertEqual(viewModel.filteredEvents.count, 0)
    }

    func testLoadEvents_WithEntries() {
        insertTestEvent(title: "Event 1")
        insertTestEvent(title: "Event 2")

        viewModel.loadEvents()

        XCTAssertEqual(viewModel.allEvents.count, 2)
        XCTAssertEqual(viewModel.filteredEvents.count, 2)
    }

    // MARK: - Delete Tests

    func testDeleteEvent() {
        let event = insertTestEvent(title: "To Delete")
        viewModel.loadEvents()
        XCTAssertEqual(viewModel.allEvents.count, 1)

        viewModel.deleteEvent(event)

        viewModel.loadEvents()
        XCTAssertEqual(viewModel.allEvents.count, 0)
    }

    func testDeleteMultipleEvents() {
        let e1 = insertTestEvent(title: "Event 1")
        let e2 = insertTestEvent(title: "Event 2")
        let e3 = insertTestEvent(title: "Event 3")

        viewModel.loadEvents()
        XCTAssertEqual(viewModel.allEvents.count, 3)

        viewModel.deleteEvents([e1, e2])

        viewModel.loadEvents()
        XCTAssertEqual(viewModel.allEvents.count, 1)
        XCTAssertEqual(viewModel.allEvents.first?.title, "Event 3")
    }

    // MARK: - Search Tests

    func testSearch_MatchingTitle() {
        insertTestEvent(title: "Team Meeting")
        insertTestEvent(title: "Dinner Party")
        insertTestEvent(title: "Doctor Appointment")

        viewModel.loadEvents()
        viewModel.searchQuery = "meeting"

        XCTAssertEqual(viewModel.filteredEvents.count, 1)
        XCTAssertEqual(viewModel.filteredEvents.first?.title, "Team Meeting")
    }

    func testSearch_MatchingLocation() {
        insertTestEvent(title: "Event A", location: "Conference Room A")
        insertTestEvent(title: "Event B", location: "Conference Room B")
        insertTestEvent(title: "Event C", location: "Home")

        viewModel.loadEvents()
        viewModel.searchQuery = "conference"

        XCTAssertEqual(viewModel.filteredEvents.count, 2)
    }

    func testSearch_NoMatch() {
        insertTestEvent(title: "Team Meeting")

        viewModel.loadEvents()
        viewModel.searchQuery = "xyzzy"

        XCTAssertEqual(viewModel.filteredEvents.count, 0)
        XCTAssertTrue(viewModel.isSearching)
    }

    func testSearch_EmptyQuery_ShowAll() {
        insertTestEvent(title: "Event 1")
        insertTestEvent(title: "Event 2")

        viewModel.loadEvents()
        viewModel.searchQuery = ""

        XCTAssertEqual(viewModel.filteredEvents.count, 2)
        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearch_CaseInsensitive() {
        insertTestEvent(title: "Team Meeting")

        viewModel.loadEvents()
        viewModel.searchQuery = "team meeting"

        XCTAssertEqual(viewModel.filteredEvents.count, 1)
    }

    // MARK: - Grouping Tests

    func testGroupingByDate() {
        insertTestEvent(title: "Today Event")
        insertTestEvent(title: "Yesterday Event", daysOffset: -1)

        viewModel.loadEvents()

        XCTAssertEqual(viewModel.sectionDates.count, 2)
    }

    func testEventsForDate() {
        insertTestEvent(title: "Today A")
        insertTestEvent(title: "Today B")

        viewModel.loadEvents()

        let today = Calendar.current.startOfDay(for: Date())
        let events = viewModel.events(for: today)
        XCTAssertEqual(events.count, 2)
    }

    func testSectionCount() {
        insertTestEvent(title: "Event 1")
        insertTestEvent(title: "Event 2", daysOffset: -1)

        viewModel.loadEvents()
        XCTAssertEqual(viewModel.sectionCount, 2)
    }

    // MARK: - Refresh Tests

    func testRefresh() {
        insertTestEvent(title: "Before Refresh")

        viewModel.loadEvents()
        XCTAssertEqual(viewModel.allEvents.count, 1)

        insertTestEvent(title: "After Insert")
        viewModel.refresh()

        XCTAssertEqual(viewModel.allEvents.count, 2)
    }

    // MARK: - Helper Methods

    private func insertTestEvent(title: String, location: String? = nil, daysOffset: Int = 0) -> EventHistory {
        let event = EventHistory(
            title: title,
            startDate: Date().addingTimeInterval(Double(daysOffset) * 86400),
            location: location,
            calendarIdentifier: "test-cal",
            inputType: .text,
            confidence: 0.8,
            eventIdentifier: "test-evt-\(UUID().uuidString)"
        )
        modelContext.insert(event)
        try! modelContext.save()
        return event
    }
}