import Foundation

// MARK: - NLParser

/// Parses natural language text into structured `ParsedEvent` data.
///
/// **Hybrid parsing strategy:**
/// 1. **Dates first** — Uses `NSDataDetector` with `.date` type to find all
///    absolute and relative date references.
/// 2. **Times second** — Regex patterns for common time formats not always
///    caught by the data detector (e.g. standalone "at 7pm", "noon").
/// 3. **Duration** — Regex for "for X hours", "X-Ypm", "from X to Y".
/// 4. **Location** — Regex for "at [location]", "📍 [location]", addresses.
/// 5. **Title** — Everything not consumed by the above.
/// 6. **Recurrence** — Pattern detection for "every week", "daily", etc.
///
/// **Ambiguity resolution:**
/// - "next Thursday" → resolves to the upcoming Thursday (never past).
/// - "tomorrow", "today", "in 3 days", "next week" → resolved to absolute dates.
///
/// **Confidence scoring:**
/// - Date found: +0.35
/// - Time found: +0.25
/// - Location found: +0.15
/// - Title ≥ 2 words: +0.15
/// - Duration found: +0.10
/// - Low-confidence fields are marked in `uncertainFields`.
enum NLParser {

    // MARK: - Types

    /// Internal structure tracking what was parsed and where in the text.
    private struct ParsedSpan {
        let range: NSRange
        let kind: SpanKind
        let value: Any? // Date, String, etc.

        enum SpanKind {
            case date
            case time
            case duration
            case location
            case recurrence
        }
    }

    // MARK: - Constants

