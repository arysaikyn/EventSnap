import SwiftUI

/// Premium voice input experience centered around a breathing orb,
/// concentric rings reacting to audio, and a refined transcription flow.
///
/// Design philosophy: meditative, spacious, warm — zero-cloud privacy
/// is the hero. The orb breathes when idle, expands when recording,
/// and rings pulse outward with the user's voice.
struct VoiceInputView: View {
    @Environment(VoiceViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var idlePhase: Double = 0
    @State private var showOrb = true

    var onTranscriptionComplete: ((String) -> Void)?

    private let barCount = 60
    private let barWidth: CGFloat = 5

    // MARK: - Adaptive Colors

    private var textPrimary: Color {
        colorScheme == .dark ? .textPrimaryDark : .textPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? .textSecondaryDark : .textSecondary
    }

    private var textTertiary: Color {
        colorScheme == .dark ? .textTertiaryDark : .textTertiary
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient — subtle radial warmth from top
            EventGradient.voiceBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if viewModel.isRecording || viewModel.isProcessing {
                    // Active state: orb + rings + transcription
                    activeVoiceArea
                } else if viewModel.recordingError != nil {
                    // Error state
                    errorArea
                } else {
                    // Idle state: invitation to speak
                    idleArea
                }

                bottomActionArea
            }
        }
        .onDisappear {
            if viewModel.isRecording {
                viewModel.cancelRecording()
            }
        }
        .animation(EventAnimation.gentle, value: viewModel.isRecording)
        .animation(EventAnimation.gentle, value: viewModel.isProcessing)
        .animation(EventAnimation.gentle, value: viewModel.recordingError)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            OnDeviceBadge()
                .padding(.leading, EventSpacing.pageMargin)
                .padding(.top, EventSpacing.lg)

