import SwiftUI
import EventKit
import SwiftData
import UniformTypeIdentifiers

/// The critical verification screen — where parsed data meets user confidence.
/// Mesh gradient header, glass field cards with staggered reveal, inline editing.
/// Inspired by Things 3's clarity and Linear's precision.
struct EventPreviewView: View {
    @Environment(EventCreationViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(CalendarService.self) private var calendarService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showInlineEditor: EventField?
    @State private var selectedCalendar: EKCalendar?
    @State private var calendars: [EKCalendar] = []
    @State private var isAddingToCalendar = false
    @State private var showShareSheet = false
    @State private var animateFields = false
    @State private var calendarLoading = false
    @State private var conflicts: [CalendarService.ConflictInfo] = []
    @State private var showConflictAlert = false

    @FocusState private var focusedField: EventField?

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Drag indicator
                    Capsule()
                        .fill(Color.textQuaternary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, EventSpacing.md)
                        .padding(.bottom, EventSpacing.lg)

                    // Event details header
                    if let event = viewModel.parsedEvent {
                        eventHeader(event: event)
                            .padding(.horizontal, EventSpacing.pageMargin)
                            .opacity(animateFields ? 1 : 0)
                            .offset(y: animateFields ? 0 : 12)

                        Divider()
                            .padding(.horizontal, EventSpacing.pageMargin)
                            .opacity(animateFields ? 0.5 : 0)
                            .padding(.vertical, EventSpacing.md)

                        // Field cards
                        fieldCards(for: event)
                            .padding(.horizontal, EventSpacing.pageMargin)

                        // Inline editor
                        if let editingField = showInlineEditor {
                            inlineEditor(for: editingField, event: event)
                                .padding(.horizontal, EventSpacing.pageMargin)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        }

                        // Calendar picker
                        calendarPicker
                            .padding(.horizontal, EventSpacing.pageMargin)
                            .padding(.top, EventSpacing.xl)

                        // Action buttons
                        actionButtons
                            .padding(.horizontal, EventSpacing.pageMargin)
                            .padding(.top, EventSpacing.xxl)
                            .padding(.bottom, EventSpacing.lg)
                    }

                    // Error state
                    if let error = viewModel.errorMessage {
                        errorBanner(error: error)
                            .padding(.horizontal, EventSpacing.pageMargin)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            loadCalendarsOrRequestAccess()
            triggerStaggerAnimation()
        }
        .onDisappear {
            animateFields = false
        }
        .sheet(isPresented: $showShareSheet) {
            shareSheetContent
        }
        .alert("Schedule Conflict", isPresented: $showConflictAlert) {
            Button("Cancel", role: .cancel) {
                EventHaptics.tap()
            }
            Button("Add Anyway") {
                EventHaptics.tap()
                conflicts = []
                performCalendarSave()
            }
        } message: {
            VStack(alignment: .leading, spacing: EventSpacing.sm) {
                Text("This event overlaps with the following:")
                ForEach(conflicts) { conflict in
                    Text("• \(conflict.displayText)")
                        .font(EventTypography.footnote)
                }
                Text("\nYou can add it anyway or edit the time first.")
                    .font(EventTypography.caption)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    EventHaptics.tap()
                    viewModel.reset()
                    dismiss()
                }
                .font(EventTypography.body)
                .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - Event Header with Premium Confidence

    private func eventHeader(event: ParsedEvent) -> some View {
        VStack(alignment: .leading, spacing: EventSpacing.md) {
            // Title first
            Text(event.title)
                .font(EventTypography.pageTitle)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .allowsTightening(false)

            HStack(spacing: EventSpacing.sm) {
                // Sparkles + label
                Image(systemName: "sparkles")
                    .font(EventTypography.captionMedium)
                    .foregroundStyle(Color.brandAccent)
                Text("Parsed on device")
                    .font(EventTypography.caption)
                    .foregroundStyle(Color.textTertiary)

                Spacer()

                // Confidence visualization: pill with icon + progress bar
                confidencePill(confidence: event.confidence)
            }
        }
        .padding(.top, EventSpacing.md)
    }

    // MARK: - Confidence Pill

    private func confidencePill(confidence: Double) -> some View {
        let percentage = Int(confidence * 100)
        let color = confidenceColor(for: confidence)

        return HStack(spacing: EventSpacing.xs) {
            // Mini progress track
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 32 * confidence, height: 4)
            }

            Text("\(percentage)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, EventSpacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Field Cards

    private func fieldCards(for event: ParsedEvent) -> some View {
        VStack(spacing: EventSpacing.sm) {
            fieldCard(icon: "calendar", label: "Date", value: formatDate(event.startDate), isUncertain: event.uncertainFields.contains(.date)) {
                withAnimation(EventAnimation.default_) { showInlineEditor = showInlineEditor == .date ? nil : .date }
            }

            fieldCard(icon: "clock", label: "Time", value: formatTime(event.startDate), isUncertain: event.uncertainFields.contains(.time)) {
                withAnimation(EventAnimation.default_) { showInlineEditor = showInlineEditor == .time ? nil : .time }
            }

            if let location = event.location {
                fieldCard(icon: "location", label: "Location", value: location, isUncertain: event.uncertainFields.contains(.location)) {
                    withAnimation(EventAnimation.default_) { showInlineEditor = showInlineEditor == .location ? nil : .location }
                }
            } else {
                fieldCard(icon: "location", label: "Location", value: "Tap to add", isUncertain: true, isPlaceholder: true) {
                    withAnimation(EventAnimation.default_) { showInlineEditor = showInlineEditor == .location ? nil : .location }
                }
            }

            if let notes = event.notes {
                fieldCard(icon: "note.text", label: "Notes", value: notes, isUncertain: false) {
                    withAnimation(EventAnimation.default_) { showInlineEditor = showInlineEditor == .notes ? nil : .notes }
                }
            }
        }
        .padding(.vertical, EventSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(colorScheme == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised)
        )
    }

    private func fieldCard(icon: String, label: String, value: String, isUncertain: Bool, isPlaceholder: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: EventSpacing.md) {
                Image(systemName: icon)
                    .font(EventTypography.body)
                    .foregroundStyle(isUncertain ? Color.semanticWarning : (colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary))
                    .frame(width: EventSpacing.lg)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(EventTypography.caption2)
                        .foregroundStyle(Color.textTertiary)
                    Text(value)
                        .font(EventTypography.body)
                        .foregroundStyle(
                            isPlaceholder
                                ? (colorScheme == .dark ? Color.textTertiaryDark : Color.textTertiary)
                                : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                        )
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if isUncertain && !isPlaceholder {
                    Text("Needs \(label.lowercased())")
                        .font(EventTypography.caption2)
                        .foregroundStyle(Color.semanticWarning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.semanticWarning.opacity(0.12))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(EventTypography.caption2)
                    .foregroundStyle(Color.textQuaternary)
            }
            .padding(.horizontal, EventSpacing.lg)
            .padding(.vertical, EventSpacing.md)
        }
        .buttonStyle(EventFieldButtonStyle())
    }

    // MARK: - Calendar Picker

    private var calendarPicker: some View {
        EventGlass.card {
            VStack(alignment: .leading, spacing: EventSpacing.sm) {
                Label("Calendar", systemImage: "calendar.badge.plus")
                    .font(EventTypography.subheadSemibold)
                    .foregroundStyle(Color.textSecondary)

                if calendarLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading calendars...")
                            .font(EventTypography.footnote)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.vertical, EventSpacing.xs)
                } else if calendars.isEmpty {
                    Button {
                        requestCalendarAccess()
                    } label: {
                        HStack(spacing: EventSpacing.sm) {
                            Image(systemName: "lock.shield")
                                .font(EventTypography.body)
                                .foregroundStyle(Color.brandPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Calendar Access")
                                    .font(EventTypography.subheadMedium)
                                    .foregroundStyle(Color.brandPrimary)
                                Text("EventSnap uses write-only access — we can't read your events")
                                    .font(EventTypography.caption2)
                                    .foregroundStyle(Color.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(EventTypography.caption2)
                                .foregroundStyle(Color.textQuaternary)
                        }
                        .padding(.horizontal, EventSpacing.md)
                        .padding(.vertical, EventSpacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: EventSpacing.sm) {
                            ForEach(calendars, id: \.calendarIdentifier) { calendar in
                                Button {
                                    EventHaptics.selection()
                                    withAnimation(EventAnimation.quick) {
                                        selectedCalendar = calendar
                                        if var event = viewModel.parsedEvent {
                                            event.calendar = calendar
                                            viewModel.updateParsedEvent(event)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: EventSpacing.xs) {
                                        Circle()
                                            .fill(Color(cgColor: calendar.cgColor))
                                            .frame(width: 10, height: 10)
                                        Text(calendar.title)
                                            .font(EventTypography.subheadMedium)
                                            .foregroundStyle(
                                                selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                                    ? Color(cgColor: calendar.cgColor)
                                                    : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                                            )
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, EventSpacing.md)
                                    .padding(.vertical, EventSpacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(
                                                selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                                    ? Color(cgColor: calendar.cgColor).opacity(0.12)
                                                    : (colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Inline Editors

    @ViewBuilder
    private func inlineEditor(for field: EventField, event: ParsedEvent) -> some View {
        VStack(alignment: .leading, spacing: EventSpacing.sm) {
            switch field {
            case .title:
                inlineTextField("Edit Title", binding: Binding(
                    get: { event.title },
                    set: { var e = event; e.title = $0; e.uncertainFields.remove(.title); viewModel.updateParsedEvent(e) }
                ))

            case .date:
                EventGlass.card {
                    VStack(alignment: .leading, spacing: EventSpacing.sm) {
                        Text("Edit Date").font(EventTypography.subheadSemibold).foregroundStyle(Color.textSecondary)
                        DatePicker("Date", selection: dateBinding(for: event), displayedComponents: .date)
                            .tint(Color.brandPrimary)
                    }
                }

            case .time:
                EventGlass.card {
                    VStack(alignment: .leading, spacing: EventSpacing.sm) {
                        Text("Edit Time").font(EventTypography.subheadSemibold).foregroundStyle(Color.textSecondary)
                        DatePicker("Start", selection: Binding(
                            get: { event.startDate },
                            set: { var e = event; e.startDate = $0; e.uncertainFields.remove(.time); viewModel.updateParsedEvent(e) }
                        ), displayedComponents: .hourAndMinute)
                        .tint(Color.brandPrimary)

                        if let end = event.endDate {
                            DatePicker("End", selection: Binding(
                                get: { end },
                                set: { var e = event; e.endDate = $0; e.uncertainFields.remove(.time); viewModel.updateParsedEvent(e) }
                            ), displayedComponents: .hourAndMinute)
                            .tint(Color.brandPrimary)
                        }
                    }
                }

            case .location:
                inlineTextField("Edit Location", binding: Binding(
                    get: { event.location ?? "" },
                    set: { var e = event; e.location = $0.isEmpty ? nil : $0; e.uncertainFields.remove(.location); viewModel.updateParsedEvent(e) }
                ))

            case .notes:
                inlineTextField("Edit Notes", binding: Binding(
                    get: { event.notes ?? "" },
                    set: { var e = event; e.notes = $0.isEmpty ? nil : $0; e.uncertainFields.remove(.notes); viewModel.updateParsedEvent(e) }
                ), isMultiline: true)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func inlineTextField(_ title: String, binding: Binding<String>, isMultiline: Bool = false) -> some View {
        EventGlass.card {
            VStack(alignment: .leading, spacing: EventSpacing.sm) {
                Text(title).font(EventTypography.subheadSemibold).foregroundStyle(Color.textSecondary)
                if isMultiline {
                    TextEditor(text: binding)
                        .font(EventTypography.body)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                        .eventInput(isFocused: focusedField == .notes)
                } else {
                    TextField("Enter \(title.lowercased())", text: binding)
                        .font(EventTypography.body)
                        .textFieldStyle(.plain)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                        .eventInput(isFocused: focusedField == .title || focusedField == .location || focusedField == .notes)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: EventSpacing.sm) {
            Button("Add to Calendar") { addToCalendar() }
                .buttonStyle(EnhancedPrimaryButtonStyle(isLoading: isAddingToCalendar, icon: "calendar.badge.plus"))
                .frame(maxWidth: .infinity)

            // Share button — only show if we have a valid event
            if let event = viewModel.parsedEvent, event.isReadyForCalendar {
                Button {
                    EventHaptics.selection()
                    showShareSheet = true
                } label: {
                    HStack(spacing: EventSpacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(EventTypography.body)
                        Text("Share as Calendar File")
                            .font(EventTypography.subheadMedium)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: EventSpacing.smallButtonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: EventRadius.medium)
                            .fill(Color.brandPrimary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }

            PrivacyLine()
                .padding(.top, EventSpacing.sm)
        }
    }

    // MARK: - Share Sheet

    private var shareSheetContent: some View {
        let items: [Any] = {
            guard let event = viewModel.parsedEvent else { return [] }
            do {
                let data = try ICSExportService.generate(from: event)
                let doc = ICSFile(data: data)
                return [doc]
            } catch {
                return ["Failed to generate calendar file: \(error.localizedDescription)"]
            }
        }()
        return ShareSheet(items: items)
    }

    // MARK: - Error Banner

    private func errorBanner(error: String) -> some View {
        HStack(spacing: EventSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(EventTypography.subheadMedium)
                .foregroundStyle(Color.semanticError)
            Text(error)
                .font(EventTypography.footnote)
                .foregroundStyle(Color.semanticError)
            Spacer()
        }
        .padding(.horizontal, EventSpacing.md)
        .padding(.vertical, EventSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.small)
                .fill(Color.semanticError.opacity(0.08))
        )
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func confidenceColor(for confidence: Double) -> Color {
        if confidence >= 0.8 { return .semanticSuccess }
        if confidence >= 0.5 { return .semanticWarning }
        return .semanticError
    }

    private func dateBinding(for event: ParsedEvent) -> Binding<Date> {
        Binding(
            get: { event.startDate },
            set: { newValue in
                let diff: TimeInterval = event.endDate.map { $0.timeIntervalSince(event.startDate) } ?? 3600
                var updated = event
                updated.startDate = newValue
                updated.endDate = newValue.addingTimeInterval(diff)
                updated.uncertainFields.remove(.date)
                updated.uncertainFields.remove(.time)
                viewModel.updateParsedEvent(updated)
            }
        )
    }

    // MARK: - Actions

    private func loadCalendarsOrRequestAccess() {
        if calendarService.isAccessGranted {
            loadCalendars()
        } else {
            requestCalendarAccess()
        }
    }

    private func loadCalendars() {
        calendars = calendarService.availableCalendars
        if let cal = viewModel.parsedEvent?.calendar {
            selectedCalendar = cal
        } else if let defaultCal = calendarService.defaultCalendar {
            selectedCalendar = defaultCal
        }
    }

    private func requestCalendarAccess() {
        calendarLoading = true
        Task { @MainActor in
            let granted = await permissionManager.requestCalendarAccess()
            await MainActor.run {
                calendarLoading = false
                if granted {
                    loadCalendars()
                } else {
                    viewModel.errorMessage = "Calendar access is required to add events."
                }
            }
        }
    }

    private func addToCalendar() {
        guard let event = viewModel.parsedEvent else { return }

        // Check for calendar conflicts before saving
        let foundConflicts = calendarService.findConflicts(for: event)
        if !foundConflicts.isEmpty {
            conflicts = foundConflicts
            showConflictAlert = true
            EventHaptics.warning()
            return
        }

        // No conflicts — proceed directly
        performCalendarSave()
    }

    /// Actually performs the calendar save (called after conflict check or user override)
    private func performCalendarSave() {
        isAddingToCalendar = true
        EventHaptics.press()

        Task {
            let granted = await permissionManager.requestCalendarAccess()
            guard granted else {
                isAddingToCalendar = false
                viewModel.errorMessage = "Calendar access is required to add events."
                return
            }

            await viewModel.confirmEvent()
            isAddingToCalendar = false
            if case .completed = viewModel.state {
                EventHaptics.success()
            }
        }
    }

    private func triggerStaggerAnimation() {
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            animateFields = true
        }
    }
}

// MARK: - Field Button Style

struct EventFieldButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? (colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
                    : Color.clear
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(EventAnimation.quick, value: configuration.isPressed)
    }
}

#if DEBUG
struct EventPreviewView_Previews: PreviewProvider {
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

        let container = try! ModelContainer(for: EventHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let vm = EventCreationViewModel(
            calendarService: CalendarService(),
            ocrService: OCRService(),
            speechService: SpeechService(),
            modelContext: container.mainContext
        )
        let _ = {
            vm.parsedEvent = event
            vm.state = .preview(event)
        }()

        EventPreviewView()
            .environment(vm)
            .environment(PermissionManager())
    }
}
#endif