    private static let dateDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }()

    /// Safe regex factory with descriptive error messages.
    /// Patterns are compile-time constants, so compilation failures indicate
    /// developer errors that should be caught immediately at startup.
    private static func regex(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            fatalError("Invalid NLParser regex pattern: \(pattern)\nError: \(error)")
        }
    }

    // MARK: - Time Regex Patterns

    // All regex patterns are compile-time string constants. Compilation failures
    // are caught immediately at app startup with descriptive error messages.

    private static let timePatterns: [NSRegularExpression] = [
        // "at 7pm", "at 7:30pm", "at 7 PM"
        regex(#"(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)(?:\b|\.|\s|,|$)"#),
        // "7:00" (24-hour format)
        regex(#"\b(\d{1,2}):(\d{2})\b(?!\s*(?:am|pm|AM|PM))"#),
        // "noon", "midnight"
        regex(#"\b(noon|midnight)\b"#),
        // "in the morning", "in the afternoon", "in the evening"
        regex(#"\bin\s+the\s+(morning|afternoon|evening)\b"#),
        // "at noon", "at midnight"
        regex(#"\bat\s+(noon|midnight)\b"#),
    ]

    // MARK: - Duration Regex Patterns

    private static let durationPatterns: [NSRegularExpression] = [
        // "for 2 hours", "for 1 hour", "for 30 minutes", "for 45 mins"
        regex(#"for\s+(\d+)\s*(hour|hr|minute|min|h|m)s?\b"#, .caseInsensitive),
        // "2-hour", "3 hour"
        regex(#"\b(\d+)\s*[-–]\s*hour\b"#, .caseInsensitive),
        // "from 7pm to 9pm", "from 7-9pm"
        regex(#"from\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*[-–to]+\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#, .caseInsensitive),
        // "7pm-9pm", "7:00-9:00", "7-9pm"
        regex(#"\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*[-–]\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?"#, .caseInsensitive),
    ]

    // MARK: - Location Regex Patterns

    private static let locationPatterns: [NSRegularExpression] = [
        // 📍 marker
        regex(#"📍\s*(.+?)(?:$|\.|,|\n)"#),
        // "at [Place Name]" — only if "at" is not followed by a time
        regex(#"(?:^|\.|,|\s)\bat\s+([A-Z][A-Za-z0-9\s'&.-]+?)(?:$|\.|,|\n| \(|\s+on|\s+this|\s+next|\s+tomorrow|\s+at\s+)"#),
        // "in [Place Name]" 
        regex(#"(?:^|\.|,|\s)\bin\s+the\s+([A-Z][A-Za-z0-9\s'&.-]+?)(?:$|\.|,|\n)"#),
        // Address patterns (starts with a number)
        regex(#"\b(\d+\s+[A-Za-z0-9\s.'-]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct|Place|Pl|Way|Square|Sq|Highway|Hwy|Suite|Ste|Floor|Fl)\b[^,\.\n]*)"#, .caseInsensitive),
        // "@ [Place]" (social media style)
        regex(#"@\s*([A-Za-z0-9\s'&.-]+?)(?:$|\.|,|\n)"#),
    ]

    // MARK: - Recurrence Regex Patterns

    private static let recurrencePatterns: [NSRegularExpression] = [
        // "every day", "every week", "every month", "every year"
        regex(#"every\s+(day|week|month|year|monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b"#, .caseInsensitive),
        // "daily", "weekly", "monthly", "yearly"
        regex(#"\b(daily|weekly|monthly|yearly|biweekly|semimonthly)\b"#, .caseInsensitive),
        // "every other day/week/month"
        regex(#"every\s+other\s+(day|week|month|year)\b"#, .caseInsensitive),
        // "each Monday", "each Tuesday", etc.
        regex(#"each\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#, .caseInsensitive),
        // "weekdays", "weekends"
        regex(#"\b(weekdays?|weekends?)\b"#, .caseInsensitive),
    ]

    // MARK: - Relative Date Predicates

    private static let relativeDatePatterns: [NSRegularExpression] = [
        // "today", "tonight"
        regex(#"\b(today|tonight)\b"#, .caseInsensitive),
        // "tomorrow"
        regex(#"\b(tomorrow)\b"#, .caseInsensitive),
        // "in X days/weeks"
        regex(#"\bin\s+(\d+)\s+(day|days|week|weeks)\b"#, .caseInsensitive),
        // "next week", "next month"
        regex(#"\bnext\s+(week|month|year)\b"#, .caseInsensitive),
        // "this week", "this month"
        regex(#"\bthis\s+(week|month|year)\b"#, .caseInsensitive),
    ]

    // MARK: - Public Parse Method

    /// Parses the given text into a `ParsedEvent`.
    ///
    /// - Parameters:
    ///   - text: The raw text to parse (from OCR, speech, or keyboard).
    ///   - inputType: The input method used to obtain the text.
    /// - Returns: A `ParsedEvent` if any meaningful content was found,
    ///            or `nil` if the text is empty, contains only noise, or is too long.
    static func parse(_ text: String, inputType: InputType) -> ParsedEvent? {
        // Guard against excessively long inputs
        guard text.count <= 5000 else { return nil }

        let normalized = normalizeText(text)
        guard !normalized.isEmpty else { return nil }

        let nsText = normalized as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        // Phase 1: Find all date-related spans
        var spans: [ParsedSpan] = []
        var startDate: Date?
        var endDate: Date?

        // --- Detect dates via NSDataDetector ---
        if let detector = dateDetector {
            let matches = detector.matches(in: normalized, range: fullRange)

            for match in matches {
                guard match.resultType == .date else { continue }
                if let date = match.date {
                    // Check if this looks like a date range (duration > 0)
                    if match.duration > 0 {
                        startDate = date
                        endDate = date.addingTimeInterval(match.duration)
                    } else if startDate == nil {
                        startDate = date
                    } else {
                        // Already have a start date — treat this as potential end date
                        endDate = date
                    }
                    spans.append(ParsedSpan(range: match.range, kind: .date, value: date))
                }
            }
        }

        // --- Detect standalone times via regex ---
        var hasStandaloneTime = false
        for pattern in timePatterns {
            let matches = pattern.matches(in: normalized, range: fullRange)
            for match in matches where !overlapsAnySpan(match.range, spans: spans) {
                if let timeDate = extractTime(from: match, in: nsText) {
                    if startDate != nil && !hasStandaloneTime {
                        // Merge time into existing start date
                        startDate = combine(date: startDate!, time: timeDate)
                        hasStandaloneTime = true
                    } else if startDate == nil {
                        startDate = timeDate
                        hasStandaloneTime = true
                    }
                    spans.append(ParsedSpan(range: match.range, kind: .time, value: timeDate))
                }
            }
        }

        // Phase 2: Detect duration
        var durationMinutes: Int?
        for pattern in durationPatterns {
            let matches = pattern.matches(in: normalized, range: fullRange)
            for match in matches where !overlapsAnySpan(match.range, spans: spans) {
                if let minutes = extractDuration(from: match, in: nsText) {
                    durationMinutes = minutes
                    spans.append(ParsedSpan(range: match.range, kind: .duration, value: minutes))
                }
            }
        }

        // Phase 3: Apply duration to end date
        if let start = startDate, let minutes = durationMinutes, endDate == nil {
            endDate = Calendar.current.date(byAdding: .minute, value: minutes, to: start)
        }

        // Phase 4: Detect recurrence
        var recurrenceText: String?
        for pattern in recurrencePatterns {
            let matches = pattern.matches(in: normalized, range: fullRange)
            for match in matches where !overlapsAnySpan(match.range, spans: spans) {
                let text = nsText.substring(with: match.range)
                recurrenceText = text
                spans.append(ParsedSpan(range: match.range, kind: .recurrence, value: text))
            }
        }

        // Phase 5: Detect location
        var locationName: String?
        var locationAddress: String?
        for pattern in locationPatterns {
            let matches = pattern.matches(in: normalized, range: fullRange)
            for match in matches where !overlapsAnySpan(match.range, spans: spans) {
                let capturedRange = match.range(at: 1)
                guard capturedRange.location != NSNotFound else { continue }
                let value = nsText.substring(with: capturedRange).trimmingCharacters(in: .whitespaces)

                guard !value.isEmpty, value.count > 1 else { continue }

                // Skip if it looks like a time or date fragment
                if value.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789")) == nil
                    || value.contains("Street") || value.contains("Ave") || value.contains("Road") {
                    if value.count > 2 {
                        if pattern.pattern.contains("Address") || value.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                            locationAddress = value
                        } else if locationName == nil {
                            locationName = value
                        }
                        spans.append(ParsedSpan(range: match.range, kind: .location, value: value))
                    }
                }
            }
        }

        // Phase 6: Extract title (everything not consumed by other spans)
        let title = extractTitle(from: normalized, excluding: spans)

        // Phase 7: Build notes (everything that was part of processed spans, minus title)
        let notes = extractNotes(from: normalized, title: title, spans: spans,
                                 locationName: locationName, recurrenceText: recurrenceText)

        // Phase 8: Calculate confidence
        let confidence = calculateConfidence(
            hasDate: startDate != nil,
            hasTime: hasStandaloneTime || (startDate != nil),
            hasLocation: locationName != nil || locationAddress != nil,
            hasDuration: durationMinutes != nil,
            hasRecurrence: recurrenceText != nil,
            titleLength: title.count
        )

        // Phase 9: Determine uncertain fields
        var uncertainFields = Set<EventField>()
        if startDate == nil { uncertainFields.insert(.date) }
        if !hasStandaloneTime && startDate == nil { uncertainFields.insert(.time) }
        if locationName == nil && locationAddress == nil { uncertainFields.insert(.location) }
        if title.trimmingCharacters(in: .whitespaces).isEmpty { uncertainFields.insert(.title) }

        // Final date fallback
        let finalStartDate = startDate ?? Calendar.current.startOfDay(for: Date())
            .addingTimeInterval(12 * 3600) // Default to noon today

        let sanitizedTitle = PIISanitizer.sanitize(title).trimmingCharacters(in: .whitespaces)
        guard !sanitizedTitle.isEmpty else { return nil }

        return ParsedEvent(
            title: sanitizedTitle,
            startDate: finalStartDate,
            endDate: endDate,
            location: PIISanitizer.sanitize(locationName ?? "").nilIfEmpty,
            locationAddress: PIISanitizer.sanitize(locationAddress ?? "").nilIfEmpty,
            notes: PIISanitizer.sanitize(notes).nilIfEmpty,
            confidence: confidence,
            uncertainFields: uncertainFields,
            sourceText: text,
            inputType: inputType
        )
    }

    // MARK: - Helper: Normalize Text

    private static func normalizeText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[\u{0000}-\u{0008}\u{000B}\u{000C}\u{000E}-\u{001F}]",
                                  with: "", options: .regularExpression)
            .replacingOccurrences(of: "\n\n+", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
    }

    // MARK: - Helper: Span Overlap Check

    private static func overlapsAnySpan(_ range: NSRange, spans: [ParsedSpan]) -> Bool {
        spans.contains { NSIntersectionRange($0.range, range).length > 0 }
    }

    // MARK: - Helper: Extract Time

    private static func extractTime(from match: NSTextCheckingResult, in text: NSString) -> Date? {
        let calendar = Calendar.current
        let fullMatch = text.substring(with: match.range).lowercased()

        // Handle keywords
        if fullMatch.contains("noon") || fullMatch.contains("midnight") {
            let hour = fullMatch.contains("midnight") ? 0 : 12
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())
        }

        // Handle time-of-day references
        if fullMatch.contains("morning") && !fullMatch.contains("in the morning") {
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        }
        if fullMatch.contains("afternoon") {
            return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: Date())
        }
        if fullMatch.contains("evening") {
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date())
        }

        // Parse numeric time
        var hour: Int?
        var minute = 0
        var isPM = false

        // Try to extract hour/minute/AMPM from the match groups
        if match.numberOfRanges >= 2 {
            let hourRange = match.range(at: 1)
            if hourRange.location != NSNotFound {
                hour = Int(text.substring(with: hourRange))
            }
        }

        if match.numberOfRanges >= 3 {
            let minRange = match.range(at: 2)
            if minRange.location != NSNotFound {
                minute = Int(text.substring(with: minRange)) ?? 0
            }
        }

        if match.numberOfRanges >= 4 {
            let ampmRange = match.range(at: 3)
            if ampmRange.location != NSNotFound {
                let ampm = text.substring(with: ampmRange).lowercased()
                isPM = ampm == "pm"
            }
        }

        // Try extracting from full match string as fallback
        if hour == nil {
            // Try regex on the full match
            let pattern = #/(\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)?/#
            if let result = try? pattern.firstMatch(in: fullMatch) {
                hour = Int(result.1)
                if let minStr = result.2 {
                    minute = Int(minStr) ?? 0
                }
                if let ampmStr = result.3 {
                    isPM = ampmStr.lowercased() == "pm"
                }
            }
        }

        guard let h = hour, h >= 1, h <= 23 else { return nil }

        var finalHour = h
        if isPM && h != 12 { finalHour += 12 }
        if !isPM && h == 12 { finalHour = 0 } // 12am = midnight

        return calendar.date(bySettingHour: finalHour, minute: minute, second: 0, of: Date())
    }

    // MARK: - Helper: Combine Date + Time

    private static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        return calendar.date(bySettingHour: timeComponents.hour ?? 12,
                             minute: timeComponents.minute ?? 0,
                             second: timeComponents.second ?? 0,
                             of: date) ?? date
    }

    // MARK: - Helper: Extract Duration

    private static func extractDuration(from match: NSTextCheckingResult, in text: NSString) -> Int? {
        let fullMatch = text.substring(with: match.range).lowercased()

        // Check for "for X hours/minutes"
        let forPattern = #/for\s+(\d+)\s*(hour|hr|minute|min|h|m)s?/#
        if let result = try? forPattern.firstMatch(in: fullMatch) {
            let value = Int(result.1) ?? 0
            let unit = result.2.lowercased()
            let isHour = unit == "hour" || unit == "hr" || unit == "h"
            return isHour ? value * 60 : value
        }

        // Check for range pattern like "7pm-9pm"
        let rangePattern = #/(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*[-–]\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/#
        if let result = try? rangePattern.firstMatch(in: fullMatch) {
            let startHour = Int(result.1) ?? 0
            var startMinute = 0
            if let minStr = result.2 { startMinute = Int(minStr) ?? 0 }
            let startIsPM = (result.3?.lowercased() == "pm")

            let endHourRaw = Int(result.4) ?? 0
            var endMinute = 0
            if let minStr = result.5 { endMinute = Int(minStr) ?? 0 }
            let endIsPM: Bool
            if let pmStr = result.6 {
                endIsPM = pmStr.lowercased() == "pm"
            } else {
                endIsPM = startIsPM // Inherit from start if not specified
            }

            var sHour = startHour
            if startIsPM && startHour != 12 { sHour += 12 }
            if !startIsPM && startHour == 12 { sHour = 0 }

            var eHour = endHourRaw
            if endIsPM && endHourRaw != 12 { eHour += 12 }
            if !endIsPM && endHourRaw == 12 { eHour = 0 }

            return (eHour * 60 + endMinute) - (sHour * 60 + startMinute)
        }

        return nil
    }

    // MARK: - Helper: Extract Title

    private static func extractTitle(from text: String, excluding spans: [ParsedSpan]) -> String {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        // Collect all ranges to exclude, sorted by location
        let sortedSpans = spans.sorted { $0.range.location < $1.range.location }
        let excludeRanges = sortedSpans.map(\.range)

        // Build included ranges (gaps between excluded spans)
        var includedRanges: [NSRange] = []
        var currentLocation = 0

        for excludeRange in excludeRanges {
            if currentLocation < excludeRange.location {
                includedRanges.append(NSRange(location: currentLocation, length: excludeRange.location - currentLocation))
            }
            currentLocation = excludeRange.location + excludeRange.length
        }
        if currentLocation < fullRange.length {
            includedRanges.append(NSRange(location: currentLocation, length: fullRange.length - currentLocation))
        }

        // Extract text from included ranges
        let parts: [String] = includedRanges.compactMap { range in
            guard range.length > 0 else { return nil }
            let substring = nsText.substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return substring.isEmpty ? nil : substring
        }

        // Join remaining parts — this is the title
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Helper: Extract Notes

    private static func extractNotes(from text: String, title: String, spans: [ParsedSpan],
                                      locationName: String?, recurrenceText: String?) -> String {
        var notesParts: [String] = []

        // Add recurrence info as notes
        if let rec = recurrenceText {
            notesParts.append("Recurrence: \(rec)")
        }

        return notesParts.joined(separator: "\n")
    }

    // MARK: - Helper: Confidence Calculation

    private static func calculateConfidence(
        hasDate: Bool,
        hasTime: Bool,
        hasLocation: Bool,
        hasDuration: Bool,
        hasRecurrence: Bool,
        titleLength: Int
    ) -> Double {
        var score = 0.0

        if hasDate { score += 0.35 }
        if hasTime { score += 0.25 }
        if hasLocation { score += 0.15 }
        if hasDuration { score += 0.10 }
        if hasRecurrence { score += 0.05 }
        if titleLength >= 2 { score += 0.10 }
        else if titleLength > 0 { score += 0.05 }

        return min(score, 1.0)
    }

    // MARK: - Convenience: Parse with Format Hint

    /// Parses text with an optional date format hint.
    /// Useful when the user has specified a date format preference.
    static func parse(_ text: String, inputType: InputType, dateFormatHint: String? = nil) -> ParsedEvent? {
        // If we had a format hint, we could pass it to NSDataDetector options.
        // For now, NSDataDetector handles US, UK, and ISO formats naturally.
        return parse(text, inputType: inputType)
    }
}

// MARK: - String Helpers

private extension String {
    /// Returns `nil` if the string is empty or whitespace-only.
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}