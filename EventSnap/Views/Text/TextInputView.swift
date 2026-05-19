import SwiftUI

/// Premium text input experience — borderless editor with floating parse button,
/// subtle paste pill, and refined visual hierarchy.
///
/// Design philosophy: editorial, spacious, typography-first.
/// The text editor feels like writing on a blank page — no borders,
/// no chrome. Actions float above the content.
struct TextInputView: View {
    @Environment(TextInputViewModel.self) private var viewModel
    @FocusState private var isTextAreaFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var isParsing = false
    @State private var showError = false
    @State private var parsedEvent: ParsedEvent?

    var onEventParsed: ((ParsedEvent) -> Void)?
    var onTextSubmitted: ((String) -> Void)?

    private let minHeight: CGFloat = 200
    private let maxHeight: CGFloat = 400

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

    private var surfaceSubtle: Color {
        colorScheme == .dark ? .surfaceSubtleDark : .surfaceSubtle
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Subtle grain-like background for depth
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                // Main content area
                ScrollView {
                    VStack(spacing: EventSpacing.lg) {
                        // Character count hint
                        if !viewModel.textInput.isEmpty {
                            characterCount
                                .transition(.opacity)
                        }

                        // Borderless text editor
                        textEditorArea
                            .padding(.horizontal, EventSpacing.pageMargin)

                        // Validation error
                        if showError, let error = viewModel.validationError {
                            errorToast(message: error)
                                .padding(.horizontal, EventSpacing.pageMargin)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Processing indicator
                        if isParsing {
                            processingIndicator
                                .padding(.horizontal, EventSpacing.huge)
                                .transition(.opacity)
                        }
                    }
                    .padding(.top, EventSpacing.lg)
                    .padding(.bottom, EventSpacing.textInputFloatingPadding) // Space for floating button
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextAreaFocused = false
                }
            }

            // Floating parse button — anchored to bottom
            floatingParseButton
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, EventSpacing.lg)
        }
        .background {
            // Tap to dismiss keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isTextAreaFocused = false }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                // Paste shortcut when keyboard is visible
                if viewModel.hasClipboardContent && viewModel.textInput.isEmpty {
                    Button {
                        viewModel.pasteFromClipboard()
                        EventHaptics.tap()
                    } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                            .font(EventTypography.caption)
                    }

                    Divider()
                }
                Button("Done") { isTextAreaFocused = false }
                    .font(EventTypography.bodyMedium)
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
        .animation(EventAnimation.default_, value: isTextAreaFocused)
        .animation(EventAnimation.gentle, value: showError)
        .animation(EventAnimation.gentle, value: isParsing)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            OnDeviceBadge()
                .padding(.leading, EventSpacing.pageMargin)
                .padding(.top, EventSpacing.lg)

            Spacer()

            // Paste button — top right, subtle
            if viewModel.hasClipboardContent && viewModel.textInput.isEmpty {
                Button {
                    viewModel.pasteFromClipboard()
                    EventHaptics.tap()
                } label: {
                    HStack(spacing: EventSpacing.xs) {
                        Image(systemName: "doc.on.clipboard")
                            .font(EventTypography.footnoteSemibold)
                        Text("Paste")
                            .font(EventTypography.caption)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, EventSpacing.md)
                    .padding(.vertical, EventSpacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.brandPrimary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.trailing, EventSpacing.pageMargin)
                .padding(.top, EventSpacing.lg)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Text Editor Area

    private var textEditorArea: some View {
        EventGlass.card {
            ZStack(alignment: .topLeading) {
                // Placeholder text
                if viewModel.textInput.isEmpty {
                    VStack(alignment: .leading, spacing: EventSpacing.sm) {
                        Image(systemName: "text.bubble")
                            .font(EventTypography.placeholderIcon)
                            .foregroundStyle(textTertiary)

                        Text("Type or paste event details")
                            .font(EventTypography.pageTitle)
                            .foregroundStyle(textTertiary)

                        Text("e.g. \"Team lunch next Tuesday at 1pm at the Italian place on Main St\"")
                            .font(EventTypography.subheadline)
                            .foregroundStyle(textTertiary.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .padding(EventSpacing.cardPadding)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }

                // Actual editor
                TextEditor(text: Binding(
                    get: { viewModel.textInput },
                    set: { viewModel.textInput = $0 }
                ))
                .font(EventTypography.body)
                .focused($isTextAreaFocused)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .scrollContentBackground(.hidden)
                .foregroundStyle(textPrimary)
                .padding(EventSpacing.cardPadding)
                .eventInput(isFocused: isTextAreaFocused)
                .accessibilityLabel("Event details text input")
                .accessibilityHint("Type or paste event information to parse")
            }
        }
        .padding(.horizontal, EventSpacing.pageMargin)
    }

    // MARK: - Character Count

    private var characterCount: some View {
        HStack(spacing: EventSpacing.sm) {
            // Mini progress bar showing characters / 5000 limit
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.textTertiary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(charCountColor)
                            .frame(width: geo.size.width * charProgress)
                    )
            }
            .frame(height: 3)

            Text("\(viewModel.textInput.count)/5000")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(charCountColor)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(.horizontal, EventSpacing.pageMargin)
    }

    private var charProgress: Double {
        min(Double(viewModel.textInput.count) / 5000.0, 1.0)
    }

    private var charCountColor: Color {
        if charProgress > 0.9 { return .semanticError }
        if charProgress > 0.7 { return .brandAccent }
        return .textTertiary
    }

    // MARK: - Error Toast

    private func errorToast(message: String) -> some View {
        HStack(spacing: EventSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(EventTypography.callout)
                .foregroundStyle(Color.semanticError)

            Text(message)
                .font(EventTypography.captionMedium)
                .foregroundStyle(Color.semanticError)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, EventSpacing.lg)
        .padding(.vertical, EventSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(Color.semanticError.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: EventRadius.medium))
        )
    }

    // MARK: - Processing Indicator

    private var processingIndicator: some View {
        VStack(spacing: EventSpacing.md) {
            ProgressView()
                .scaleEffect(0.9)
                .tint(Color.brandPrimary)

            Text("Extracting event details…")
                .font(EventTypography.callout)
                .foregroundStyle(textSecondary)
        }
        .padding(.vertical, EventSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(surfaceSubtle.opacity(0.5))
        )
    }

    // MARK: - Floating Parse Button

    private var floatingParseButton: some View {
        let isEmpty = viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isDisabled = isEmpty || isParsing

        return VStack(spacing: EventSpacing.sm) {
            // Smart hint
            if isEmpty {
                Text("Describe your event to parse date, time, and location")
                    .font(EventTypography.caption)
                    .foregroundStyle(textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EventSpacing.huge)
            }

            // Parse button with gradient + glow
            Button {
                parseAndSubmit()
            } label: {
                HStack(spacing: EventSpacing.sm) {
                    if isParsing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                            .transition(.opacity)
                    } else {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(EventTypography.calloutMedium)
                            .transition(.opacity)
                    }

                    Text(isParsing ? "Parsing…" : "Parse Event")
                        .font(EventTypography.subheadSemibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: EventSpacing.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: EventRadius.medium)
                        .fill(isDisabled ? Color.textTertiary : Color.brandPrimary)
                        .shadow(
                            color: isDisabled ? .clear : Color.brandPrimary.opacity(0.25),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .scaleEffect(isDisabled ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .padding(.horizontal, EventSpacing.pageMargin)
            .keyboardShortcut(.return, modifiers: [])
            .accessibilityLabel("Parse event")
            .accessibilityHint("Extracts event details from entered text")
        }
        .animation(EventAnimation.gentle, value: isEmpty)
        .animation(EventAnimation.quick, value: isParsing)
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
#Preview {
    TextInputView()
        .environment(TextInputViewModel())
}
#endif
