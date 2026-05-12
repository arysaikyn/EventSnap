=import SwiftUI
import SwiftData

@main
struct EventSnapApp: App {
    // MARK: - SwiftData Container
    private let modelContainer: ModelContainer = {
        do {
            let schema = Schema([
                EventHistory.self,
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // Log the error for debugging before crashing
            assertionFailure("Failed to create ModelContainer: \(error.localizedDescription)")
            // In production, this is fatal — SwiftData is essential
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    // MARK: - Services
    @State private var calendarService = CalendarService()
    @State private var permissionManager = PermissionManager()
    @State private var ocrService = OCRService()
    @State private var speechService = SpeechService()

    // MARK: - Environment
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Deep Link State
    @State private var pendingDeepLink: URL? = nil

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(calendarService)
                .environment(permissionManager)
                .environment(speechService)
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onAppear {
                    // Privacy-first: no permissions requested at launch
                    registerForLifecycleNotifications()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                handleBecomeActive()
            case .inactive:
                handleBecomeInactive()
            case .background:
                handleEnterBackground()
            @unknown default:
                break
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        // Validate URL scheme
        guard url.scheme == "eventsnap" else { return }

        // Validate URL structure
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }

        // Validate host against allowed values
        let allowedHosts: Set<String> = ["capture", "history", "event"]
        guard allowedHosts.contains(host) else { return }

        pendingDeepLink = url

        switch host {
        case "capture":
            // Future: navigate to capture tab
            break
        case "history":
            // Future: navigate to history tab
            break
        case "event":
            // Future: navigate to specific event by ID
            // e.g., eventsnap://event/123
            let pathComponents = components.path.components(separatedBy: "/").dropFirst()
            if let eventId = pathComponents.first, !eventId.isEmpty {
                // Future: navigate to specific event detail
            }
            break
        default:
            break
        }

        pendingDeepLink = nil
    }

    // MARK: - Lifecycle Notifications (iOS <17 fallback)

    private func registerForLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            cleanupResources()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            cleanupResources()
        }
    }

    // MARK: - Lifecycle Handlers

    private func handleBecomeActive() {
        // App came to foreground - no automatic permission requests
    }

    private func handleBecomeInactive() {
        // App about to become inactive
    }

    private func handleEnterBackground() {
        cleanupResources()
    }

    private func cleanupResources() {
        // Clean up camera resources
        Task { @MainActor in
            await ocrService.releaseCachedData()
            speechService.stopRecording()
        }
    }
}
