import SwiftUI
import SwiftData

/// Success screen after calendar save.
/// Orchestrated entry: ring pulse → AnimatedCheckmark → scale-in card → ConfettiBurst → auto-dismiss.
struct EventConfirmationView: View {
    @Environment(EventCreationViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var ringScale: CGFloat = 0.0
    @State private var checkmarkAppeared = false
    @State private var showContent = false
    @State private var confettiActive = false
    @State private var autoDismissTask: Task<Void, Never>?

    private let autoDismissDelay: TimeInterval = 8.0

    var body: some View {
        ZStack {
            // Background — soft mesh gradient
            (colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
                .ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color.brandPrimary.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            .opacity(showContent ? 1 : 0)
            .animation(.easeIn(duration: 0.8), value: showContent)

            VStack(spacing: 0) {
                // Center success card
                Spacer()

                successCard
                    .padding(.horizontal, EventSpacing.xxl)

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.horizontal, EventSpacing.xxl)
                    .padding(.bottom, EventSpacing.massive)
            }

            // Confetti overlay
            if confettiActive {
                ConfettiBurst(isPlaying: true, count: 14)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            EventHaptics.success()
            triggerEntryAnimations()
            startAutoDismissTimer()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
        .onTapGesture {
            resetAutoDismissTimer()
        }
    }

    // MARK: - Success Card

    private var successCard: some View {
        EventGlass.card {
            VStack(spacing: EventSpacing.xxl) {
                // Animated checkmark with success ring
                successRing

                // Headline
                Text("Added to Calendar")
                    .font(EventTypography.pageTitle)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)

                // Mini event card
                if let event = viewModel.parsedEvent {
                    compactEventCard(event: event)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: EventRadius.small)
                                .stroke(Color.semanticSuccess.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, EventSpacing.md)
    }

    // MARK: - Success Ring + Checkmark

    private var successRing: some View {
        ZStack {
            // Outer success glow (pulsing)
            Circle()
                .fill(Color.semanticSuccess.opacity(0.08))
                .frame(width: 160, height: 160)
                .scaleEffect(checkmarkAppeared ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.3),
                    value: checkmarkAppeared
                )

            // Expanding ring
            Circle()
                .stroke(Color.semanticSuccess.opacity(0.15), lineWidth: 2)
                .frame(width: 140, height: 140)
                .scaleEffect(ringScale)
                .opacity(ringScale > 0 ? 1 : 0)

            // Checkmark
            if checkmarkAppeared {
                AnimatedCheckmark(strokeColor: .semanticSuccess, lineWidth: 4)
            }
        }
        .frame(width: 160, height: 160)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.semanticSuccess.opacity(0.06),
                            Color.semanticSuccess.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Compact Event Card

    private func compactEventCard(event: ParsedEvent) -> some View {
        VStack(alignment: .leading, spacing: EventSpacing.sm) {
            // Title — bold, truncated
            Text(event.title)
                .font(EventTypography.subheadSemibold)
                .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                .lineLimit(1)

            Divider()
                .opacity(0.3)

            // Date + Time row
            eventDetail(icon: "calendar", text: formatFullDate(event.startDate))

            if let location = event.location {
                eventDetail(icon: "location", text: location)
            }
        }
        .padding(EventSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.small)
                .fill(colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
        )
    }

    private func eventDetail(icon: String, text: String) -> some View {
        HStack(spacing: EventSpacing.sm) {
            Image(systemName: icon)
                .font(EventTypography.caption)
                .foregroundStyle(Color.textTertiary)
                .frame(width: EventSpacing.lg)

            Text(text)
                .font(EventTypography.subheadline)
                .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: EventSpacing.sm) {
            // Done — primary
            Button("Done") {
                EventHaptics.tap()
                dismissAndReset()
            }
            .buttonStyle(EnhancedPrimaryButtonStyle(icon: "checkmark"))
            .frame(maxWidth: .infinity)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            HStack(spacing: EventSpacing.md) {
                // View in Calendar
                Button {
                    EventHaptics.tap()
                    openInCalendar()
                } label: {
                    Label("Calendar", systemImage: "calendar")
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                // Snap Another
                Button("Snap Another") {
                    EventHaptics.tap()
                    dismissAndReset()
                }
                .buttonStyle(IconButtonStyle())
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 16)
        }
    }

    // MARK: - Helpers

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Animations

    private func triggerEntryAnimations() {
        // Ring expands
        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0.3)
        ) {
            ringScale = 1.0
        }

        // Checkmark appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            checkmarkAppeared = true
            EventHaptics.success()
        }

        // Content fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(
                .spring(response: 0.4, dampingFraction: 0.75)
            ) {
                showContent = true
            }
        }

        // Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            confettiActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(EventAnimation.gentle) {
                    confettiActive = false
                }
            }
        }
    }

    // MARK: - Auto-dismiss

    private func startAutoDismissTimer() {
        autoDismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            dismissAndReset()
        }
    }

    private func resetAutoDismissTimer() {
        autoDismissTask?.cancel()
        startAutoDismissTimer()
    }

    // MARK: - Actions

    private func openInCalendar() {
        if case .completed(let history) = viewModel.state {
            let interval = history.startDate.timeIntervalSinceReferenceDate
            if let url = URL(string: "calshow:\(interval)") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func dismissAndReset() {
        viewModel.reset()
        dismiss()
    }
}

#if DEBUG
struct EventConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: EventHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let vm = EventCreationViewModel(
            calendarService: CalendarService(),
            ocrService: OCRService(),
            speechService: SpeechService(),
            modelContext: container.mainContext
        )

        EventConfirmationView()
            .environment(vm)
    }
}
#endif
