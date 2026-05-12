import SwiftUI
import UIKit
import SwiftData

/// Success/confirmation screen shown after an event is added to the calendar.
/// Features expanding success ring, checkmark animation, confetti burst, and auto-dismiss.
struct EventConfirmationView: View {
    @Environment(EventCreationViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var ringScale: CGFloat = 0.0
    @State private var checkmarkProgress: CGFloat = 0.0
    @State private var showContent = false
    @State private var confettiActive = false
    @State private var autoDismissTask: Task<Void, Never>?
    @State private var interactionTimer: Task<Void, Never>?

    private let autoDismissDelay: TimeInterval = 8.0

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Success ring + checkmark
                ZStack {
                    // Expanding ring
                    Circle()
                        .stroke(Color.accentPrimary.opacity(0.25), lineWidth: 4)
                        .frame(width: 80, height: 80)
                        .scaleEffect(ringScale)

                    Circle()
                        .trim(from: 0, to: ringScale)
                        .stroke(Color.accentPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.accentPrimary)
                        .scaleEffect(checkmarkProgress)
                        .opacity(checkmarkProgress)
                }
                .frame(width: 100, height: 100)
                .padding(.bottom, 24)

                // Headline
                Text("Added to Calendar")
                    .font(.title.bold())
                    .foregroundColor(.primary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .padding(.bottom, 32)

                // Mini event card
                if let event = viewModel.parsedEvent {
                    EventCard(event: event, variant: .compact)
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 15)
                        .padding(.bottom, 40)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // View in Calendar
                    Button {
                        openInCalendar()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                            Text("View in Calendar")
                                .font(.body.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(Color.accentTeal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentTeal, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(showContent ? 1 : 0)
                    .accessibilityLabel("View event in Calendar app")
                    .frame(minWidth: 44, minHeight: 44)

                    // Snap Another
                    Button {
                        dismissAndReset()
                    } label: {
                        Text("Snap Another")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(showContent ? 1 : 0)
                    .accessibilityLabel("Capture another event")
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // Confetti burst
            if confettiActive {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            triggerEntryAnimation()
            startAutoDismissTimer()
        }
        .onDisappear {
            autoDismissTask?.cancel()
            interactionTimer?.cancel()
        }
        .onTapGesture {
            resetAutoDismissTimer()
        }
    }

    // MARK: - Background

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }

    // MARK: - Entry Animation

    private func triggerEntryAnimation() {
        // Ring spring animation with overshoot
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0.3)) {
            ringScale = 1.0
        }

        // Checkmark after ring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                checkmarkProgress = 1.0
            }
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }

        // Content fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }

        // Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                confettiActive = true
            }
            // Auto-hide confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
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
            await MainActor.run {
                dismissAndReset()
            }
        }
    }

    private func resetAutoDismissTimer() {
        autoDismissTask?.cancel()
        startAutoDismissTimer()
    }

    // MARK: - Actions

    private func openInCalendar() {
        // Open the event in the system Calendar app
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

// MARK: - Confetti View

private struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false

        let emitterLayer = CAEmitterLayer()
        // NOTE: Using UIScreen.main.bounds here is a known limitation.
        // CAEmitterLayer doesn't have direct SwiftUI geometry access, so we fall back to UIScreen.main.
        // This should be replaced with GeometryReader in a future iOS 16+ compatible refactor.
        emitterLayer.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -20)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitterLayer.emitterCells = (0..<12).map { _ in createEmitterCell() }

        view.layer.addSublayer(emitterLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func createEmitterCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = createCircleImage(size: 8, color: confettiColor())?.cgImage
        cell.birthRate = 8
        cell.lifetime = 3.0
        cell.velocity = 400
        cell.velocityRange = 150
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.spin = 4
        cell.spinRange = 8
        cell.scale = 0.6
        cell.scaleRange = 0.4
        cell.yAcceleration = 300
        cell.alphaSpeed = -0.2
        return cell
    }

    private func confettiColor() -> UIColor {
        let colors: [UIColor] = [
            UIColor.accentPrimary,
            UIColor.accentTeal,
            UIColor.privacyGreen,
            UIColor(hex: "#FFD60A"),
            UIColor(hex: "#FF375F"),
        ]
        return colors.randomElement() ?? .orange
    }

    private func createCircleImage(size: CGFloat, color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            UIBezierPath(ovalIn: rect).fill()
        }
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