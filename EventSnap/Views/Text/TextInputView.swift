import SwiftUI

/// Minimal text input screen with auto-expanding text area, paste button,
/// and a "Parse Event" CTA button.
struct TextInputView: View {
    @Environment(TextInputViewModel.self) private var viewModel
    @FocusState private var isTextAreaFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var isParsing = false
    @State private var showError = false
    @State private var parsedEvent: ParsedEvent?

    var onEventParsed: ((ParsedEvent) -> Void)?
    /// When set, raw text is forwarded to the coordinator instead of being parsed locally.
    var onTextSubmitted: ((String) -> Void)?

    private let minHeight: CGFloat = 200
    private let maxHeight: CGFloat = 400

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Text area
                    textEditorSection
                        .padding(.top, 24)

                    // Paste button
                    if viewModel.hasClipboardContent && viewModel.textInput.isEmpty {
                        pasteButton
                    }

                    // Validation error
                    if showError, let error = viewModel.validationError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(Color.accentPrimary)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Color.accentPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Parssing indicator
                    if isParsing {
                        VStack(spacing: 12) {
                            ProgressBar(progress: 0.0, isPulsing: true)
                                .padding(.horizontal, 40)
                            Text("Parsing event details...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Parse Event button (at bottom, always visible)
            VStack(spacing: 0) {
                Divider()
                    .overlay(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))

                parseButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
                    )
            }
        }
        .onAppear {
            viewModel.refreshClipboardStatus()
        }
        .onChange(of: viewModel.textInput) { _, newValue in
            if !newValue.isEmpty {
                showError = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isTextAreaFocused)
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.textInput.isEmpty && !isTextAreaFocused {
                    Text("Type or paste event details...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }

                // Text editor
                TextEditor(text: Binding(
                    get: { viewModel.textInput },
                    set: { viewModel.textInput = $0 }
                ))
                .font(.body)
                .focused($isTextAreaFocused)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.clear)
                .accessibilityLabel("Event details text input")
                .accessibilityHint("Type or paste event information to parse")
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isTextAreaFocused ? Color.accentPrimary : Color.clear,
                            lineWidth: 2
                        )
                )
            .animation(.easeInOut(duration: 0.25), value: isTextAreaFocused)
        }
    }

    // MARK: - Paste Button

    private var pasteButton: some View {
        Button {
            viewModel.pasteFromClipboard()
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.accentTeal)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(
                    Capsule()
                        .stroke(Color.accentTeal, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
        .accessibilityLabel("Paste from clipboard")
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - Parse Button

    private var parseButton: some View {
        Button {
            parseAndSubmit()
        } label: {
            HStack(spacing: 8) {
                if isParsing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkle.magnifyingglass")
                }
                Text("Parse Event")
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(parsedEvent != nil ? Color.privacyGreen : Color.accentPrimary)
                    .opacity(viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isParsing)
        .accessibilityLabel("Parse event")
        .accessibilityHint("Extracts event details from entered text")
        .frame(minWidth: 44, minHeight: 44)
        .keyboardShortcut(.return, modifiers: [])
    }

    // MARK: - Actions

    private func parseAndSubmit() {
        guard !viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // If we have a coordinator callback, forward raw text there
        if let onTextSubmitted {
            isParsing = true
            showError = false
            let trimmed = viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines)
            onTextSubmitted(trimmed)
            isParsing = false
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
            return
        }

        isParsing = true
        showError = false

        Task {
            do {
                let event = try await viewModel.parseEvent()
                parsedEvent = event
                isParsing = false

                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.success)

                // Pass to coordinator (standalone mode)
                onEventParsed?(event)
            } catch {
                isParsing = false
                showError = true

                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.error)
            }
        }
    }
}

#if DEBUG
struct TextInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TextInputView()
                .environment(TextInputViewModel())
                .navigationTitle("Text")
        }
    }
}
#endif