            Spacer()
        }
    }

    // MARK: - Active Voice Area (recording / processing)

    private var activeVoiceArea: some View {
        VStack(spacing: 0) {
            Spacer()

            // Orb + concentric rings — the visual hero
            ZStack {
                ConcentricRings(
                    audioLevel: maxAudioLevel,
                    isRecording: viewModel.isRecording
                )

                BreathingOrb(
                    isRecording: viewModel.isRecording,
                    audioLevel: maxAudioLevel
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: EventSpacing.huge * 3)

            Spacer()

            // Live transcription
            liveTranscriptionView
                .padding(.horizontal, EventSpacing.xl)

            Spacer()
        }
    }

    // MARK: - Error Area

    private var errorArea: some View {
        VStack(spacing: EventSpacing.xl) {
            Spacer()

            Image(systemName: "mic.slash.circle.fill")
                .font(EventTypography.errorIcon)
                .foregroundStyle(Color.semanticError)
                .symbolEffect(.bounce, value: true)

            if let error = viewModel.recordingError {
                Text(error)
                    .font(EventTypography.headline)
                    .foregroundStyle(textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EventSpacing.huge)

                Button("Try Again") {
                    EventHaptics.tap()
                    startRecording()
                }
                .buttonStyle(EnhancedPrimaryButtonStyle(icon: "arrow.clockwise"))
                .padding(.horizontal, EventSpacing.xxl)
            }

            Spacer()
        }
    }

    // MARK: - Idle Area

    private var idleArea: some View {
        VStack(spacing: EventSpacing.xl) {
            Spacer()

            // Large breathing orb
            BreathingOrb(
                isRecording: false,
                audioLevel: idleOrbLevel
            )
            .frame(height: EventSpacing.huge * 3)

            // Invitation text
            Text("Describe your event")
                .font(EventTypography.pageTitle)
                .foregroundStyle(textPrimary)

            Text("Say something like\n\"Lunch with Sarah next Tuesday at 1pm\"")
                .font(EventTypography.subheadline)
                .foregroundStyle(textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Waveform preview — 60 gradient bars
            idleWaveformPreview
                .frame(height: EventSpacing.xl)
                .padding(.horizontal, EventSpacing.xxl)

            Spacer()
        }
    }

    // MARK: - Bottom Action Area

    @ViewBuilder
    private var bottomActionArea: some View {
        if viewModel.isRecording {
            recordingControls
                .padding(.bottom, EventSpacing.bottomSafe)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if viewModel.isProcessing {
            processingIndicator
                .padding(.bottom, EventSpacing.bottomSafe)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            startRecordingButton
                .padding(.bottom, EventSpacing.bottomSafe)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Recording Controls

    private var recordingControls: some View {
        VStack(spacing: EventSpacing.lg) {
            // Status pill
            VoiceStatusPill(
                status: recordingPillStatus
            )

            // Stop button with countdown ring
            ZStack {
                // Countdown ring (visible during silence countdown)
                if let countdown = viewModel.silenceCountdown {
                    Circle()
                        .stroke(Color.brandPrimary.opacity(0.12), lineWidth: 3)
                        .frame(width: EventSpacing.xl * 1.5, height: EventSpacing.xl * 1.5)

                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 3.0)
                        .stroke(
                            Color.brandPrimary,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: EventSpacing.xl * 1.5, height: EventSpacing.xl * 1.5)
                        .rotationEffect(.degrees(-90))
                        .animation(EventAnimation.countdown, value: countdown)
                }

                // Stop button
                Button {
                    EventHaptics.press()
                    viewModel.stopRecording()
                } label: {
                    Circle()
                        .fill(.red)
                        .frame(width: EventSpacing.xl, height: EventSpacing.xl)
                        .overlay(
                            Image(systemName: "stop.fill")
                                .font(EventTypography.stopIcon)
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop recording")
            }
        }
        .animation(EventAnimation.gentle, value: viewModel.silenceCountdown)
    }

    // MARK: - Processing Indicator

    private var processingIndicator: some View {
        VStack(spacing: EventSpacing.lg) {
            VoiceStatusPill(status: .processing)
                .transition(.opacity)
        }
    }

    // MARK: - Start Recording Button

    private var startRecordingButton: some View {
        VStack(spacing: EventSpacing.lg) {
            Button("Tap to Speak") {
                startRecording()
            }
            .buttonStyle(EnhancedPrimaryButtonStyle(icon: "mic.fill"))
            .padding(.horizontal, EventSpacing.xxl)
        }
    }

    // MARK: - Live Transcription

    private var liveTranscriptionView: some View {
        ScrollView {
            Text(transcriptionDisplayText)
                .font(EventTypography.headline)
                .foregroundStyle(viewModel.liveTranscription.isEmpty ? textTertiary : textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: EventSpacing.smallButtonHeight)
                .padding(.vertical, EventSpacing.sm)
        }
        .frame(maxHeight: EventSpacing.huge * 2)
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(Color.surfaceSubtle.opacity(0.4))
        )
        .padding(.horizontal, EventSpacing.xl)
        .accessibilityLabel("Transcription: \(transcriptionDisplayText)")
        .animation(EventAnimation.gentle, value: viewModel.liveTranscription)
    }

    // MARK: - Idle Waveform Preview

    private var idleWaveformPreview: some View {
        let total = barCount

        return GeometryReader { geometry in
            let spacing: CGFloat = 3
            let barW = barWidth

            HStack(spacing: spacing) {
                ForEach(0..<total, id: \.self) { index in
                    WaveformBar(
                        index: index,
                        height: idleBarHeight(
                            at: index,
                            total: geometry.size.height,
                            totalBars: total
                        ),
                        isIdle: true,
                        phase: idlePhase,
                        barWidth: barW
                    )
                    .animation(
                        EventAnimation.idleWaveform,
                        value: idlePhase
                    )
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onAppear { animateIdleWaveform() }
    }

    // MARK: - Computed Properties

    private var maxAudioLevel: CGFloat {
        guard !viewModel.audioLevels.isEmpty else { return 0 }
        let clamped = viewModel.audioLevels.map { Swift.max($0, 0.05) }
        return CGFloat(clamped.max() ?? 0.05)
    }

    private var idleOrbLevel: CGFloat {
        cos(idlePhase) * 0.5 + 0.5
    }

    private var recordingPillStatus: VoiceStatusPill.VoiceStatus {
        if let countdown = viewModel.silenceCountdown {
            return .countdown(remaining: countdown)
        }
        return .recording(seconds: 0)
    }

    private var transcriptionDisplayText: String {
        if !viewModel.liveTranscription.isEmpty {
            return viewModel.liveTranscription
        }
        if viewModel.isRecording {
            return "Listening… start speaking"
        }
        if viewModel.isProcessing {
            return "Processing your transcription…"
        }
        return "Tap the microphone and describe your event"
    }

    // MARK: - Idle Waveform Animation

    private func idleBarHeight(at index: Int, total: CGFloat, totalBars: Int) -> CGFloat {
        let center = Double(totalBars) / 2
        let distance = abs(Double(index) - center)
        let envelope = exp(-distance * distance / (Double(totalBars) * 2.0))
        let oscillation = sin((Double(index) * 0.25) + idlePhase)
        let value = envelope * (0.3 + 0.3 * oscillation)
        return max(4, total * CGFloat(value) * 0.7)
    }

    private func animateIdleWaveform() {
        withAnimation(EventAnimation.idleWaveform) {
            idlePhase = .pi * 2
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard !viewModel.isRecording && !viewModel.isProcessing else { return }

        EventHaptics.soft()
        viewModel.startRecording { transcription in
            EventHaptics.success()
            onTranscriptionComplete?(transcription)
        }
    }
}

#if DEBUG
#Preview {
    VoiceInputView()
        .environment(VoiceViewModel(speechService: SpeechService()))
}
#endif
