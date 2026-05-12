import SwiftUI

/// Full-screen voice experience with waveform visualization, live transcription,
/// stop button, and auto-stop countdown.
struct VoiceInputView: View {
    @Environment(VoiceViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var waveformOffset: CGFloat = 0
    @State private var hasStarted = false

    /// Called when transcription completes with the final text.
    var onTranscriptionComplete: ((String) -> Void)?

    private let barCount = 60
    private let barWidth: CGFloat = 6

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    OnDeviceBadge()
                        .padding(.leading, 16)
                        .padding(.top, 16)

                    Spacer()
                }

                Spacer()

                // Waveform visualization
                waveformView
                    .frame(height: 180)
                    .padding(.horizontal, 24)

                Spacer()

                // Live transcription
                liveTranscriptionView
                    .padding(.horizontal, 24)

                Spacer()

                // Stop button / auto-stop countdown
                if viewModel.isRecording {
                    stopButtonArea
                        .padding(.bottom, 50)
                } else if hasStarted {
                    // Processing state
                    VStack(spacing: 12) {
                        IndeterminateProgressBar()
                            .padding(.horizontal, 60)
                        Text("Processing...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 50)
                } else {
                    // Idle state - start recording prompt
                    startPrompt
                        .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            startRecording()
        }
        .onDisappear {
            if viewModel.isRecording {
                viewModel.stopRecording()
            }
        }
    }

    // MARK: - Background

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)
    }

    // MARK: - Waveform

    private var waveformView: some View {
        let levels = viewModel.audioLevels
        let isIdle = !viewModel.isRecording && !hasStarted

        return GeometryReader { geometry in
            let spacing: CGFloat = 4
            let totalWidth = CGFloat(barCount) * (barWidth + spacing)
            let startX = (geometry.size.width - totalWidth) / 2

            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentPrimary)
                        .frame(width: barWidth)
                        .frame(
                            maxHeight: isIdle
                                ? idleBarHeight(at: index, totalHeight: geometry.size.height)
                                : activeBarHeight(level: safeLevel(levels, index: index), totalHeight: geometry.size.height)
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

    private func safeLevel(_ levels: [Float], index: Int) -> Float {
        guard index < levels.count else { return 0 }
        return levels[index]
    }

    private func activeBarHeight(level: Float, totalHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight = totalHeight * 0.9
        return minHeight + (maxHeight - minHeight) * CGFloat(level)
    }

    // Idle state: gentle oscillating wave
    @State private var idlePhase: Double = 0

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
            Text(viewModel.liveTranscription.isEmpty ? "Listening..." : viewModel.liveTranscription)
                .font(.title3)
                .foregroundColor(viewModel.liveTranscription.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .animation(.default, value: viewModel.liveTranscription)
        }
        .frame(maxHeight: 120)
        .accessibilityLabel("Transcription: \(viewModel.liveTranscription.isEmpty ? "listening" : viewModel.liveTranscription)")
    }

    // MARK: - Stop Button

    private var stopButtonArea: some View {
        VStack(spacing: 16) {
            ZStack {
                // Auto-stop countdown ring
                if let countdown = viewModel.silenceCountdown {
                    Circle()
                        .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 4)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 3.0)
                        .stroke(Color.accentPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)

                    Text("\(countdown)")
                        .font(.title.weight(.bold))
                        .foregroundColor(Color.accentPrimary)
                }

                // Stop button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.stopRecording()
                    hasStarted = false
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 44, height: 44)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop recording")
                .frame(minWidth: 44, minHeight: 44)
            }

            // Countdown hint
            if viewModel.silenceCountdown != nil {
                Text("Auto-stopping...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Start Prompt

    private var startPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundColor(Color.accentPrimary)

            Text("Describe your event")
                .font(.title3.weight(.semibold))

            Text("Say something like \"Lunch with Sarah next Tuesday at 1pm\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard !hasStarted else { return }
        hasStarted = true

        viewModel.startRecording { transcription in
            // Transcription complete - forward to coordinator
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
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