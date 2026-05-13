import SwiftUI
import SwiftData

// MARK: - Content View (Premium Coordinator)

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .capture
    @State private var inputMode: InputMode = .camera

    // MARK: - Services (injected via environment)
    @Environment(CalendarService.self) private var calendarService
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(SpeechService.self) private var speechService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var ocrService = OCRService()

    // MARK: - ViewModels (created here as coordinator)
    @State private var eventCreationVM: EventCreationViewModel?
    @State private var cameraVM: CameraViewModel?
    @State private var voiceVM: VoiceViewModel?
    @State private var textInputVM: TextInputViewModel?
    @State private var historyViewModel: HistoryViewModel?
    @State private var settingsViewModel: SettingsViewModel?

    // MARK: - Navigation State
    @State private var showEventPreview = false
    @State private var showEventConfirmation = false

    // MARK: - Tab Enum
    enum Tab: String, CaseIterable, Identifiable {
        case capture
        case history
        case settings

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .capture: return "camera.aperture"
            case .history: return "clock.arrow.circlepath"
            case .settings: return "gearshape"
            }
        }

        var selectedIconName: String {
            switch self {
            case .capture: return "camera.aperture"
            case .history: return "clock.arrow.circlepath.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var title: String {
            switch self {
            case .capture: return "Snap"
            case .history: return "History"
            case .settings: return "Settings"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                mainTabView
            }
        }
        .onAppear {
            setupViewModels()
        }
    }

    // MARK: - ViewModel Setup

    private func setupViewModels() {
        guard eventCreationVM == nil else { return }

        let creationVM = EventCreationViewModel(
            calendarService: calendarService,
            ocrService: ocrService,
            speechService: speechService,
            modelContext: modelContext
        )
        eventCreationVM = creationVM
        cameraVM = CameraViewModel(ocrService: ocrService)
        voiceVM = VoiceViewModel(speechService: speechService)
        textInputVM = TextInputViewModel()
        historyViewModel = HistoryViewModel(modelContext: modelContext, calendarService: calendarService)
        settingsViewModel = SettingsViewModel(calendarService: calendarService, permissionManager: permissionManager)
    }

    // MARK: - Input Handler

    private func handleInput(_ input: InputData) {
        guard let vm = eventCreationVM else { return }
        Task {
            switch input {
            case .image:
                vm.startCapture(.camera)
            case .text:
                vm.startCapture(.text)
            case .transcription:
                vm.startCapture(.voice)
            }
            await vm.processInput(input)
        }
    }

    // MARK: - Main Tab View (Premium Custom Tab Bar)

    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            // Content layers
            Group {
                switch selectedTab {
                case .capture:
                    captureContent
                case .history:
                    if let historyViewModel {
                        NavigationStack {
                            HistoryView(onNavigateToCapture: { selectedTab = .capture })
                                .environment(historyViewModel)
                                .navigationTitle("History")
                                .navigationBarTitleDisplayMode(.large)
                        }
                    }
                case .settings:
                    if let settingsViewModel {
                        NavigationStack {
                            SettingsView()
                                .environment(settingsViewModel)
                                .navigationTitle("Settings")
                                .navigationBarTitleDisplayMode(.large)
                        }
                    }
                }
            }

            // Premium floating tab bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .tint(Color.brandPrimary)
        // Observe creation state changes for navigation
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
            default:
                break
            }
        }
        // Event Preview Sheet
        .sheet(isPresented: $showEventPreview) {
            if let vm = eventCreationVM {
                EventPreviewView()
                    .environment(vm)
                    .environment(permissionManager)
            }
        }
        // Event Confirmation Full-Screen Cover
        .fullScreenCover(isPresented: $showEventConfirmation) {
            if let vm = eventCreationVM {
                EventConfirmationView()
                    .environment(vm)
            }
        }
    }

    // MARK: - Custom Premium Tab Bar

    private var customTabBar: some View {
        VStack(spacing: 0) {
            // Thin separator line
            Rectangle()
                .fill(colorScheme == .dark ? Color.borderSubtleDark : Color.borderSubtle)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(Tab.allCases) { tab in
                    Button {
                        withAnimation(EventAnimation.tabSwitch) {
                            selectedTab = tab
                        }
                        EventHaptics.tap()
                    } label: {
                        VStack(spacing: EventSpacing.xs) {
                            Image(systemName: selectedTab == tab ? tab.selectedIconName : tab.iconName)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(
                                    selectedTab == tab
                                    ? Color.brandPrimary
                                    : Color.textTertiary
                                )
                                .frame(height: 24)

                            Text(tab.title)
                                .font(EventTypography.caption2)
                                .foregroundStyle(
                                    selectedTab == tab
                                    ? Color.brandPrimary
                                    : Color.textTertiary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                }
            }
            .padding(.bottom, 4)
            .background(
                colorScheme == .dark
                ? Color.surfaceBaseDark
                : Color.surfaceRaised
            )
        }
    }

    // MARK: - Capture Content

    @ViewBuilder
    private var captureContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Input mode selector (premium pill)
                InputSelector(selectedMode: $inputMode)
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.top, EventSpacing.md)
                    .padding(.bottom, EventSpacing.lg)

                // Active input view
                switch inputMode {
                case .camera:
                    cameraView
                case .voice:
                    voiceView
                case .text:
                    textInputView
                }
            }
            .background(colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
            .navigationTitle("EventSnap")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Mode Views

    private var cameraView: some View {
        Group {
            if let cameraVM {
                CameraCaptureView(onImageCaptured: { image in
                    handleInput(.image(image))
                })
                .environment(cameraVM)
                .environment(permissionManager)
            }
        }
    }

    private var voiceView: some View {
        Group {
            if let voiceVM {
                VoiceInputView(onTranscriptionComplete: { text in
                    handleInput(.transcription(text))
                })
                .environment(voiceVM)
                .environment(permissionManager)
            }
        }
    }

    private var textInputView: some View {
        Group {
            if let textInputVM, eventCreationVM != nil {
                TextInputView(onTextSubmitted: { text in
                    handleInput(.text(text))
                })
                .environment(textInputVM)
            }
        }
    }
}

#Preview {
    ContentView()
}