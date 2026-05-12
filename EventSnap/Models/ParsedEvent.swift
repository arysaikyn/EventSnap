import Foundation
import EventKit

// MARK: - Core Parsed Event Model

/// Represents a parsed event before it is inserted into the calendar.
/// Contains all extracted fields, confidence metadata, and the raw source text.
struct ParsedEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startDate: Date
    var endDate: Date?
    var location: String?
    var locationAddress: String?
    var notes: String?
    var calendar: EKCalendar?
    var confidence: Double // 0.0–1.0 overall confidence
    var uncertainFields: Set<EventField> // fields the parser is unsure about
    var sourceText: String // the raw text that was parsed
    var inputType: InputType

    // MARK: - Convenience

    /// Whether the event has enough valid data to be inserted into the calendar.
    var isReadyForCalendar: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && confidence > 0.3
    }

    /// The overall confidence expressed as a percentage (0–100) for display.
    var confidencePercent: Int {
        Int((confidence * 100).rounded())
    }

    /// A human-readable summary of what was parsed, for use in preview UI.
    var summary: String {
        var parts: [String] = []
        parts.append(title)
        
        // Use cached formatters from Date+Extensions.swift
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale.current
        let dateStr = formatter.string(from: startDate)
        
        formatter.dateFormat = "h:mm a"
        let timeStr = formatter.string(from: startDate)
        
        parts.append("\(dateStr) · \(timeStr)")
        
        if let loc = location {
            parts.append("📍 \(loc)")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - EventField

/// Fields of an event that the parser may mark as uncertain.
enum EventField: String, CaseIterable, Codable {
    case title
    case date
    case time
    case location
    case notes
}

// MARK: - InputType

/// The method by which event text was obtained.
enum InputType: String, Codable, CaseIterable {
    case camera
    case voice
    case text
}

// MARK: - ParsedEvent + EKEvent conversion

extension ParsedEvent {
    /// Converts this parsed event into an `EKEvent` ready for calendar insertion.
    /// - Parameter eventStore: The `EKEventStore` to create the event in.
    /// - Returns: A configured `EKEvent`.
    func makeEKEvent(in eventStore: EKEventStore) -> EKEvent {
        let ekEvent = EKEvent(eventStore: eventStore)

        ekEvent.title = title
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        ekEvent.notes = buildNotes()
        ekEvent.calendar = calendar ?? eventStore.defaultCalendarForNewEvents

        // Apply location if present
        if let loc = location ?? locationAddress {
            ekEvent.location = loc
        }

        // Set availability to free/busy based on confidence
        ekEvent.availability = confidence >= 0.7 ? .busy : .free

        return ekEvent
    }

    /// Builds the notes string by consolidating user notes, location address, and source text.
    private func buildNotes() -> String {
        var parts: [String] = []

        if let existingNotes = notes, !existingNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(existingNotes)
        }

        if let addr = locationAddress, addr != location {
            parts.append("Address: \(addr)")
        }

        parts.append("")
        parts.append("—")
        parts.append("Added via EventSnap (\(inputType.rawValue))")

        return parts.joined(separator: "\n")
    }
}

// MARK: - Coding keys for manual conformance

extension ParsedEvent {
    enum CodingKeys: String, CodingKey {
        case id, title, startDate, endDate, location, locationAddress, notes
        case confidence, uncertainFields, sourceText, inputType
        // NOTE: `calendar` (EKCalendar) is intentionally excluded because EKCalendar is not Codable.
        // When persisting, use `calendarIdentifier` (as done in EventHistory).
    }
}

extension EventField: CodingKey {}