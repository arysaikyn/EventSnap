import SwiftUI
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
                for: EventHistory.self,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            assertionFailure("Failed to create ModelContainer: \(error.localizedDescription)")
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    // MARK: - Services
    @State private var calendarService = CalendarService()
    @State private var permissionManager = PermissionManager()
    @State private var speechService = SpeechService()
    // NOTE: OCRService is created and owned by ContentView — lifecycle cleanup is handled there

    // MARK: - Environment
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Deep Link State
    @State private var pendingDeepLink: URL? = nil

    // MARK: - Lifecycle Observers
    @State private var backgroundObserver: NSObjectProtocol?
    @State private var terminateObserver: NSObjectProtocol?

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
            setupLifecycleObservers()
        }
        .onDisappear {
            removeLifecycleObservers()
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
        // Guard against excessively long URLs
        guard url.absoluteString.count <= 2048 else { return }

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
            break
        case "history":
            break
        case "event":
            let pathComponents = components.path
                .components(separatedBy: "/")
                .dropFirst()
                .filter { !$0.isEmpty }

            if let eventId = pathComponents.first,
               !eventId.isEmpty,
               eventId.count <= 64,
               isValidPathComponent(eventId) {
                // Future: navigate to specific event by ID
            }
            break
        default:
            break
        }

        pendingDeepLink = nil
    }

    /// Validates a path component for injection safety.
    private func isValidPathComponent(_ component: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return component.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    // MARK: - Lifecycle Notifications

    private func setupLifecycleObservers() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App entered background — nothing critical to clean up
        }

        terminateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App terminating — stop speech if active
        }
    }

    private func removeLifecycleObservers() {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = terminateObserver {
            NotificationCenter.default.removeObserver(observer)
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
        // App entered background
    }
}
