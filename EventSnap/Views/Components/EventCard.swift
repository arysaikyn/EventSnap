import SwiftUI

/// Reusable event card with two variants: full and compact.
/// Full variant includes all event fields; compact is a summarised row for confirmation.
struct EventCard: View {
    let event: ParsedEvent
    let variant: Variant
    let onTapField: ((EventField) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var surfaceColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }

    init(event: ParsedEvent, variant: Variant = .full, onTapField: ((EventField) -> Void)? = nil) {
        self.event = event
        self.variant = variant
        self.onTapField = onTapField
    }

    var body: some View {
        switch variant {
        case .full:
            fullCard
        case .compact:
            compactCard
        }
    }

    // MARK: - Full Card

    private var fullCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: category icon + title
            HStack(spacing: 12) {
                Image(systemName: eventCategoryIcon)
                    .font(.title2)
                    .foregroundColor(Color.accentPrimary)
                    .frame(width: 32, height: 32)

                Text(event.title)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapField?(.title)
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Event title: \(event.title)")

            Divider()
                .overlay(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))

            // Date & Time
            fieldRow(icon: "calendar", label: dateDisplay, field: .date)
            if event.endDate != nil {
                fieldRow(icon: "clock", label: timeDisplay, field: .time)
            }

            // Location
            if let location = event.location, !location.isEmpty {
                fieldRow(icon: "location.fill", label: location, field: .location)
            }

            // Notes
            if let notes = event.notes, !notes.isEmpty {
                fieldRow(icon: "note.text", label: notes, field: .notes)
            }

            // Uncertain fields
            ForEach(Array(event.uncertainFields), id: \.self) { field in
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(Color.accentPrimary)
                    Text(fieldDisplayName(field))
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color.accentPrimary)
                    Spacer()
                    Image(systemName: "hand.tap")
                        .font(.caption2)
                        .foregroundColor(Color.accentPrimary.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .onTapGesture {
                    onTapField?(field)
                }
                .accessibilityLabel("Uncertain \(fieldDisplayName(field)), tap to clarify")
            }
        }
        .padding(20)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        HStack(spacing: 12) {
            Image(systemName: eventCategoryIcon)
                .font(.title3)
                .foregroundColor(Color.accentPrimary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(compactDateDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func fieldRow(icon: String, label: String, field: EventField) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color.accentTeal)
                .frame(width: 24)

            Text(label)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if onTapField != nil {
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            onTapField?(field)
        }
        .accessibilityLabel("\(fieldDisplayName(field)): \(label)")
    }

    private var dateDisplay: String {
        let start = event.startDate.eventDisplayDate
        if let end = event.endDate {
            let startDay = event.startDate.eventDisplayDate
            let endDay = end.eventDisplayDate
            if startDay == endDay {
                return "\(startDay), \(timeDisplay)"
            }
            return "\(startDay) – \(endDay)"
        }
        return start
    }

    private var timeDisplay: String {
        let start = event.startDate.eventDisplayTime
        if let end = event.endDate {
            return "\(start) – \(end.eventDisplayTime)"
        }
        return start
    }

    private var compactDateDisplay: String {
        if let end = event.endDate {
            return "\(event.startDate.eventDisplayDateTime) – \(end.eventDisplayTime)"
        }
        return event.startDate.eventDisplayDateTime
    }

    private var eventCategoryIcon: String {
        // Simple heuristic based on title keywords
        let lower = event.title.lowercased()
        if lower.contains("meeting") || lower.contains("sync") { return "person.2.fill" }
        if lower.contains("party") || lower.contains("birthday") || lower.contains("celebration") { return "party.popper" }
        if lower.contains("dinner") || lower.contains("lunch") || lower.contains("breakfast") || lower.contains("food") { return "fork.knife" }
        if lower.contains("flight") || lower.contains("travel") || lower.contains("trip") { return "airplane" }
        if lower.contains("doctor") || lower.contains("dentist") || lower.contains("appointment") { return "cross.fill" }
        if lower.contains("gym") || lower.contains("workout") || lower.contains("fitness") { return "figure.run" }
        if lower.contains("concert") || lower.contains("show") || lower.contains("movie") { return "music.note" }
        return "calendar.badge.plus"
    }

    // MARK: - Variant

    enum Variant {
        case full
        case compact
    }
}

// MARK: - Field Display Names

private func fieldDisplayName(_ field: EventField) -> String {
    switch field {
    case .title: return "Title"
    case .date: return "Date"
    case .time: return "Time"
    case .location: return "Location"
    case .notes: return "Notes"
    }
}

#if DEBUG
struct EventCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                EventCard(
                    event: ParsedEvent(
                        title: "Team Sync Meeting",
                        startDate: Date(),
                        endDate: Date().addingTimeInterval(7200),
                        location: "Conference Room A",
                        notes: "Bring quarterly report",
                        calendar: nil,
                        confidence: 0.92,
                        uncertainFields: [.location],
                        sourceText: "Team sync meeting tomorrow at 2pm in Conference Room A",
                        inputType: .camera
                    ),
                    variant: .full
                )

                EventCard(
                    event: ParsedEvent(
                        title: "Dinner with Alex",
                        startDate: Date().addingTimeInterval(86400),
                        endDate: Date().addingTimeInterval(86400 + 5400),
                        location: nil,
                        notes: nil,
                        calendar: nil,
                        confidence: 0.85,
                        uncertainFields: [],
                        sourceText: "Dinner with Alex tomorrow at 7",
                        inputType: .voice
                    ),
                    variant: .compact
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
#endif