import SwiftUI

/// Premium text input screen with auto-expanding text area, paste button,
/// and a "Parse Event" CTA button. Uses the EventSnap design system.
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

    private var surface: AdaptiveSurface {
        AdaptiveSurface(scheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: EventSpacing.xl) {
                    // Text area
                    textEditorSection
                        .padding(.top, EventSpacing.xxl)

                    // Paste from clipboard button
                    if viewModel.hasClipboardContent && viewModel.textInput.isEmpty {
                        pasteButton
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Validation error banner
                    if showError, let error = viewModel.validationError {
                        errorBanner(message: error)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Processing indicator
                    if isParsing {
                        processingIndicator
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, EventSpacing.pageMargin)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextAreaFocused = false
            }

            // Bottom button bar
            VStack(spacing: 0) {
                parseButton
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.vertical, EventSpacing.lg)
            }
        }
        .background(surface.background)
        .onAppear {
            viewModel.refreshClipboardStatus()
        }
        .onChange(of: viewModel.textInput) { _, newValue in
            if !newValue.isEmpty {
                showError = false
            }
        }
        .animation(EventAnimation.default_, value: isTextAreaFocused)
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: EventSpacing.xs) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if viewModel.textInput.isEmpty {
                    Text("Type or paste event details...")
                        .font(EventTypography.body)
                        .foregroundStyle(surface.textTertiary)
                        .padding(.horizontal, EventSpacing.md + 4)
                        .padding(.vertical, EventSpacing.md + 2)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                // Text editor
                TextEditor(text: Binding(
                    get: { viewModel.textInput },
                    set: { viewModel.textInput = $0 }
                ))
                .font(EventTypography.body)
                .focused($isTextAreaFocused)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, EventSpacing.md)
                .padding(.vertical, EventSpacing.sm)
                .foregroundStyle(surface.textPrimary)
                .accessibilityLabel("Event details text input")
                .accessibilityHint("Type or paste event information to parse")
            }
            .eventInput(isFocused: isTextAreaFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isTextAreaFocused = false }
                        .font(.body.weight(.medium))
                }
            }
        }
    }

    // MARK: - Paste Button

    private var pasteButton: some View {
        Button {
            viewModel.pasteFromClipboard()
            EventHaptics.tap()
        } label: {
            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                .font(EventTypography.subheadMedium)
                .foregroundStyle(Color.brandSecondary)
                .padding(.horizontal, EventSpacing.xl)
                .frame(height: EventSpacing.smallButtonHeight)
                .background(
                    Capsule()
                        .stroke(Color.brandSecondary, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Paste from clipboard")
        .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: EventSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(EventTypography.footnote)
                .foregroundStyle(Color.semanticError)

            Text(message)
                .font(EventTypography.footnote)
                .foregroundStyle(Color.semanticError)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, EventSpacing.lg)
        .padding(.vertical, EventSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.small)
                .fill(Color.semanticError.opacity(0.1))
        )
    }

    // MARK: - Processing Indicator

    private var processingIndicator: some View {
        VStack(spacing: EventSpacing.md) {
            IndeterminateProgressBar()
                .padding(.horizontal, EventSpacing.huge)

            Text("Parsing event details...")
                .font(EventTypography.subheadline)
                .foregroundStyle(surface.textSecondary)
        }
    }

    // MARK: - Parse Button

    private var parseButton: some View {
        let isEmpty = viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isDisabled = isEmpty || isParsing

        return Button {
            parseAndSubmit()
        } label: {
            HStack(spacing: EventSpacing.sm) {
                if isParsing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                }

                Text("Parse Event")
                    .font(EventTypography.bodyMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: EventSpacing.buttonHeight)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: EventRadius.medium)
                    .fill(isDisabled ? Color.textTertiary : Color.brandPrimary)
            )
            .scaleEffect(isDisabled ? 1.0 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(EventAnimation.quick, value: isDisabled)
        .accessibilityLabel("Parse event")
        .accessibilityHint("Extracts event details from entered text")
        .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
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
            EventHaptics.success()
            return
        }

        isParsing = true
        showError = false

        Task {
            do {
                let event = try await viewModel.parseEvent()
                parsedEvent = event
                isParsing = false

                EventHaptics.success()

                // Pass to coordinator (standalone mode)
                onEventParsed?(event)
            } catch {
                isParsing = false
                showError = true

                EventHaptics.error()
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