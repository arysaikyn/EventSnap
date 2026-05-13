import SwiftUI

/// Full-screen voice experience with premium waveform visualization, live transcription,
/// stop button with countdown ring, and smooth spring animations.
///
/// Design: 95% neutral, 5% color — typography-first hierarchy on 8-pt grid.
struct VoiceInputView: View {
    @Environment(VoiceViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var waveformOffset: CGFloat = 0
    @State private var idlePhase: Double = 0

    /// Called when transcription completes with the final text.
    var onTranscriptionComplete: ((String) -> Void)?

    private let barCount = 60
    private let barWidth: CGFloat = 6

    // MARK: - Adaptive Colors

    private var surfaceColor: Color {
        colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase
    }

    private var textPrimary: Color {
        colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary
    }

    private var textTertiary: Color {
        colorScheme == .dark ? Color.textTertiaryDark : Color.textTertiary
    }

    private var surfaceSubtle: Color {
        colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            surfaceColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                waveformView
                    .frame(height: 180)
                    .padding(.horizontal, EventSpacing.xl)

                Spacer()

                liveTranscriptionView
                    .padding(.horizontal, EventSpacing.xl)

                Spacer()

                bottomArea
            }
        }
        .onDisappear {
            if viewModel.isRecording {
                viewModel.cancelRecording()
            }
        }
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

    // MARK: - Waveform Visualization

    private var waveformView: some View {
        let levels = viewModel.audioLevels
        let isIdle = !viewModel.isRecording && !viewModel.isProcessing && viewModel.recordingError == nil

        return GeometryReader { geometry in
            let spacing: CGFloat = 4

            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            isIdle
                                ? Color.brandPrimary.opacity(0.7)
                                : Color.brandPrimary.opacity(barOpacity(at: index, levels: levels, isIdle: false))
                        )
                        .frame(width: barWidth)
                        .frame(
                            maxHeight: isIdle
                                ? idleBarHeight(at: index, totalHeight: geometry.size.height)
                                : activeBarHeight(
                                    level: safeLevel(levels, index: index),
                                    totalHeight: geometry.size.height
                                )
                        )
                        .animation(
                            isIdle
                                ? EventAnimation.gentle
                                : EventAnimation.quick,
                            value: isIdle
                                ? Double(idlePhase)
                                : Double(safeLevel(levels, index: index))
                        )
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onAppear {
            if isIdle {
                animateIdleWaveform()
            }
        }
    }

    /// Varying opacity creates depth — taller bars are more opaque.
    private func barOpacity(at index: Int, levels: [Float], isIdle: Bool) -> CGFloat {
        if isIdle {
            let center = Double(barCount) / 2
            let distance = abs(Double(index) - center)
            let envelope = exp(-distance * distance / (Double(barCount) * 2.5))
            return 0.40 + CGFloat(envelope) * 0.35
        }
        let level = safeLevel(levels, index: index)
        return 0.45 + CGFloat(level) * 0.40
    }

    private func safeLevel(_ levels: [Float], index: Int) -> Float {
        guard index < levels.count else { return 0 }
        return levels[index]
    }

    private func activeBarHeight(level: Float, totalHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight = totalHeight * 0.9
        return minHeight + (maxHeight - minHeight) * CGFloat(level)
    }

    /// Idle state: gentle sine wave oscillation with a gaussian envelope.
    private func idleBarHeight(at index: Int, totalHeight: CGFloat) -> CGFloat {
        let center = Double(barCount) / 2
        let distance = abs(Double(index) - center)
        let envelope = exp(-distance * distance / (Double(barCount) * 2.5))
        let oscillation = sin((Double(index) * 0.3) + idlePhase)
        let value = envelope * (0.3 + 0.3 * oscillation)
        return max(4, totalHeight * CGFloat(value) * 0.8)
    }

