import SwiftUI
import UIKit
import SwiftData

/// Success/confirmation screen shown after an event is added to the calendar.
/// Features expanding success ring, checkmark animation, confetti burst, and auto-dismiss.
/// Premium design with spring overshoot animations.
struct EventConfirmationView: View {
    @Environment(EventCreationViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var ringScale: CGFloat = 0.0
    @State private var ringOuterScale: CGFloat = 0.0
    @State private var checkmarkProgress: CGFloat = 0.0
    @State private var showContent = false
    @State private var confettiActive = false
    @State private var autoDismissTask: Task<Void, Never>?
    @State private var interactionTimer: Task<Void, Never>?

    private let autoDismissDelay: TimeInterval = 8.0

    private var surface: Color {
        colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase
    }

    var body: some View {
        ZStack {
            surface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Success ring + checkmark
                ZStack {
                    // Outer expanding ring (overshoot spring)
                    Circle()
                        .stroke(Color.brandPrimary.opacity(0.12), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringOuterScale)

                    // Inner progress ring
                    Circle()
                        .trim(from: 0, to: ringScale)
                        .stroke(
                            Color.brandPrimary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.brandPrimary)
                        .scaleEffect(checkmarkProgress)
                        .opacity(checkmarkProgress)
                }
                .frame(width: 120, height: 120)
                .padding(.bottom, EventSpacing.xxl)

                // Headline
                Text("Added to Calendar")
                    .font(EventTypography.pageTitle)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 12)
                    .padding(.bottom, EventSpacing.huge)

                // Mini event card
                if let event = viewModel.parsedEvent {
                    EventCard(event: event, variant: .compact)
                        .padding(.horizontal, EventSpacing.xxl)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 16)
                        .padding(.bottom, EventSpacing.massive)
                }

                Spacer()

                // Action buttons
                VStack(spacing: EventSpacing.md) {
                    // View in Calendar
                    Button {
                        EventHaptics.tap()
                        openInCalendar()
                    } label: {
                        HStack(spacing: EventSpacing.sm) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                            Text("View in Calendar")
                                .font(EventTypography.bodyMedium)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .opacity(showContent ? 1 : 0)
                    .accessibilityLabel("View event in Calendar app")
                    .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)

                    // Snap Another
                    Button {
                        EventHaptics.tap()
                        dismissAndReset()
                    } label: {
                        Text("Snap Another")
                            .font(EventTypography.bodyMedium)
                    }
                    .buttonStyle(GhostButtonStyle())
                    .opacity(showContent ? 1 : 0)
                    .accessibilityLabel("Capture another event")
                    .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
                }
                .padding(.horizontal, EventSpacing.xxl)
                .padding(.bottom, EventSpacing.massive)
            }

            // Confetti burst
            if confettiActive {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            EventHaptics.success()
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

    // MARK: - Entry Animation

    private func triggerEntryAnimation() {
        // Ring outer expands with spring overshoot
        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.45, blendDuration: 0.3)
        ) {
            ringOuterScale = 1.2
        }

        // Inner ring fills
        withAnimation(
            .spring(response: 0.55, dampingFraction: 0.50, blendDuration: 0.3)
        ) {
            ringScale = 1.0
        }

        // Checkmark appears after ring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(
                .spring(response: 0.35, dampingFraction: 0.55)
            ) {
                checkmarkProgress = 1.0
            }
        }

        // Content fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(
                Animation.spring(response: 0.4, dampingFraction: 0.7)
            ) {
                showContent = true
            }
        }

        //Confetti burst - brief and subtle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            confettiActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
        emitterLayer.emitterCells = (0..<6).map { _ in createEmitterCell() }

        view.layer.addSublayer(emitterLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func createEmitterCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = createCircleImage(size: 8, color: confettiColor())?.cgImage
cell.birthRate = 3
        cell.lifetime = 2.0
        cell.velocity = 180
        cell.velocityRange = 60
        cell.emissionRange = .pi / 8
        cell.spin = 2
        cell.spinRange = 3
        cell.scale = 0.4
        cell.scaleRange = 0.2
        cell.yAcceleration = 160
        cell.alphaSpeed = -0.16
        return cell
    }

    private func confettiColor() -> UIColor {
        let colors: [UIColor] = [
            UIColor.brandPrimary,
            UIColor.brandSecondary,
            UIColor(hex: "#2DB55D"),  // semanticSuccess
            UIColor.brandAccent,
            UIColor(hex: "#FF375F"),  // vibrant pink accent
        ]
        return colors.randomElement() ?? UIColor.brandPrimary
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