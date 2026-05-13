import SwiftUI
import SwiftData
#if canImport(EventKitUI)
import EventKitUI
#endif

/// Chronological list of added events with search, grouping, swipe-to-delete,
/// and context menus. Premium design using the EventSnap design system.
struct HistoryView: View {
    @Environment(HistoryViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var isSearchActive = false
    @State private var selectedEvent: EventHistory?
    @State private var eventToDelete: EventHistory?

    /// Called when the user wants to switch to the capture tab from empty state.
    var onNavigateToCapture: (() -> Void)?

    private var surface: AdaptiveSurface {
        AdaptiveSurface(scheme: colorScheme)
    }

    var body: some View {
        Group {
            if viewModel.filteredEvents.isEmpty && !viewModel.isSearching {
                emptyStateView
            } else {
                listContent
            }
        }
        .onAppear {
            viewModel.loadEvents()
        }
        .searchable(
            text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.searchQuery = $0 }
            ),
            isPresented: $isSearchActive,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search events..."
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    EventHaptics.tap()
                    withAnimation(EventAnimation.quick) {
                        isSearchActive.toggle()
                    }
                } label: {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.body.weight(.medium))
                        .foregroundStyle(isSearchActive ? Color.textSecondary : Color.brandPrimary)
                        .frame(width: EventSpacing.touchTarget, height: EventSpacing.touchTarget)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(isSearchActive ? "Close search" : "Search events")
            }
        }
        .tint(Color.brandPrimary)
        .alert("Delete Event?", isPresented: Binding(
            get: { eventToDelete != nil },
            set: { if !$0 { eventToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { eventToDelete = nil }
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    withAnimation(EventAnimation.default_) {
                        viewModel.deleteEvent(event)
                    }
                    eventToDelete = nil
                }
            }
        } message: {
            if let event = eventToDelete {
                Text("\"\(event.title)\" will be removed from your history.")
            }
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            ForEach(viewModel.sectionDates, id: \.self) { date in
                Section {
                    ForEach(viewModel.events(for: date)) { event in
                        eventRow(event)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    EventHaptics.heavy()
                                    eventToDelete = event
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(Color.semanticError)
                            }
                            .contextMenu {
                                Button {
                                    EventHaptics.press()
                                    viewModel.openInCalendar(event)
                                } label: {
                                    Label("Open in Calendar", systemImage: "calendar")
                                }

                                Button {
                                    EventHaptics.press()
                                    shareEvent(event)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    EventHaptics.heavy()
                                    eventToDelete = event
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    sectionHeader(for: date)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(surface.background)
        .refreshable {
            viewModel.refresh()
        }
        .overlay {
            if viewModel.isSearching && viewModel.filteredEvents.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term")
                )
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: EventHistory) -> some View {
        Button {
            EventHaptics.tap()
            openEvent(event)
        } label: {
            HStack(spacing: EventSpacing.lg) {
                // Category icon in subtle colored circle
                ZStack {
                    Circle()
                        .fill(iconColor(for: event).opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: iconForEvent(event))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor(for: event))
                }

                // Title + details
                VStack(alignment: .leading, spacing: EventSpacing.xs) {
                    Text(event.title)
                        .font(EventTypography.subheadSemibold)
                        .foregroundColor(surface.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(surface.textTertiary)
                        Text(event.formattedDate)
                            .font(EventTypography.footnote)
                            .foregroundColor(surface.textSecondary)
                    }

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundStyle(surface.textTertiary)
                            Text(location)
                                .font(EventTypography.caption)
                                .foregroundColor(surface.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: EventSpacing.md)

                // Input type badge
                inputTypeBadge(event.inputType)
            }
            .padding(.vertical, EventSpacing.sm)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: EventSpacing.lg,
            bottom: 0,
            trailing: EventSpacing.lg
        ))
        .listRowSeparator(.hidden)
        .listRowBackground(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(surface.raised)
                .padding(.horizontal, EventSpacing.sm)
                .padding(.vertical, 3)
        )
        .frame(minHeight: EventSpacing.touchTarget)
        .accessibilityLabel("\(event.title), \(event.formattedDate)")
        .accessibilityHint("Double-tap to open in Calendar")
    }

    // MARK: - Section Header

    private func sectionHeader(for date: Date) -> some View {
        HStack(spacing: EventSpacing.sm) {
            if Calendar.current.isDateInToday(date) {
                Image(systemName: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(Color.brandPrimary)
                Text("Today")
                    .font(EventTypography.subheadSemibold)
                    .foregroundColor(surface.textPrimary)
            } else if Calendar.current.isDateInYesterday(date) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondary)
                Text("Yesterday")
                    .font(EventTypography.subheadSemibold)
                    .foregroundColor(surface.textPrimary)
            } else {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(surface.textTertiary)
                Text(dateFormatter.string(from: date))
                    .font(EventTypography.subheadSemibold)
                    .foregroundColor(surface.textPrimary)
            }

            Spacer()

            // Event count badge
            let count = viewModel.events(for: date).count
            Text("\(count)")
                .font(EventTypography.caption2)
                .foregroundStyle(surface.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(surface.subtle)
                )
        }
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: EventSpacing.lg,
            bottom: 0,
            trailing: EventSpacing.lg
        ))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: EventSpacing.xxl) {
            Spacer()

            // Large icon in a soft circle
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.brandPrimary.opacity(0.6))
            }

            VStack(spacing: EventSpacing.sm) {
                Text("No events yet")
                    .font(EventTypography.sectionTitle)
                    .foregroundColor(surface.textPrimary)

                Text("Events you create will appear here")
                    .font(EventTypography.body)
                    .foregroundColor(surface.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                EventHaptics.press()
                onNavigateToCapture?()
            } label: {
                Label("Create First Event", systemImage: "camera.viewfinder")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, EventSpacing.massive)
            .padding(.top, EventSpacing.sm)
            .accessibilityLabel("Try camera input")

            Spacer()
        }
        .padding(EventSpacing.huge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surface.background)
    }

    // MARK: - Helpers

    private func iconForEvent(_ event: EventHistory) -> String {
        let lower = event.title.lowercased()
        if lower.contains("meeting") || lower.contains("sync") { return "person.2.fill" }
        if lower.contains("party") || lower.contains("birthday") || lower.contains("celebration") { return "party.popper" }
        if lower.contains("dinner") || lower.contains("lunch") || lower.contains("food") { return "fork.knife" }
        if lower.contains("flight") || lower.contains("travel") || lower.contains("trip") { return "airplane" }
        if lower.contains("doctor") || lower.contains("appointment") { return "cross.fill" }
        if lower.contains("concert") || lower.contains("show") || lower.contains("movie") { return "music.note" }
        return "calendar.badge.plus"
    }

    private func iconColor(for event: EventHistory) -> Color {
        let lower = event.title.lowercased()
        if lower.contains("meeting") || lower.contains("sync") { return Color.brandPrimary }
        if lower.contains("party") || lower.contains("birthday") || lower.contains("celebration") { return Color.semanticSuccess }
        if lower.contains("dinner") || lower.contains("lunch") || lower.contains("food") { return Color.brandSecondary }
        if lower.contains("flight") || lower.contains("travel") || lower.contains("trip") { return Color.brandPrimary }
        if lower.contains("doctor") || lower.contains("appointment") { return Color.semanticError }
        if lower.contains("concert") || lower.contains("show") || lower.contains("movie") { return Color.brandSecondary }
        return Color.brandPrimary
    }

    private func inputTypeBadge(_ inputType: InputType?) -> some View {
        Group {
            if let type = inputType {
                Text(type.rawValue.capitalized)
                    .font(EventTypography.caption2)
                    .foregroundStyle(badgeColor(for: type))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(badgeColor(for: type).opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(badgeColor(for: type).opacity(0.2), lineWidth: 0.5)
                    )
            }
        }
    }

    private func badgeColor(for type: InputType) -> Color {
        switch type {
        case .camera: return Color.brandPrimary
        case .voice:  return Color.brandSecondary
        case .text:   return Color.semanticSuccess
        }
    }

    private func openEvent(_ event: EventHistory) {
        viewModel.openInCalendar(event)
    }

    private func shareEvent(_ event: EventHistory) {
        let text = "\(event.title) - \(event.formattedDate)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()
}

#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: EventHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        NavigationStack {
            HistoryView()
                .environment(HistoryViewModel(
                    modelContext: container.mainContext,
                    calendarService: CalendarService()
                ))
                .navigationTitle("History")
        }
    }
}
#endif