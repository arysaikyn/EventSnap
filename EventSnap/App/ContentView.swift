import SwiftUI
import SwiftData

// MARK: - Content View (Coordinator)

struct ContentView: View {
    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .capture
    @State private var inputMode: InputMode = .camera

    // MARK: - Services (injected via environment)
    @Environment(CalendarService.self) private var calendarService
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(SpeechService.self) private var speechService
    @Environment(\.modelContext) private var modelContext

    // OCRService is an actor — can't use @Environment, so create it here
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

        var title: String {
            switch self {
            case .capture: return "Capture"
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

    /// Feeds input data into EventCreationViewModel and triggers the creation flow.
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

    // MARK: - Main Tab View

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Capture Tab
            NavigationStack {
                captureContent
                    .navigationTitle("EventSnap")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label(Tab.capture.title, systemImage: Tab.capture.iconName)
            }
            .tag(Tab.capture)

            // History Tab
            NavigationStack {
                if let historyViewModel {
                    HistoryView()
                        .environment(historyViewModel)
                        .navigationTitle("History")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            .tabItem {
                Label(Tab.history.title, systemImage: Tab.history.iconName)
            }
            .tag(Tab.history)

            // Settings Tab
            NavigationStack {
                if let settingsViewModel {
                    SettingsView()
                        .environment(settingsViewModel)
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.iconName)
            }
            .tag(Tab.settings)
        }
        .tint(Color.accentPrimary)
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

    // MARK: - Capture Content

    @ViewBuilder
    private var captureContent: some View {
        VStack(spacing: 0) {
            InputSelector(selectedMode: $inputMode)

            switch inputMode {
            case .camera:
                cameraView
            case .voice:
                voiceView
            case .text:
                textInputView
            }
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

// MARK: - Previews

#Preview {
    ContentView()
}