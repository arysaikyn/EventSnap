import SwiftUI
import SwiftData
#if canImport(EventKitUI)
import EventKitUI
#endif

/// Chronological list of added events with search, grouping, swipe-to-delete,
/// and context menus.
struct HistoryView: View {
    @Environment(HistoryViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var isSearchActive = false
    @State private var showEmptyState = false
    @State private var selectedEvent: EventHistory?

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
                    withAnimation(.spring(response: 0.3)) {
                        isSearchActive.toggle()
                    }
                } label: {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.body)
                        .foregroundColor(Color.accentPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(isSearchActive ? "Close search" : "Search events")
                .frame(minWidth: 44, minHeight: 44)
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
                                    withAnimation {
                                        viewModel.deleteEvent(event)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button {
                                    viewModel.openInCalendar(event)
                                } label: {
                                    Label("Open in Calendar", systemImage: "calendar")
                                }

                                Button {
                                    shareEvent(event)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Divider()

                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteEvent(event)
                                    }
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
            openEvent(event)
        } label: {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: iconForEvent(event))
                    .font(.title3)
                    .foregroundColor(Color.accentPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentPrimary.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(event.formattedDate)
                        .font(.callout)
                        .foregroundColor(.secondary)

                    if let location = event.location, !location.isEmpty {
                        Label(location, systemImage: "location.fill")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Input type indicator
                inputTypeBadge(event.inputType)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel("\(event.title), \(event.formattedDate)")
    }

    // MARK: - Section Header

    private func sectionHeader(for date: Date) -> some View {
        HStack(spacing: 6) {
            if Calendar.current.isDateInToday(date) {
                Image(systemName: "sun.max.fill")
                    .font(.caption)
                    .foregroundColor(Color.accentPrimary)
                Text("Today")
                    .font(.subheadline.weight(.semibold))
            } else if Calendar.current.isDateInYesterday(date) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Yesterday")
                    .font(.subheadline.weight(.semibold))
            } else {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(dateFormatter.string(from: date))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .foregroundColor(.primary)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(Color.accentPrimary.opacity(0.5))

            Text("No events yet")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)

            Text("Events you create will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                // Switch to capture tab - handled by parent coordinator
            } label: {
                Label("Try Camera", systemImage: "camera.viewfinder")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(Color.accentPrimary)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityLabel("Try camera input")
            .frame(minWidth: 44, minHeight: 44)

            Spacer()
        }
        .padding(32)
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

    private func inputTypeBadge(_ inputType: InputType?) -> some View {
        Group {
            if let type = inputType {
                Text(type.rawValue.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(badgeColor(for: type))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(badgeColor(for: type).opacity(0.12))
                    )
            }
        }
    }

    private func badgeColor(for type: InputType) -> Color {
        switch type {
        case .camera: return Color.accentPrimary
        case .voice: return Color.accentTeal
        case .text: return Color.privacyGreen
        }
    }

    private func openEvent(_ event: EventHistory) {
        // Try to open in EKEventViewController
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