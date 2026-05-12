import Foundation
import SwiftData

// MARK: - EventHistory

/// A SwiftData model that persists a record of every event created through the app.
/// Used for the history screen, re-editing, and analytics.
@Model
final class EventHistory {
    // MARK: - Attributes

    /// Unique identifier for this history entry.
    @Attribute(.unique)
    var id: UUID

    /// Event title as it was added to the calendar.
    var title: String

    /// Start date of the event.
    var startDate: Date

    /// Optional end date of the event. `nil` means no end date was specified.
    var endDate: Date?

    /// Optional location string associated with the event.
    var location: String?

    /// The calendar identifier (from `EKCalendar.calendarIdentifier`) this event was added to.
    var calendarIdentifier: String

    /// Raw value of the `InputType` enum (`"camera"`, `"voice"`, or `"text"`).
    var inputTypeRaw: String

    /// Overall confidence score (0.0–1.0) from the parser at the time of creation.
    var confidence: Double

    /// Timestamp when this history entry was first saved.
    var createdAt: Date

    /// The `EKEvent.eventIdentifier` returned after the event was created in Calendar.
    var eventIdentifier: String

    // MARK: - Transient helpers (not persisted)

    /// The `InputType` decoded from the stored raw value.
    var inputType: InputType? {
        InputType(rawValue: inputTypeRaw)
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        location: String? = nil,
        calendarIdentifier: String,
        inputType: InputType,
        confidence: Double,
        createdAt: Date = Date(),
        eventIdentifier: String
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.calendarIdentifier = calendarIdentifier
        self.inputTypeRaw = inputType.rawValue
        self.confidence = confidence
        self.createdAt = createdAt
        self.eventIdentifier = eventIdentifier
    }
}

// MARK: - Display Helpers

extension EventHistory {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// A formatted date string suitable for display in list rows.
    var formattedDate: String {
        Self.dateFormatter.string(from: startDate)
    }

    /// A relative description of when this entry was created (e.g. "2 hours ago").
    var relativeTime: String {
        Self.relativeFormatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Sort descriptors

extension EventHistory {
    /// Default sort order (newest first).
    static let defaultSort: [SortDescriptor<EventHistory>] = [
        SortDescriptor(\.createdAt, order: .reverse)
    ]
}