    private func animateIdleWaveform() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            idlePhase = .pi * 2
        }
    }

    // MARK: - Live Transcription

    private var liveTranscriptionView: some View {
        ScrollView {
            Text(transcriptionDisplayText)
                .font(EventTypography.headline)
                .foregroundStyle(viewModel.liveTranscription.isEmpty ? textTertiary : textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, EventSpacing.sm)
                .animation(EventAnimation.gentle, value: viewModel.liveTranscription)
        }
        .frame(maxHeight: 120)
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(surfaceSubtle.opacity(0.5))
        )
        .accessibilityLabel("Transcription: \(transcriptionDisplayText)")
    }

    private var transcriptionDisplayText: String {
        if !viewModel.liveTranscription.isEmpty {
            return viewModel.liveTranscription
        }
        if let error = viewModel.recordingError, !viewModel.isRecording {
            return error
        }
        if viewModel.isRecording {
            return "Listening… start speaking"
        }
        return "Tap the microphone and describe your event"
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if viewModel.isRecording {
            stopButtonArea
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if viewModel.isProcessing {
            processingView
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            startPrompt
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Stop Button

    private var stopButtonArea: some View {
        VStack(spacing: EventSpacing.lg) {
            // Recording indicator dot + duration hint
            HStack(spacing: EventSpacing.sm) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)

                Text(viewModel.statusMessage)
                    .font(EventTypography.captionMedium)
                    .foregroundStyle(textSecondary)
            }
            .opacity(viewModel.silenceCountdown == nil ? 1 : 0)
            .animation(EventAnimation.default_, value: viewModel.silenceCountdown)

            ZStack {
                // Auto-stop countdown ring
                if let countdown = viewModel.silenceCountdown {
                    // Background ring
                    Circle()
                        .stroke(Color.brandPrimary.opacity(0.12), lineWidth: 4)
                        .frame(width: 72, height: 72)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 3.0)
                        .stroke(
                            Color.brandPrimary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)

                    // Countdown number
                    Text("\(countdown)")
                        .font(EventTypography.bigNumber)
                        .foregroundStyle(Color.brandPrimary)
                        .contentTransition(.numericText())
                        .animation(EventAnimation.snappy, value: countdown)
                }

                // Stop button — 56pt red circle with white stop icon
                Button {
                    EventHaptics.press()
                    viewModel.stopRecording()
                } label: {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "stop.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .red.opacity(0.35), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop recording")
                .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
            }

            // Auto-stop hint
            if viewModel.silenceCountdown != nil {
                Text("Auto-stopping…")
                    .font(EventTypography.caption)
                    .foregroundStyle(textTertiary)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                // Invisible placeholder to maintain layout
                Color.clear
                    .frame(height: 16)
            }
        }
        .animation(EventAnimation.gentle, value: viewModel.silenceCountdown)
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: EventSpacing.lg) {
            IndeterminateProgressBar()
                .padding(.horizontal, 60)

            HStack(spacing: EventSpacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: textSecondary))

                Text("Processing…")
                    .font(EventTypography.callout)
                    .foregroundStyle(textSecondary)
            }
        }
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: EventSpacing.xl) {
            // Icon
            Image(systemName: "waveform")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(Color.brandPrimary)
                .symbolEffect(.pulse, options: .repeating)

            // Title
            Text("Describe your event")
                .font(EventTypography.sectionTitle)
                .foregroundStyle(textPrimary)

            // Subtitle
            Text("Say something like\n\"Lunch with Sarah next Tuesday at 1pm\"")
                .font(EventTypography.subheadline)
                .foregroundStyle(textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, EventSpacing.huge)

            Button {
                EventHaptics.press()
                startRecording()
            } label: {
                HStack(spacing: EventSpacing.sm) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Tap to Speak")
                        .font(EventTypography.bodyMedium)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, EventSpacing.xxl)

            if let error = viewModel.recordingError {
                Text(error)
                    .font(EventTypography.footnote)
                    .foregroundStyle(Color.semanticError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EventSpacing.xl)
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard !viewModel.isRecording && !viewModel.isProcessing else { return }

        viewModel.startRecording { transcription in
            // Transcription complete — forward to coordinator
            EventHaptics.success()
            onTranscriptionComplete?(transcription)
        }
    }
}

#if DEBUG
struct VoiceInputView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInputView()
            .environment(VoiceViewModel(speechService: SpeechService()))
    }
}
#endif
