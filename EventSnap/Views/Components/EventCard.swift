import SwiftUI

/// Reusable event card with two variants: full and compact.
/// Typography-first, minimal color. Full variant for preview screen;
/// compact for confirmation and history rows.
struct EventCard: View {
    let event: ParsedEvent
    let variant: Variant
    let onTapField: ((EventField) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    init(event: ParsedEvent, variant: Variant = .full, onTapField: ((EventField) -> Void)? = nil) {
        self.event = event
        self.variant = variant
        self.onTapField = onTapField
    }

    enum Variant {
        case full
        case compact
    }

    var body: some View {
        switch variant {
        case .full:
            fullCard
        case .compact:
            compactCard
        }
    }

    // MARK: - Full Card (for preview screen)

    private var fullCard: some View {
        VStack(alignment: .leading, spacing: EventSpacing.lg) {
            // Header: icon + title
            HStack(spacing: EventSpacing.md) {
                Image(systemName: eventCategoryIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 32, height: 32)

                Text(event.title)
                    .font(EventTypography.pageTitle)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                    .lineLimit(2)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .onTapGesture { onTapField?(.title) }
            .accessibilityAddTraits(.isHeader)

            // Separator
            Rectangle()
                .fill(colorScheme == .dark ? Color.borderSubtleDark : Color.borderSubtle)
                .frame(height: 0.5)

            // Date & Time
            fieldRow(icon: "calendar", label: dateDisplay, field: .date)
            if event.endDate != nil {
                fieldRow(icon: "clock", label: timeDisplay, field: .time)
            }

            // Location
            if let location = event.location, !location.isEmpty {
                fieldRow(icon: "location.fill", label: location, field: .location)
            } else if event.uncertainFields.contains(.location) {
                fieldRow(icon: "location.fill", label: "tap to add location", field: .location)
            }

            // Notes
            if let notes = event.notes, !notes.isEmpty {
                fieldRow(icon: "note.text", label: notes, field: .notes)
            }

            // Uncertain fields — amber warning badges
            ForEach(Array(event.uncertainFields), id: \.self) { field in
                HStack(spacing: EventSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.semanticWarning)

                    Text("Needs \(fieldDisplayName(field))")
                        .font(EventTypography.captionMedium)
                        .foregroundStyle(Color.semanticWarning)

                    Spacer()

                    Image(systemName: "hand.tap")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.semanticWarning.opacity(0.6))
                }
                .padding(.horizontal, EventSpacing.md)
                .padding(.vertical, EventSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: EventRadius.small)
                        .fill(Color.semanticWarning.opacity(0.1))
                )
                .contentShape(Rectangle())
                .onTapGesture { onTapField?(field) }
                .accessibilityLabel("Needs \(fieldDisplayName(field)), tap to clarify")
            }
        }
        .padding(EventSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                .fill(colorScheme == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06),
            radius: colorScheme == .dark ? 12 : 8, x: 0, y: colorScheme == .dark ? 4 : 2
        )
    }

    // MARK: - Compact Card (for confirmation and history)

    private var compactCard: some View {
        HStack(spacing: EventSpacing.md) {
            Image(systemName: eventCategoryIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: EventSpacing.xs) {
                Text(event.title)
                    .font(EventTypography.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                    .lineLimit(1)

                Text(compactDateDisplay)
                    .font(EventTypography.subheadline)
                    .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary)

                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "location.fill")
                        .font(EventTypography.caption)
                        .foregroundStyle(colorScheme == .dark ? Color.textTertiaryDark : Color.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(EventTypography.caption2)
                .foregroundStyle(colorScheme == .dark ? Color.textTertiaryDark : Color.textTertiary)
        }
        .padding(EventSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(colorScheme == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.20 : 0.05),
            radius: 6, x: 0, y: 2
        )
    }

    // MARK: - Field Row

    private func fieldRow(icon: String, label: String, field: EventField) -> some View {
        HStack(spacing: EventSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.brandSecondary)
                .frame(width: 24)

            Text(label)
                .font(EventTypography.body)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if onTapField != nil {
                Image(systemName: "pencil")
                    .font(EventTypography.caption2)
                    .foregroundStyle(colorScheme == .dark ? Color.textTertiaryDark : Color.textTertiary)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture { onTapField?(field) }
    }

    // MARK: - Helpers

    private var eventCategoryIcon: String {
        let lower = event.title.lowercased()
        if lower.contains("meeting") || lower.contains("sync") { return "person.2.fill" }
        if lower.contains("party") || lower.contains("birthday") || lower.contains("celebration") { return "party.popper" }
        if lower.contains("dinner") || lower.contains("lunch") || lower.contains("food") { return "fork.knife" }
        if lower.contains("flight") || lower.contains("travel") || lower.contains("trip") { return "airplane" }
        if lower.contains("doctor") || lower.contains("appointment") { return "cross.case.fill" }
        if lower.contains("concert") || lower.contains("show") || lower.contains("movie") { return "music.note" }
        if lower.contains("class") || lower.contains("course") || lower.contains("workshop") { return "book.fill" }
        return "calendar.badge.plus"
    }

    private var dateDisplay: String {
        event.startDate.eventDisplayDate
    }

    private var timeDisplay: String {
        let start = event.startDate.eventDisplayTime
        if let end = event.endDate {
            return "\(start) – \(end.eventDisplayTime)"
        }
        return start
    }

    private var compactDateDisplay: String {
        event.startDate.eventDisplayDateTime
    }

    private func fieldDisplayName(_ field: EventField) -> String {
        switch field {
        case .title: return "title"
        case .date: return "date"
        case .time: return "time"
        case .location: return "location"
        case .notes: return "notes"
        }
    }
}

#if DEBUG
struct EventCard_Previews: PreviewProvider {
    static var previews: some View {
        let event = ParsedEvent(
            title: "Team Sync Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(7200),
            location: "Conference Room A",
            notes: "Bring quarterly report",
            calendar: nil,
            confidence: 0.85,
            uncertainFields: [.location],
            sourceText: "Team sync meeting tomorrow at 2pm",
            inputType: .camera
        )

        VStack(spacing: 20) {
            EventCard(event: event, variant: .full)
            EventCard(event: event, variant: .compact)
        }
        .padding()
    }
}
#endif