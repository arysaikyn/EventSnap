import SwiftUI
import EventKit
import SwiftData

/// The critical verification screen. Shows the parsed event card with edit capabilities,
/// calendar picker, and confirm/add actions. Features stagger reveal animation.
/// Designed with premium Things 3 / Linear-style polish.
struct EventPreviewView: View {
    @Environment(EventCreationViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showInlineEditor: EventField?
    @State private var selectedCalendar: EKCalendar?
    @State private var calendars: [EKCalendar] = []
    @State private var isAddingToCalendar = false
    @State private var animateFields = false

    @FocusState private var focusedField: EventField?

    private var surface: Color {
        colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase
    }

    private var raisedSurface: Color {
        colorScheme == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: EventSpacing.xxl) {
                    // Drag indicator
                    Capsule()
                        .fill(Color.textQuaternary)
                        .frame(width: 36, height: 5)
                        .padding(.top, EventSpacing.sm)

                    // Event card with stagger animation
                    if let event = viewModel.parsedEvent {
                        EventCard(event: event, variant: .full) { field in
                            EventHaptics.tap()
                            withAnimation(EventAnimation.default_) {
                                if showInlineEditor == field {
                                    showInlineEditor = nil
                                } else {
                                    showInlineEditor = field
                                    focusedField = field
                                }
                            }
                        }
                        .staggerReveal(delay: 0, trigger: animateFields)
                        .padding(.horizontal, EventSpacing.pageMargin)

                        // Inline editors
                        if let editingField = showInlineEditor {
                            inlineEditor(for: editingField, event: event)
                                .padding(.horizontal, EventSpacing.pageMargin)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .staggerReveal(delay: 4, trigger: animateFields)
                        }

                        // Calendar picker
                        calendarPicker
                            .staggerReveal(delay: 5, trigger: animateFields)
                            .padding(.horizontal, EventSpacing.pageMargin)

                        // Action buttons
                        actionButtons
                            .staggerReveal(delay: 6, trigger: animateFields)
                            .padding(.horizontal, EventSpacing.pageMargin)
                            .padding(.bottom, EventSpacing.lg)

                        // Privacy line
                        PrivacyLine()
                            .staggerReveal(delay: 7, trigger: animateFields)
                    }

                    // Error state
                    if let error = viewModel.errorMessage {
                        HStack(spacing: EventSpacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.semanticError)
                            Text(error)
                                .font(EventTypography.footnote)
                                .foregroundStyle(Color.semanticError)
                        }
                        .padding(.horizontal, EventSpacing.md)
                        .padding(.vertical, EventSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: EventRadius.small)
                                .fill(Color.semanticError.opacity(0.1))
                        )
                        .padding(.horizontal, EventSpacing.pageMargin)
                        .staggerReveal(delay: 8, trigger: animateFields)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(surface.ignoresSafeArea())
            .onAppear {
                loadCalendars()
                triggerStaggerAnimation()
            }
            .onDisappear {
                animateFields = false
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.height > 100 {
                            EventHaptics.tap()
                            dismiss()
                        }
                    }
            )
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        EventHaptics.tap()
                        viewModel.reset()
                        dismiss()
                    }
                    .font(EventTypography.body)
                    .foregroundStyle(Color.textSecondary)
                    .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
                }
            }
        }
    }

    // MARK: - Calendar Picker

    private var calendarPicker: some View {
        VStack(alignment: .leading, spacing: EventSpacing.sm) {
            Text("Calendar")
                .font(EventTypography.subheadSemibold)
                .foregroundStyle(Color.textSecondary)

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
                                    .foregroundColor(
                                        selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                            ? Color(cgColor: calendar.cgColor)
                                            : (colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                                    )
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, EventSpacing.md)
                            .frame(height: EventSpacing.smallButtonHeight)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                            ? Color(cgColor: calendar.cgColor).opacity(0.12)
                                            : (colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                            ? Color(cgColor: calendar.cgColor).opacity(0.5)
                                            : (colorScheme == .dark ? Color.borderSubtleDark : Color.borderSubtle),
                                        lineWidth: selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier ? 1.5 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Calendar: \(calendar.title)")
                        .accessibilityAddTraits(selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier ? .isSelected : [])
                        .frame(minWidth: 44, minHeight: EventSpacing.smallButtonHeight)
                    }
                }
                .padding(.vertical, EventSpacing.xs)
            }
        }
        .padding(EventSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                .fill(raisedSurface)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.20 : 0.04),
            radius: 6, x: 0, y: 2
        )
    }

    // MARK: - Inline Editors

    @ViewBuilder
    private func inlineEditor(for field: EventField, event: ParsedEvent) -> some View {
        switch field {
        case .title:
            inlineTextEditor(
                title: "Edit Title",
                text: Binding(
                    get: { event.title },
                    set: { newValue in
                        var updated = event
                        updated.title = newValue
                        updated.uncertainFields.remove(.title)
                        viewModel.updateParsedEvent(updated)
                    }
                )
            )

        case .date:
            VStack(alignment: .leading, spacing: EventSpacing.sm) {
                Text("Edit Date")
                    .font(EventTypography.subheadSemibold)
                    .foregroundStyle(Color.textSecondary)

                DatePicker(
                    "Date",
                    selection: Binding(
                        get: { event.startDate },
                        set: { newValue in
                            let diff: TimeInterval
                            if let end = event.endDate {
                                diff = end.timeIntervalSince(event.startDate)
                            } else {
                                diff = 3600
                            }
                            var updated = event
                            updated.startDate = newValue
                            updated.endDate = newValue.addingTimeInterval(diff)
                            updated.uncertainFields.remove(.date)
                            updated.uncertainFields.remove(.time)
                            viewModel.updateParsedEvent(updated)
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.brandPrimary)
            }
            .padding(EventSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                    .fill(raisedSurface)
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.20 : 0.04),
                radius: 6, x: 0, y: 2
            )

        case .time:
            VStack(alignment: .leading, spacing: EventSpacing.sm) {
                Text("Edit Time")
                    .font(EventTypography.subheadSemibold)
                    .foregroundStyle(Color.textSecondary)

                DatePicker(
                    "Start",
                    selection: Binding(
                        get: { event.startDate },
                        set: { newValue in
                            var updated = event
                            updated.startDate = newValue
                            updated.uncertainFields.remove(.time)
                            viewModel.updateParsedEvent(updated)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .tint(Color.brandPrimary)

                if let end = event.endDate {
                    DatePicker(
                        "End",
                        selection: Binding(
                            get: { end },
                            set: { newValue in
                                var updated = event
                                updated.endDate = newValue
                                updated.uncertainFields.remove(.time)
                                viewModel.updateParsedEvent(updated)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .tint(Color.brandPrimary)
                }
            }
            .padding(EventSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                    .fill(raisedSurface)
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.20 : 0.04),
                radius: 6, x: 0, y: 2
            )

        case .location:
            inlineTextEditor(
                title: "Edit Location",
                text: Binding(
                    get: { event.location ?? "" },
                    set: { newValue in
                        var updated = event
                        updated.location = newValue.isEmpty ? nil : newValue
                        updated.uncertainFields.remove(.location)
                        viewModel.updateParsedEvent(updated)
                    }
                )
            )

        case .notes:
            inlineTextEditor(
                title: "Edit Notes",
                text: Binding(
                    get: { event.notes ?? "" },
                    set: { newValue in
                        var updated = event
                        updated.notes = newValue.isEmpty ? nil : newValue
                        updated.uncertainFields.remove(.notes)
                        viewModel.updateParsedEvent(updated)
                    }
                ),
                isMultiline: true
            )
        }
    }

    private func inlineTextEditor(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: EventSpacing.sm) {
            Text(title)
                .font(EventTypography.subheadSemibold)
                .foregroundStyle(Color.textSecondary)

            if isMultiline {
                TextEditor(text: text)
                    .font(EventTypography.body)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .notes)
                    .eventInput(isFocused: focusedField == .notes)
            } else {
                TextField("Enter \(title.lowercased())", text: text)
                    .font(EventTypography.body)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: title == "Edit Title" ? .title : .location)
                    .eventInput(isFocused: focusedField == .title || focusedField == .location)
            }
        }
        .padding(EventSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                .fill(raisedSurface)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.20 : 0.04),
            radius: 6, x: 0, y: 2
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: EventSpacing.md) {
            // Add to Calendar - primary
            Button {
                addToCalendar()
            } label: {
                HStack(spacing: EventSpacing.sm) {
                    if isAddingToCalendar {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    Text("Add to Calendar")
                        .font(EventTypography.bodyMedium)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isDisabled: isAddingToCalendar))
            .disabled(isAddingToCalendar)
            .accessibilityLabel("Add event to calendar")
            .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
        }
    }

    // MARK: - Actions

    private func loadCalendars() {
        if let cal = viewModel.parsedEvent?.calendar {
            selectedCalendar = cal
        }
    }

    private func addToCalendar() {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(EventAnimation.default_) {
                animateFields = true
            }
        }
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
        // Configure ViewModel for preview — assignments must be wrapped
        // to avoid Swift interpreting them as View expressions in @ViewBuilder
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