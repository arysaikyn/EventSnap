import Foundation

// MARK: - Event Display Formatting

extension Date {
    /// Formatted as a short weekday + month + day string.
    /// Example: "Fri, Jun 14"
    var eventDisplayDate: String {
        Self.eventDateFormatter.string(from: self)
    }

    /// Formatted as a short time string.
    /// Example: "7:00 PM"
    var eventDisplayTime: String {
        Self.eventTimeFormatter.string(from: self)
    }

    /// Combined date and time display.
    /// Example: "Fri, Jun 14 · 7:00 PM"
    var eventDisplayDateTime: String {
        "\(eventDisplayDate) · \(eventDisplayTime)"
    }

    /// Returns `true` if the date falls on today's date.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns `true` if the date falls on yesterday's date.
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Returns `true` if the date falls on tomorrow's date.
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Resolves relative weekday references like "next Thursday".
    ///
    /// Given a target weekday (e.g., `.thursday`), returns the next occurrence
    /// of that weekday relative to the receiver. If today matches the target,
    /// returns today.
    ///
    /// - Parameter weekday: The desired `Weekday` (`.sunday` through `.saturday`).
    /// - Returns: The date of the next occurrence of the specified weekday.
    func nextWeekday(_ weekday: Weekday) -> Date {
        let calendar = Calendar.current
        let targetComponent = weekday.rawValue
        let currentComponent = calendar.component(.weekday, from: self)

        var daysToAdd = targetComponent - currentComponent
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: self) ?? self
    }

    // MARK: - Formatters

    private static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale.current
        return formatter
    }()

    private static let eventTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale.current
        return formatter
    }()
}

// MARK: - Weekday Enum

/// Represents the days of the week for calendar calculations.
///
/// Raw values correspond to `Calendar.current.component(.weekday, from:)` values
/// where 1 = Sunday (per Gregorian calendar).
enum Weekday: Int, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    /// Localized display name (e.g., "Monday", "Mon").
    var displayName: String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[rawValue - 1]
    }

    /// Abbreviated display name (e.g., "Mon").
    var shortDisplayName: String {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols[rawValue - 1]
    }
}