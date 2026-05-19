import SwiftUI
import AVFoundation
import Speech
import EventKit

/// Settings view — copied directly from dimeApp's pattern:
/// ScrollView + grouped VStack sections + simple UPPERCASE headers.
/// Zero generics, zero complexity.
struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(\.colorScheme) private var style

    @State private var showIconPicker = false
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // App info header
                appInfoCard
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.top, EventSpacing.md)
                    .padding(.bottom, EventSpacing.xl)
                settingsSection(header: "DEFAULTS") {
                    if let cal = viewModel.defaultCalendar ?? viewModel.availableCalendars.first {
                        HStack(spacing: EventSpacing.sm) {
                            iconBox(systemName: "calendar", color: .brandSecondary)
                            Text("Default Calendar").font(EventTypography.body)
                            Spacer()
                            Text(cal.title).font(EventTypography.caption).foregroundStyle(Color.textTertiary)
                        }
                        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                        Divider().padding(.horizontal, EventSpacing.pageMargin)
                    }
                    HStack(spacing: EventSpacing.sm) {
                        iconBox(systemName: "clock.fill", color: .brandAccent)
                        Text("Default Duration").font(EventTypography.body)
                        Spacer()
                        Text(durationText).font(EventTypography.caption).foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                    Divider().padding(.horizontal, EventSpacing.pageMargin)
                    HStack(spacing: EventSpacing.sm) {
                        iconBox(systemName: "bell.fill", color: .semanticWarning)
                        Text("Default Reminder").font(EventTypography.body)
                        Spacer()
                        Text(alertText).font(EventTypography.caption).foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                }

                settingsSection(header: "PRIVACY & PERMISSIONS") {
                    HStack(spacing: EventSpacing.sm) {
                        iconBox(systemName: "lock.shield.fill", color: .semanticSuccess)
                        VStack(alignment: .leading, spacing: EventSpacing.xs) {
                            Text("On-Device Processing").font(EventTypography.body)
                            Text("All OCR, speech, and parsing happens locally.")
                                .font(EventTypography.caption).foregroundStyle(Color.textTertiary).lineLimit(2)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                    Divider().padding(.horizontal, EventSpacing.pageMargin)
                    permissionRow(icon: "camera.fill", title: "Camera", status: viewModel.cameraPermissionStatus)
                    Divider().padding(.horizontal, EventSpacing.pageMargin)
                    permissionRow(icon: "mic.fill", title: "Microphone", status: viewModel.microphonePermissionStatus)
                    Divider().padding(.horizontal, EventSpacing.pageMargin)
                    permissionRowSpeech()
                    Divider().padding(.horizontal, EventSpacing.pageMargin)
                    calendarPermissionRow()
                }

                settingsSection(header: "APPEARANCE") {
                    Button {
                        EventHaptics.tap()
                        showIconPicker = true
                    } label: {
                        HStack(spacing: EventSpacing.sm) {
                            iconBox(systemName: "app.badge.fill", color: .brandPrimary)
                            Text("App Icon").font(EventTypography.body)
                            Spacer()
                            Text(displayIconName).font(EventTypography.caption).foregroundStyle(Color.textTertiary)
                        }
                        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }

                settingsSection(header: "ABOUT") {
                    Button {
                        EventHaptics.tap()
                        if let url = URL(string: "https://eventsnap.app/privacy") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: EventSpacing.sm) {
                            iconBox(systemName: "doc.text.fill", color: .brandSecondary)
                            Text("Privacy Policy").font(EventTypography.body)
                            Spacer()
                        }
                        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.horizontal, EventSpacing.pageMargin)
                    Text("Version \(appVersion)")
                        .font(EventTypography.caption).foregroundStyle(Color.textTertiary)
                        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                }

                settingsSection(header: "ADVANCED", isLast: true) {
                    Button(role: .destructive) {
                        EventHaptics.warning()
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: EventSpacing.sm) {
                            iconBox(systemName: "arrow.counterclockwise", color: .semanticError)
                            Text("Reset to Defaults").font(EventTypography.body).foregroundStyle(Color.semanticError)
                            Spacer()
                        }
                        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, EventSpacing.floatingButtonPadding)
        }
        .background(style == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
        .onAppear {
            viewModel.refreshPermissionStatuses()
            viewModel.loadCalendars()
        }
        .sheet(isPresented: $showIconPicker) { iconPickerSheet }
        .alert("Reset to Defaults?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                EventHaptics.heavy()
                viewModel.resetToDefaults()
            }
        } message: {
            Text("This will restore default duration and alert settings. Your event history will not be affected.")
        }
    }

    private func settingsSection(header: String, isLast: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: EventSpacing.xs) {
            Text(header)
                .font(EventTypography.footnoteSemibold)
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, EventSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 0, content: content)
                .padding(EventSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: EventRadius.small)
                        .fill(style == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
                )
        }
        .padding(.horizontal, EventSpacing.pageMargin)
        .padding(.bottom, isLast ? 0 : EventSpacing.xl)
    }

    // MARK: - Helpers

    private func iconBox(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(EventTypography.body)
            .foregroundStyle(.white)
            .frame(width: EventSpacing.lg, height: EventSpacing.lg)
            .background(color, in: RoundedRectangle(cornerRadius: EventRadius.small))
    }

    private func permissionRow(icon: String, title: String, status: AVAuthorizationStatus) -> some View {
        HStack(spacing: EventSpacing.sm) {
            iconBox(systemName: icon, color: permColor(status))
            Text(title).font(EventTypography.body)
            Spacer()
            Text(permText(status)).font(EventTypography.caption).foregroundStyle(permColor(status))
        }
        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
    }

    private func calendarPermissionRow() -> some View {
        HStack(spacing: EventSpacing.sm) {
            iconBox(systemName: "calendar", color: permEKColor(from: viewModel.calendarPermissionStatus))
            Text("Calendar (Write-Only)").font(EventTypography.body)
            Spacer()
            Text(permEKText(from: viewModel.calendarPermissionStatus)).font(EventTypography.caption).foregroundStyle(permEKColor(from: viewModel.calendarPermissionStatus))
        }
        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
    }

    private func permColor(_ s: AVAuthorizationStatus) -> Color {
        switch s { case .authorized: return .semanticSuccess; case .denied, .restricted: return .semanticError; default: return .textTertiary }
    }
    private func permText(_ s: AVAuthorizationStatus) -> String {
        switch s { case .authorized: return "Granted"; case .denied, .restricted: return "Denied"; default: return "Not Set" }
    }
    private func permissionRowSpeech() -> some View {
        let status = SFSpeechRecognizer.authorizationStatus()
        return HStack(spacing: EventSpacing.sm) {
            iconBox(systemName: "waveform", color: permSpeechColor(from: status))
            Text("Speech Recognition").font(EventTypography.body)
            Spacer()
            Text(permSpeechText(from: status)).font(EventTypography.caption).foregroundStyle(permSpeechColor(from: status))
        }
        .padding(.horizontal, EventSpacing.pageMargin).padding(.vertical, EventSpacing.xs)
    }

    private func permSpeechColor(from status: SFSpeechRecognizerAuthorizationStatus) -> Color {
        switch status { case .authorized: return .semanticSuccess; case .denied, .restricted: return .semanticError; default: return .textTertiary }
    }
    private func permSpeechText(from status: SFSpeechRecognizerAuthorizationStatus) -> String {
        switch status { case .authorized: return "Granted"; case .denied, .restricted: return "Denied"; default: return "Not Set" }
    }
    private func permEKColor(from status: EKAuthorizationStatus) -> Color {
        switch status { case .fullAccess, .writeOnly: return .semanticSuccess; case .denied: return .semanticError; default: return .textTertiary }
    }
    private func permEKText(from status: EKAuthorizationStatus) -> String {
        switch status { case .fullAccess, .writeOnly: return "Granted"; case .denied: return "Denied"; default: return "Not Set" }
    }

    private var durationText: String {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]; f.unitsStyle = .full
        return f.string(from: viewModel.defaultDuration) ?? "1 hour"
    }

    private var alertText: String {
        let m = Int(-viewModel.defaultAlertOffset / 60)
        if m == 0 { return "At time of event" }
        if m >= 1440 { return "\(m/1440) day(s) before" }
        if m >= 60 { return "\(m/60) hour(s) before" }
        return "\(m) minutes before"
    }

    private var appInfoCard: some View {
        EventGlass.card {
            HStack(spacing: EventSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: EventRadius.medium)
                        .fill(LinearGradient(colors: [.brandPrimary, .brandAccent], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: EventSpacing.xl * 2, height: EventSpacing.xl * 2)
                    Image(systemName: "camera.viewfinder").font(EventTypography.tabBarIcon).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: EventSpacing.xs) {
                    Text("EventSnap").font(EventTypography.headline)
                    Text("Version \(appVersion)").font(EventTypography.caption).foregroundStyle(Color.textTertiary)
                }
                Spacer()
            }.padding(EventSpacing.md)
        }
    }

    // Icon picker sheet now handled by IconChangerView
    private var iconPickerSheet: some View {
        IconChangerView {
            showIconPicker = false
        }
    }

    /// Human-readable name for the currently active icon.
    private var displayIconName: String {
        guard let name = UIApplication.shared.alternateIconName else { return "Default" }
        switch name {
        case "AppIcon-Brackets":   return "Brackets"
        case "AppIcon-Monogram":   return "Monogram"
        case "AppIcon-ShieldDot":  return "Shield Dot"
        case "AppIcon-ShieldLens": return "Shield Lens"
        default:                   return "Custom"
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}
