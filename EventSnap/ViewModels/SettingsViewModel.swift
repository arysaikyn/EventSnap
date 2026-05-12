import SwiftUI
import EventKit
import AVFoundation
import Speech

@Observable
final class SettingsViewModel {
    // MARK: - Published State

    var defaultCalendar: EKCalendar?
    var defaultDuration: TimeInterval {
        didSet { persistDouble(defaultDuration, forKey: Self.defaultDurationKey) }
    }
    var defaultAlertOffset: TimeInterval {
        didSet { persistDouble(defaultAlertOffset, forKey: Self.defaultAlertOffsetKey) }
    }
    var availableCalendars: [EKCalendar] = []
    var selectedAppIcon: String? {
        didSet { applyAppIcon(selectedAppIcon) }
    }

    // Permission statuses
    var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    var microphonePermissionStatus: AVAuthorizationStatus = .notDetermined
    var calendarPermissionStatus: EKAuthorizationStatus = .notDetermined

    // Error / feedback
    var errorMessage: String?

    // MARK: - Dependencies

    private let calendarService: CalendarService
    private let permissionManager: PermissionManager

    // MARK: - Constants

    private static let defaultDurationKey = "com.eventsnap.settings.defaultDuration"
    private static let defaultAlertOffsetKey = "com.eventsnap.settings.defaultAlertOffset"
    static let defaultDurationValue: TimeInterval = 3600      // 1 hour
    static let defaultAlertOffsetValue: TimeInterval = -900   // 15 min before
    static let minimumDuration: TimeInterval = 300            // 5 min

    // MARK: - Init

    init(calendarService: CalendarService, permissionManager: PermissionManager) {
        self.calendarService = calendarService
        self.permissionManager = permissionManager

        // Load persisted values (or use defaults)
        let storedDuration = UserDefaults.standard.double(forKey: Self.defaultDurationKey)
        self.defaultDuration = storedDuration.isZero ? Self.defaultDurationValue : storedDuration

        let storedOffset = UserDefaults.standard.double(forKey: Self.defaultAlertOffsetKey)
        self.defaultAlertOffset = storedOffset.isZero ? Self.defaultAlertOffsetValue : storedOffset

        loadCalendars()
        refreshPermissionStatuses()
    }

    // MARK: - Calendar

    /// Refresh the list of available calendars and the current default.
    func loadCalendars() {
        availableCalendars = calendarService.availableCalendars
        defaultCalendar = calendarService.defaultCalendar
    }

    /// Set a new default calendar for event creation.
    func updateDefaultCalendar(_ calendar: EKCalendar) {
        calendarService.setDefaultCalendar(calendar)
        defaultCalendar = calendar
    }

    /// Coerce duration to a minimum of 5 minutes and persist.
    func updateDefaultDuration(_ duration: TimeInterval) {
        defaultDuration = max(Self.minimumDuration, duration)
    }

    /// Alert offset must be ≤ 0 (before the event). Persist.
    func updateDefaultAlertOffset(_ offset: TimeInterval) {
        defaultAlertOffset = min(0, offset)
    }

    // MARK: - Permissions

    /// Request calendar access and refresh the calendar list on success.
    func requestCalendarAccess() async {
        let granted = await permissionManager.requestCalendarAccess()
        if granted {
            loadCalendars()
        }
        refreshPermissionStatuses()
    }

    /// Request camera access.
    func requestCameraAccess() async {
        await permissionManager.requestCameraAccess()
        refreshPermissionStatuses()
    }

    /// Request microphone access.
    func requestMicrophoneAccess() async {
        await permissionManager.requestMicrophoneAccess()
        refreshPermissionStatuses()
    }

    /// Refresh all cached permission statuses from `PermissionManager`.
    func refreshPermissionStatuses() {
        cameraPermissionStatus = permissionManager.cameraStatus
        microphonePermissionStatus = permissionManager.microphoneStatus
        calendarPermissionStatus = permissionManager.calendarStatus
    }

    // MARK: - App Icon

    /// Set the app's alternate icon. Pass `nil` to revert to the primary icon.
    /// Only works if `CFBundleAlternateIcons` is configured in Info.plist.
    private func applyAppIcon(_ name: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        Task { @MainActor in
            do {
                try await UIApplication.shared.setAlternateIconName(name)
            } catch {
                errorMessage = "Could not change app icon: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Reset

    /// Restore all settings to their factory defaults.
    func resetToDefaults() {
        defaultDuration = Self.defaultDurationValue
        defaultAlertOffset = Self.defaultAlertOffsetValue
        UserDefaults.standard.removeObject(forKey: Self.defaultDurationKey)
        UserDefaults.standard.removeObject(forKey: Self.defaultAlertOffsetKey)
        errorMessage = nil
    }

    // MARK: - Persistence Helpers

    private func persistDouble(_ value: Double, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

// MARK: - Permission Display Helpers

extension AVAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted:    return "Restricted"
        case .denied:        return "Denied"
        case .authorized:    return "Authorized"
        @unknown default:    return "Unknown"
        }
    }
}

extension AVAudioSession.RecordPermission: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .undetermined: return "Not Determined"
        case .denied:       return "Denied"
        case .granted:      return "Granted"
        @unknown default:   return "Unknown"
        }
    }
}

extension EKAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted:    return "Restricted"
        case .denied:        return "Denied"
        case .authorized:    return "Authorized"
        case .fullAccess:    return "Full Access"
        case .writeOnly:     return "Write Only"
        @unknown default:    return "Unknown"
        }
    }
}

extension SFSpeechRecognizerAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied:        return "Denied"
        case .restricted:    return "Restricted"
        case .authorized:    return "Authorized"
        @unknown default:    return "Unknown"
        }
    }
}