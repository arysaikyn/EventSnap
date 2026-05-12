import SwiftUI
import SwiftData
#if canImport(EventKitUI)
import EventKitUI
#endif

@Observable
final class HistoryViewModel {
    // MARK: - Published State

    var searchQuery = "" {
        didSet { scheduleSearch() }
    }

    var filteredEvents: [EventHistory] = []
    var isSearching = false
    var groupedEvents: [Date: [EventHistory]] = [:]
    var allEvents: [EventHistory] = []
    var loadError: String?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let calendarService: CalendarService

    // MARK: - Private State

    private var searchTask: Task<Void, Never>?
    private static let debounceNanoseconds: UInt64 = 300_000_000 // 300 ms

    // MARK: - Init

    init(modelContext: ModelContext, calendarService: CalendarService) {
        self.modelContext = modelContext
        self.calendarService = calendarService
        loadEvents()
    }

    // MARK: - Data Loading

    /// Fetch all history records from SwiftData, sorted newest-first.
    func loadEvents() {
        let descriptor = FetchDescriptor<EventHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            allEvents = try modelContext.fetch(descriptor)
            loadError = nil
            applySearchAndGroup()
        } catch {
            loadError = "Failed to load history: \(error.localizedDescription)"
            allEvents = []
            filteredEvents = []
            groupedEvents = [:]
        }
    }

    // MARK: - Mutations

    /// Delete an event from history only (does **not** remove from Calendar).
    func deleteEvent(_ event: EventHistory) {
        modelContext.delete(event)

        do {
            try modelContext.save()
            loadEvents() // refresh the list
        } catch {
            loadError = "Failed to delete event: \(error.localizedDescription)"
        }
    }

    /// Delete multiple events at once.
    func deleteEvents(_ events: [EventHistory]) {
        for event in events {
            modelContext.delete(event)
        }

        do {
            try modelContext.save()
            loadEvents()
        } catch {
            loadError = "Failed to delete events: \(error.localizedDescription)"
        }
    }

    /// Open the event in the system Calendar app using its `eventIdentifier`.
    func openInCalendar(_ event: EventHistory) {
        let eventIdentifier = event.eventIdentifier
        if eventIdentifier.isEmpty {
            loadError = "This event does not have a Calendar identifier."
            return
        }
        calendarService.openEventInCalendar(with: eventIdentifier)
    }

    /// Reload data (useful after returning from background).
    func refresh() {
        loadEvents()
    }

    // MARK: - Search

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            self.isSearching = !self.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
            self.applySearchAndGroup()
        }
    }

    /// Filter `allEvents` by `searchQuery` and group by date.
    private func applySearchAndGroup() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if query.isEmpty {
            filteredEvents = allEvents
        } else {
            filteredEvents = allEvents.filter { event in
                event.title.localizedCaseInsensitiveContains(query) ||
                event.location?.localizedCaseInsensitiveContains(query) ?? false
            }
        }

        groupEventsByDate()
    }

    /// Group filtered events by their creation date (start of day).
    private func groupEventsByDate() {
        let calendar = Calendar.current
        groupedEvents = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.createdAt)
        }
    }

    // MARK: - Helpers

    /// Number of sections in the grouped display.
    var sectionCount: Int {
        groupedEvents.keys.count
    }

    /// Sorted section dates (newest first).
    var sectionDates: [Date] {
        groupedEvents.keys.sorted(by: >)
    }

    /// Events for a given section date.
    func events(for date: Date) -> [EventHistory] {
        groupedEvents[date] ?? []
    }
}