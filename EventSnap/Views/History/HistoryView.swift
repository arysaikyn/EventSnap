import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers

/// History view — premium event cards with visual hierarchy, colored accent bars,
/// and a rich empty state with CTA. Groups events by date with section headers.
struct HistoryView: View {
    @Environment(HistoryViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var style
    @State private var isSearchActive = false
    @State private var eventToDelete: EventHistory?
    @State private var eventToShare: EventHistory?
    @State private var appeared = false
    var onNavigateToCapture: (() -> Void)?

    // Reusable date formatters to avoid recreation on every call
    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    // MARK: - Body

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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
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
                withAnimation(.spring()) {
                    isSearchActive.toggle()
                }
                EventHaptics.tap()
            } label: {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .font(EventTypography.body)
                        .foregroundStyle(isSearchActive ? Color.textTertiary : Color.brandPrimary)
                        .frame(width: EventSpacing.touchTarget, height: EventSpacing.touchTarget)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .alert("Delete Event?", isPresented: .init(
            get: { eventToDelete != nil },
            set: { if !$0 { eventToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { eventToDelete = nil }
            Button("Delete", role: .destructive) {
                EventHaptics.tap()
                if let e = eventToDelete {
                    viewModel.deleteEvent(e)
                }
                eventToDelete = nil
            }
        } message: {
            if let e = eventToDelete {
                Text("\"\(e.title)\" will be removed from your history.")
            }
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: EventSpacing.lg) {
                ForEach(viewModel.sectionDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: EventSpacing.sm) {
                        // Section header with event count badge
                        dateHeader(date, count: viewModel.events(for: date).count)

                        // Event cards
                        ForEach(Array(viewModel.events(for: date).enumerated()), id: \.element.id) { idx, event in
                            eventCard(event)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8)
                                        .delay(Double(idx) * 0.05),
                                    value: appeared
                                )
                        }
                    }
                    .padding(.horizontal, EventSpacing.pageMargin)
                }
            }
            .padding(.top, EventSpacing.md)
            .padding(.bottom, EventSpacing.floatingButtonPadding)
        }
        .background(style == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
        .refreshable { viewModel.refresh() }
    }

    // MARK: - Date Header with Badge

    private func dateHeader(_ date: Date, count: Int) -> some View {
        HStack(spacing: EventSpacing.sm) {
            Text(dateHeaderLabel(for: date))
                .font(EventTypography.footnoteSemibold)
                .foregroundStyle(Color.textTertiary)

            // Event count badge
            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, EventSpacing.xs)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(style == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
                )
        }
    }

    // MARK: - Premium Event Card

    private func eventCard(_ event: EventHistory) -> some View {
        Button {
            EventHaptics.tap()
            viewModel.openInCalendar(event)
        } label: {
            HStack(spacing: EventSpacing.md) {
                // Colored accent bar
                iconColor(for: event)
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                    .clipShape(Capsule())

                // Icon with circular background
                Image(systemName: iconForEvent(event))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor(for: event))
                    .frame(width: EventSpacing.xl, height: EventSpacing.xl)
                    .background(
                        Circle()
                            .fill(iconColor(for: event).opacity(0.1))
                    )

                // Title + date
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(EventTypography.subheadSemibold)
                        .foregroundStyle(style == .dark ? Color.textPrimaryDark : Color.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.textTertiary)
                        Text(event.formattedDate)
                            .font(EventTypography.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textTertiary.opacity(0.5))
            }
            .padding(.vertical, EventSpacing.md) // Touch-target padding
            .padding(.trailing, EventSpacing.sm)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(style == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised)
                .shadow(
                    color: Color.black.opacity(style == .dark ? 0.15 : 0.06),
                    radius: style == .dark ? 6 : 4,
                    x: 0,
                    y: 2
                )
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { eventToDelete = event } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                EventHaptics.soft()
                eventToShare = event
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(Color.brandPrimary)
        }
        .sheet(item: $eventToShare) { event in
            shareSheet(for: event)
        }
    }

    // MARK: - Premium Empty State

    private var emptyStateView: some View {
        VStack(spacing: EventSpacing.xl) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.06))
                    .frame(width: 120, height: 120)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: appeared)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.brandPrimary)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)
            }

            // Title + subtitle
            VStack(spacing: EventSpacing.xs) {
                Text("No Events Yet")
                    .font(EventTypography.pageTitle)
                    .foregroundStyle(style == .dark ? Color.textPrimaryDark : Color.textPrimary)

                Text("Your first event will appear here.\nTap Snap to scan an event flyer.")
                    .font(EventTypography.subheadline)
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // CTA button
            if let onNavigateToCapture {
                Button {
                    EventHaptics.tap()
                    onNavigateToCapture()
                } label: {
                    HStack(spacing: EventSpacing.sm) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 16, weight: .medium))
                        Text("Try Camera")
                            .font(EventTypography.subheadSemibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: EventSpacing.inputHeight)
                    .background(
                        Capsule()
                            .fill(Color.brandPrimary)
                            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, EventSpacing.xxl)
            }

            Spacer()
        }
        .padding(.horizontal, EventSpacing.xxl)
        .background(style == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
    }

    // MARK: - Share Sheet

    private func shareSheet(for event: EventHistory) -> some View {
        ShareSheet(items: shareItems(for: event))
    }

    private func shareItems(for event: EventHistory) -> [Any] {
        do {
            let data = try ICSExportService.generate(from: event)
            let doc = ICSFile(data: data)
            return [doc]
        } catch {
            return ["Failed to generate calendar file: \(error.localizedDescription)"]
        }
    }

    // MARK: - Helpers

    private func dateHeaderLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return Self.todayFormatter.string(from: date)
    }

    private func iconForEvent(_ event: EventHistory) -> String {
        let l = event.title.lowercased()
        if l.contains("meeting") || l.contains("sync") { return "person.2.fill" }
        if l.contains("party") || l.contains("birthday") { return "party.popper.fill" }
        if l.contains("dinner") || l.contains("lunch") { return "fork.knife" }
        if l.contains("flight") || l.contains("travel") { return "airplane" }
        if l.contains("doctor") { return "cross.fill" }
        return "calendar.badge.clock"
    }

    private func iconColor(for event: EventHistory) -> Color {
        let l = event.title.lowercased()
        if l.contains("meeting") || l.contains("sync") { return .brandSecondary }
        if l.contains("party") || l.contains("birthday") { return .semanticSuccess }
        if l.contains("dinner") || l.contains("lunch") { return .brandAccent }
        if l.contains("flight") || l.contains("travel") { return .cyan }
        if l.contains("doctor") { return .semanticError }
        return .brandPrimary
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let activityItems: [UIActivity] = []
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: activityItems
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ICS File Wrapper for UIActivityViewController

struct ICSFile: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let content = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = content
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
