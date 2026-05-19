import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .capture

    @Environment(CalendarService.self) private var calendarService
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(SpeechService.self) private var speechService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var ocrService = OCRService()

    @State private var eventCreationVM: EventCreationViewModel?
    @State private var cameraVM: CameraViewModel?
    @State private var voiceVM: VoiceViewModel?
    @State private var textInputVM: TextInputViewModel?
    @State private var historyViewModel: HistoryViewModel?
    @State private var settingsViewModel: SettingsViewModel?

    @State private var showEventPreview = false
    @State private var showEventConfirmation = false

    @State private var inputMode: InputMode = .camera

    enum Tab: String, CaseIterable, Identifiable {
        case capture, history, settings
        var id: String { rawValue }
        var title: String {
            switch self {
            case .capture: return "Snap"
            case .history: return "History"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                ZStack(alignment: .bottom) {
                    // MARK: - Tab Views
                    TabView(selection: $selectedTab) {
                        captureTab
                            .tag(Tab.capture)
                        historyTab
                            .tag(Tab.history)
                        settingsTab
                            .tag(Tab.settings)
                    }
                    .tint(Color.brandPrimary)
                    .onChange(of: eventCreationVM?.state) { _, newState in
                        guard let newState else { return }
                        switch newState {
                        case .preview:
                            showEventPreview = true
                        case .completed:
                            showEventPreview = false
                            showEventConfirmation = true
                        case .idle:
                            showEventPreview = false
                            showEventConfirmation = false
                        default: break
                        }
                    }
                    .sheet(isPresented: $showEventPreview) {
                        if let vm = eventCreationVM {
                            EventPreviewView()
                                .environment(vm)
                                .environment(permissionManager)
                        }
                    }
                    .fullScreenCover(isPresented: $showEventConfirmation) {
                        if let vm = eventCreationVM {
                            EventConfirmationView()
                                .environment(vm)
                        }
                    }

                    // MARK: - Tab Bar Overlay
                    CustomTabBar(selectedTab: $selectedTab)
                }
                .ignoresSafeArea(.keyboard)
            }
        }
        .onAppear {
            setupViewModels()
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var captureTab: some View {
        GeometryReader { proxy in
            let topSafe = proxy.safeAreaInsets.top
            let botSafe = proxy.safeAreaInsets.bottom
            VStack(spacing: 0) {
                Text("EventSnap")
                    .font(EventTypography.sectionTitle)
                    .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.top, topSafe)

                InputSelector(selectedMode: $inputMode)
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.top, 8)

                switch inputMode {
                case .camera:
                    CameraCaptureView(onImageCaptured: {
                        handleInput(.image($0))
                    }).environment(cameraVM)
                     .environment(permissionManager)
                case .voice:
                    VoiceInputView(onTranscriptionComplete: {
                        handleInput(.transcription($0))
                    }).environment(voiceVM)
                     .environment(permissionManager)
                case .text:
                    TextInputView(onTextSubmitted: {
                        handleInput(.text($0))
                    }).environment(textInputVM)
                }
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
            .padding(.bottom, botSafe + 70)
        }
    }

    @ViewBuilder
    private var historyTab: some View {
        if let historyViewModel {
            HistoryView(onNavigateToCapture: { selectedTab = .capture })
                .environment(historyViewModel)
        }
    }

    @ViewBuilder
    private var settingsTab: some View {
        if let settingsViewModel {
            SettingsView()
                .environment(settingsViewModel)
        }
    }

    // MARK: - Logic

    private func setupViewModels() {
        guard eventCreationVM == nil else { return }
        eventCreationVM = EventCreationViewModel(
            calendarService: calendarService, ocrService: ocrService,
            speechService: speechService, modelContext: modelContext)
        cameraVM = CameraViewModel(ocrService: ocrService)
        voiceVM = VoiceViewModel(speechService: speechService)
        textInputVM = TextInputViewModel()
        historyViewModel = HistoryViewModel(modelContext: modelContext, calendarService: calendarService)
        settingsViewModel = SettingsViewModel(calendarService: calendarService, permissionManager: permissionManager)
    }

    private func handleInput(_ input: InputData) {
        guard let vm = eventCreationVM else { return }
        Task {
            switch input {
            case .image: vm.startCapture(.camera)
            case .text: vm.startCapture(.text)
            case .transcription: vm.startCapture(.voice)
            }
            await vm.processInput(input)
        }
    }

    // MARK: - Custom Tab Bar
    /// Frosted glass bar with rounded top corners, positioned above
    /// the home indicator with proper safe area padding.
    private struct CustomTabBar: View {
        @Binding var selectedTab: ContentView.Tab
        @Environment(\.colorScheme) private var style

        var body: some View {
            HStack(spacing: 0) {
                TabButton(tab: .capture, selectedTab: $selectedTab)
                TabButton(tab: .history, selectedTab: $selectedTab)
                TabButton(tab: .settings, selectedTab: $selectedTab)
            }
            .padding(.vertical, EventSpacing.sm)
            .padding(.horizontal, EventSpacing.pageMargin)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: EventRadius.large,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: EventRadius.large
                )
                .fill(backgroundMaterial())
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: EventRadius.large,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: EventRadius.large
                )
                .strokeBorder(
                    style == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08),
                    lineWidth: 0.5
                ),
                alignment: .top
            )
            // Only shadow upward — tab bar floats above content
            .shadow(
                color: Color.black.opacity(style == .dark ? 0.4 : 0.12),
                radius: 6, x: 0, y: -3
            )
            // Proper safe area: sits above home indicator
            .safeAreaPadding(.bottom)
        }

        private func backgroundMaterial() -> some ShapeStyle {
            style == .dark
                ? AnyShapeStyle(Color(UIColor.systemBackground).opacity(0.92))
                : AnyShapeStyle(Color(UIColor.systemBackground).opacity(0.82))
        }
    }

    private struct TabButton: View {
        var tab: ContentView.Tab
        @Binding var selectedTab: ContentView.Tab
        @Environment(\.colorScheme) private var style

        private var isSelected: Bool {
            selectedTab == tab
        }

        private var iconName: String {
            switch tab {
            case .capture: return "camera.aperture"
            case .history: return "clock.fill"
            case .settings: return "gearshape"
            }
        }

        var body: some View {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
                EventHaptics.selection()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                    Text(tab.title)
                        .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: EventSpacing.md + EventSpacing.xs)
                .foregroundStyle(isSelected ? Color.brandPrimary : (style == .dark ? Color.textTertiaryDark : .secondary))
                .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .buttonStyle(.plain)
        }
    }
}
