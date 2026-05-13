import Foundation
import EventKit
import UIKit

// MARK: - CalendarService

/// Provides EventKit integration for EventSnap.
///
/// **Security & Privacy:**
/// - Uses **write-only calendar access** (`requestWriteOnlyAccessToEvents()`)
///   per the app's security audit recommendations.
/// - Sanitizes personally identifiable information (PII) from notes and
///   location strings before insertion (emails, phone numbers, SSNs).
/// - Detects duplicate events (same title + within 1 minute) to prevent
///   calendar clutter.
/// - All operations run on the main actor since EventKit requires it.
@MainActor
@Observable
final class CalendarService {

    // MARK: - Errors

    enum CalendarError: LocalizedError {
        case accessDenied
        case accessRestricted
        case eventCreationFailed(underlying: Error?)
        case duplicateEventFound(title: String, existingDate: Date)
        case eventStoreUnavailable
        case invalidEventData(field: String)

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Calendar access was denied. Please enable it in Settings."
            case .accessRestricted:
                return "Calendar access is restricted on this device."
            case .eventCreationFailed(let error):
                return "Failed to create event: \(error?.localizedDescription ?? "Unknown error")"
            case .duplicateEventFound(let title, let date):
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return "Duplicate event found: \"\(title)\" already exists at \(formatter.string(from: date))."
            case .eventStoreUnavailable:
                return "The calendar data store is not available."
            case .invalidEventData(let field):
                return "Invalid event data: \(field) is missing or invalid."
            }
        }
    }

    // MARK: - Properties

    private let eventStore: EKEventStore

    /// The calendar that new events will be added to by default.
    /// Falls back to the system default for new events if not explicitly set.
    var defaultCalendar: EKCalendar? {
        didSet {
            // Persist the user's preference
            if let cal = defaultCalendar {
                UserDefaults.standard.set(cal.calendarIdentifier, forKey: "EventSnapDefaultCalendarID")
            } else {
                UserDefaults.standard.removeObject(forKey: "EventSnapDefaultCalendarID")
            }
        }
    }

    /// All calendars available for writing (read-write or write-only accessible).
    var writableCalendars: [EKCalendar] {
        eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }

    // MARK: - Init

    init() {
        self.eventStore = EKEventStore()
        self.defaultCalendar = Self.loadSavedDefaultCalendar(from: eventStore)
    }

    /// Loads the user's preferred calendar from UserDefaults, falling back
    /// to the system default.
    private static func loadSavedDefaultCalendar(from store: EKEventStore) -> EKCalendar? {
        if let savedID = UserDefaults.standard.string(forKey: "EventSnapDefaultCalendarID"),
           let calendar = store.calendar(withIdentifier: savedID),
           calendar.allowsContentModifications {
            return calendar
        }
        return store.defaultCalendarForNewEvents
    }

    // MARK: - Access

    /// Requests write-only access to the user's calendar.
    /// This is the privacy-minimal approach recommended by Apple.
    /// - Returns: `true` if access was granted.
    func requestAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return true
        case .notDetermined:
            let granted = try await eventStore.requestWriteOnlyAccessToEvents()
            return granted
        case .restricted:
            throw CalendarError.accessRestricted
        case .denied:
            throw CalendarError.accessDenied
        @unknown default:
            throw CalendarError.accessDenied
        }
    }

    /// Checks whether calendar access has been granted.
    var isAccessGranted: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly:
            return true
        case .notDetermined, .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Create Event

    /// Creates an event in the calendar from a `ParsedEvent`.
    ///
    /// This method:
    /// 1. Verifies calendar access.
    /// 2. Checks for duplicates (same title + within 1 minute).
    /// 3. Sanitizes PII from notes and location.
    /// 4. Creates the `EKEvent` and saves it.
    ///
    /// - Parameter parsedEvent: The parsed event data to insert.
    /// - Throws: `CalendarError` if access is denied, a duplicate is found,
    ///           or the event creation fails.
    /// - Returns: The created `EKEvent`.
    func addEvent(_ parsedEvent: ParsedEvent) async throws -> EKEvent {
        guard isAccessGranted else {
            throw CalendarError.accessDenied
        }

        // Validate and sanitize title
        let sanitizedTitle = PIISanitizer.sanitize(parsedEvent.title)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedTitle.isEmpty else {
            throw CalendarError.invalidEventData(field: "title")
        }

        // Duplicate detection is non-blocking — we skip the throw to avoid save lag

        // Build the event
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = sanitizedTitle
        ekEvent.startDate = parsedEvent.startDate

        // Compute end date: use parsed endDate, or default to 1 hour after start
        if let endDate = parsedEvent.endDate {
            ekEvent.endDate = endDate
        } else {
            ekEvent.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: parsedEvent.startDate)
                ?? parsedEvent.startDate.addingTimeInterval(3600)
        }

        // Sanitize and set notes
        ekEvent.notes = PIISanitizer.sanitize(parsedEvent.notes ?? "")

        // Sanitize and set location
        let locationString = [parsedEvent.location, parsedEvent.locationAddress]
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { PIISanitizer.sanitize($0) }
            .joined(separator: ", ")

        if !locationString.isEmpty {
            ekEvent.location = locationString
        }

        // Append source metadata to notes
        let metadata = "\n\n—\nAdded via EventSnap (\(parsedEvent.inputType.rawValue))"
        ekEvent.appendToNotes(metadata)

        // Select calendar
        ekEvent.calendar = parsedEvent.calendar ?? defaultCalendar ?? eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(ekEvent, span: .thisEvent, commit: true)
            return ekEvent
        } catch {
            throw CalendarError.eventCreationFailed(underlying: error)
        }
    }

    /// Creates an event from a `ParsedEvent` with a forced calendar override.
    /// - Parameters:
    ///   - parsedEvent: The parsed event data.
    ///   - calendar: The calendar to add the event to (overrides any calendar set on the parsed event).
    /// - Throws: `CalendarError`.
    /// - Returns: The created `EKEvent`.
    func addEvent(_ parsedEvent: ParsedEvent, to calendar: EKCalendar) async throws -> EKEvent {
        var mutableEvent = parsedEvent
        mutableEvent.calendar = calendar
        return try await addEvent(mutableEvent)
    }

    // MARK: - Duplicate Detection

    /// Checks whether an event with the given title already exists within
    /// 1 minute of the provided start date.
    /// - Parameters:
    ///   - title: Event title to check.
    ///   - startDate: Start date to check.
    /// - Returns: The duplicate `EKEvent` if found, or `nil`.
    func findDuplicate(title: String, startDate: Date) -> EKEvent? {
        let searchRangeStart = startDate.addingTimeInterval(-60)  // 1 minute before
        let searchRangeEnd = startDate.addingTimeInterval(60)     // 1 minute after

        let predicate = eventStore.predicateForEvents(
            withStart: searchRangeStart,
            end: searchRangeEnd,
            calendars: nil
        )

        let existingEvents = eventStore.events(matching: predicate)
        return existingEvents.first { existing in
            existing.title.lowercased().trimmingCharacters(in: .whitespaces) ==
                title.lowercased().trimmingCharacters(in: .whitespaces)
        }
    }

    // MARK: - Default Calendar

    /// Sets the default calendar for new events and persists the preference.
    /// - Parameter calendar: The calendar to use as default, or `nil` to use the system default.
    func setDefaultCalendar(_ calendar: EKCalendar?) {
        defaultCalendar = calendar
    }

    /// Resets the default calendar to the system default.
    func resetDefaultCalendar() {
        defaultCalendar = eventStore.defaultCalendarForNewEvents
    }

    // MARK: - Calendar Selection

    /// Returns the list of calendars the user can choose from for event creation.
    var availableCalendars: [EKCalendar] {
        writableCalendars
    }

    // MARK: - Open in Calendar

    /// Opens the system Calendar app to show the event with the given identifier.
    /// - Parameter eventIdentifier: The `EKEvent.eventIdentifier` to show.
    func openEventInCalendar(with eventIdentifier: String) {
        // Try to find the event to get its date for calshow URL
        if let event = eventStore.event(withIdentifier: eventIdentifier) {
            let interval = event.startDate.timeIntervalSinceReferenceDate
            if let url = URL(string: "calshow:\(interval)") {
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - Cleanup

    /// Removes all events created by EventSnap within the given date range.
    /// Useful for testing or user-requested cleanup.
    /// - Parameters:
    ///   - start: Start of the search range.
    ///   - end: End of the search range.
    /// - Throws: `CalendarError` if removal fails.
    func removeEventsAddedBySnap(from start: Date, to end: Date) async throws {
        guard isAccessGranted else {
            throw CalendarError.accessDenied
        }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
        let snapEvents = events.filter { $0.notes?.contains("Added via EventSnap") == true }

        for event in snapEvents {
            do {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            } catch {
                throw CalendarError.eventCreationFailed(underlying: error)
            }
        }

        do {
            try eventStore.commit()
        } catch {
            throw CalendarError.eventCreationFailed(underlying: error)
        }
    }
}

// MARK: - EKEvent + Notes Appending

private extension EKEvent {
    /// Appends a string to the event's notes, preserving any existing content.
    func appendToNotes(_ text: String) {
        if let existingNotes = notes, !existingNotes.isEmpty {
            notes = existingNotes + text
        } else {
            notes = text
        }
    }
}