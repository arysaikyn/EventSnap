import Foundation
import UIKit

/// Generates .ics (iCalendar) files from event data for sharing via AirDrop, Messages, etc.
enum ICSExportService {
    // MARK: - Export Errors

    enum ExportError: LocalizedError {
        case emptyTitle
        case missingStartDate
        case encodingFailed
        case shareSheetUnavailable

        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Event title is required for export."
            case .missingStartDate:
                return "Event start date is required for export."
            case .encodingFailed:
                return "Failed to encode event data."
            case .shareSheetUnavailable:
                return "Unable to open share sheet."
            }
        }
    }

    // MARK: - Public API

    /// Generate .ics data from an `EventHistory` record.
    static func generate(from history: EventHistory) throws -> Data {
        guard !history.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExportError.emptyTitle
        }

        return try icsContent(
            uid: history.id.uuidString,
            title: history.title,
            startDate: history.startDate,
            endDate: history.endDate ?? history.startDate.addingTimeInterval(3600),
            location: history.location,
            notes: nil,
            createdBy: history.inputTypeRaw
        )
    }

    /// Generate .ics data from a `ParsedEvent`.
    static func generate(from event: ParsedEvent) throws -> Data {
        guard !event.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExportError.emptyTitle
        }
        let endTime = event.endDate
            ?? Calendar.current.date(byAdding: .hour, value: 1, to: event.startDate)
            ?? event.startDate.addingTimeInterval(3600)

        return try icsContent(
            uid: event.id.uuidString,
            title: event.title,
            startDate: event.startDate,
            endDate: endTime,
            location: event.location ?? event.locationAddress,
            notes: event.notes,
            createdBy: event.inputType.rawValue
        )
    }

    // MARK: - Core Builder

    private static func icsContent(
        uid: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        createdBy: String
    ) throws -> Data {
        let now = Date()

        var lines: [String] = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//EventSnap//EN",
            "CALSCALE:GREGORIAN",
            "METHOD:PUBLISH",
            "BEGIN:VEVENT",
            "UID:\(uid)@eventsnap.app",
            "DTSTAMP:\(formatICSDate(now))",
            "DTSTART:\(formatICSDate(startDate))",
            "DTEND:\(formatICSDate(endDate))",
            "SUMMARY:\(escapeICS(title))"
        ]

        if let location, !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("LOCATION:\(escapeICS(location))")
        }

        // Build description: user notes + source attribution
        var descriptionParts: [String] = []
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            descriptionParts.append(notes.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        descriptionParts.append("Added via EventSnap (\(createdBy))")
        lines.append("DESCRIPTION:\(escapeICS(descriptionParts.joined(separator: "\n\n")))")

        // Attach a 15-minute reminder
        lines += [
            "BEGIN:VALARM",
            "TRIGGER:-PT15M",
            "ACTION:DISPLAY",
            "DESCRIPTION:Reminder",
            "END:VALARM",
            "END:VEVENT",
            "END:VCALENDAR"
        ]

        // Join with CRLF per RFC 5545 spec
        let content = lines.joined(separator: "\r\n")

        guard let data = content.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return data
    }

    // MARK: - Formatting

    /// Format a Date as iCalendar UTC: `20260519T100000Z`
    private static func formatICSDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Escape special characters per RFC 5545 section 3.3.11.
    private static func escapeICS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
