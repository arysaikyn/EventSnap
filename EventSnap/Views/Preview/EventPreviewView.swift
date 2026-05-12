import SwiftUI
import EventKit
import SwiftData

/// The critical verification screen. Shows the parsed event card with edit capabilities,
/// calendar picker, and confirm/add actions. Features stagger reveal animation.
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

    private let staggerDelay: Double = 0.08

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Drag indicator
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    // Event card with stagger animation
                    if let event = viewModel.parsedEvent {
                        EventCard(event: event, variant: .full) { field in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showInlineEditor = field
                            }
                        }
                        .opacity(animateFields ? 1 : 0)
                        .offset(y: animateFields ? 0 : 20)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(staggerDelay * 1),
                            value: animateFields
                        )
                        .padding(.horizontal, 16)

                        // Inline editors
                        if let editingField = showInlineEditor {
                            inlineEditor(for: editingField, event: event)
                                .padding(.horizontal, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Calendar picker
                        calendarPicker
                            .opacity(animateFields ? 1 : 0)
                            .offset(y: animateFields ? 0 : 16)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(staggerDelay * 6),
                                value: animateFields
                            )
                            .padding(.horizontal, 16)

                        // Privacy line
                        PrivacyLine()
                            .opacity(animateFields ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(staggerDelay * 7), value: animateFields)
                    }

                    // Error state
                    if let error = viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                    }

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .opacity(animateFields ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(staggerDelay * 8), value: animateFields)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                colorScheme == .dark ? Color(.systemGray6) : Color(.systemGroupedBackground)
            )
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
                            dismiss()
                        }
                    }
            )
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        viewModel.editEvent()
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(Color.accentPrimary)
                    .accessibilityLabel("Edit event details")
                    .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        viewModel.reset()
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    // MARK: - Calendar Picker

    private var calendarPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(calendars, id: \.calendarIdentifier) { calendar in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCalendar = calendar
                                if var event = viewModel.parsedEvent {
                                    event.calendar = calendar
                                    viewModel.updateParsedEvent(event)
                                }
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(cgColor: calendar.cgColor))
                                    .frame(width: 10, height: 10)

                                Text(calendar.title)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(
                                Capsule()
                                    .fill(selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                        ? Color(cgColor: calendar.cgColor).opacity(0.15)
                                        : Color.clear
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier
                                            ? Color(cgColor: calendar.cgColor)
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Calendar: \(calendar.title)")
                        .accessibilityAddTraits(selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier ? .isSelected : [])
                        .frame(minWidth: 44, minHeight: 36)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
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
                        // Remove from uncertain if it was there
                        updated.uncertainFields.remove(.title)
                        viewModel.updateParsedEvent(updated)
                    }
                )
            )

        case .date:
            VStack(alignment: .leading, spacing: 8) {
                Text("Edit Date")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

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
                        .tint(Color.accentPrimary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
            )

        case .time:
            VStack(alignment: .leading, spacing: 8) {
                Text("Edit Time")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

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
                .tint(Color.accentPrimary)

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
                .tint(Color.accentPrimary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

                if isMultiline {
                    TextEditor(text: text)
                        .font(.body)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentPrimary.opacity(0.5), lineWidth: 1)
                        )
            } else {
                TextField("Enter \(title.lowercased())", text: text)
                    .font(.body)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentPrimary.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Add to Calendar - primary
            Button {
                addToCalendar()
            } label: {
                HStack(spacing: 8) {
                    if isAddingToCalendar {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                    Text("Add to Calendar")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isAddingToCalendar ? Color.gray : Color.accentPrimary)
                )
            }
            .buttonStyle(.plain)
            .disabled(isAddingToCalendar)
            .accessibilityLabel("Add event to calendar")
            .frame(minWidth: 44, minHeight: 44)

            // Edit
            Button {
                viewModel.editEvent()
            } label: {
                Text("Edit Details")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(Color.accentPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentPrimary, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit event details")
            .frame(minWidth: 44, minHeight: 44)
        }
    }

    // MARK: - Actions

    private func loadCalendars() {
        // Load from environment or CalendarService
        if let event = viewModel.parsedEvent, let cal = event.calendar {
            selectedCalendar = cal
        }
        // In production, load from EKEventStore
        // calendars = calendarService.getCalendars()
        // For now, a placeholder will be replaced by real CalendarService
    }

    private func addToCalendar() {
        isAddingToCalendar = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            // Ensure calendar permission
            let granted = await permissionManager.requestCalendarAccess()
            guard granted else {
                await MainActor.run {
                    isAddingToCalendar = false
                    viewModel.errorMessage = "Calendar access is required to add events."
                }
                return
            }

            await viewModel.confirmEvent()
            await MainActor.run {
                isAddingToCalendar = false
                if case .completed = viewModel.state {
                    let haptic = UINotificationFeedbackGenerator()
                    haptic.notificationOccurred(.success)
                }
            }
        }
    }

    private func triggerStaggerAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.3)) {
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
        // Would set vm.state = .preview(event)

        EventPreviewView()
            .environment(vm)
            .environment(PermissionManager())
    }
}
#endif