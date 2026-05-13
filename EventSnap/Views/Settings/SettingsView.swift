import SwiftUI
import AVFoundation
import Speech
import EventKit

/// Standard grouped Form with sections for defaults, privacy, appearance, and about.
/// Polished with brandPrimary tint, semantic status colors, and design system tokens.
struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showIconPicker = false

    private let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .full
        return f
    }()

    private var surface: AdaptiveSurface {
        AdaptiveSurface(scheme: colorScheme)
    }

    var body: some View {
        let selectedCalendar = viewModel.defaultCalendar ?? viewModel.availableCalendars.first

        return Form {
            // MARK: - Defaults Section
            Section {
                // Default Calendar
                Picker("Default Calendar", selection: Binding<EKCalendar?>(
                    get: { selectedCalendar },
                    set: { newValue in
                        if let cal = newValue {
                            viewModel.updateDefaultCalendar(cal)
                        }
                    }
                )) {
                    ForEach(viewModel.availableCalendars, id: \.calendarIdentifier) { calendar in
                        HStack(spacing: EventSpacing.sm) {
                            Circle()
                                .fill(Color(cgColor: calendar.cgColor))
                                .frame(width: 10, height: 10)
                            Text(calendar.title)
                                .font(EventTypography.body)
                        }
                        .tag(calendar as EKCalendar?)
                    }
                }
                .frame(minHeight: EventSpacing.touchTarget)

                // Default Duration
                Picker("Default Duration", selection: Binding(
                    get: { viewModel.defaultDuration },
                    set: { viewModel.updateDefaultDuration($0) }
                )) {
                    ForEach(durationOptions, id: \.interval) { option in
                        Text(option.label)
                            .font(EventTypography.body)
                            .tag(option.interval)
                    }
                }
                .frame(minHeight: EventSpacing.touchTarget)

                // Default Alert
                Picker("Default Alert", selection: Binding(
                    get: { viewModel.defaultAlertOffset },
                    set: { viewModel.updateDefaultAlertOffset($0) }
                )) {
                    ForEach(alertOptions, id: \.offset) { option in
                        Text(option.label)
                            .font(EventTypography.body)
                            .tag(option.offset)
                    }
                }
                .frame(minHeight: EventSpacing.touchTarget)
            } header: {
                Label("Defaults", systemImage: "gearshape.2")
                    .font(EventTypography.subheadSemibold)
            }

            // MARK: - Privacy Section
            Section {
                // On-device processing info
                HStack(spacing: EventSpacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundColor(Color.semanticSuccess)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("On-Device Processing")
                            .font(EventTypography.bodyMedium)
                            .foregroundColor(surface.textPrimary)
                        Text("All event data is processed locally. Nothing is sent to servers.")
                            .font(EventTypography.footnote)
                            .foregroundColor(surface.textTertiary)
                    }
                }
                .frame(minHeight: EventSpacing.touchTarget)

                // Camera permission
                permissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    status: permissionManager.cameraStatus.description,
                    statusColor: permissionStatusColor(for: permissionManager.cameraStatus),
                    needsSettings: permissionManager.needsSettingsRedirect(for: .camera)
                )

                // Microphone permission
                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    status: permissionManager.microphoneStatus.description,
                    statusColor: permissionStatusColor(for: permissionManager.microphoneStatus),
                    needsSettings: permissionManager.needsSettingsRedirect(for: .microphone)
                )

                // Speech recognition
                permissionRow(
                    icon: "waveform",
                    title: "Speech Recognition",
                    status: permissionManager.speechStatus.description,
                    statusColor: permissionStatusColor(for: permissionManager.speechStatus),
                    needsSettings: permissionManager.needsSettingsRedirect(for: .speech)
                )

                // Calendar
                permissionRow(
                    icon: "calendar",
                    title: "Calendar",
                    status: permissionManager.calendarStatus.description,
                    statusColor: permissionStatusColor(for: permissionManager.calendarStatus),
                    needsSettings: permissionManager.needsSettingsRedirect(for: .calendar)
                )
            } header: {
                Label("Privacy", systemImage: "hand.raised.fill")
                    .font(EventTypography.subheadSemibold)
            }

            // MARK: - Appearance Section
            Section {
                Button {
                    showIconPicker = true
                } label: {
                    HStack(spacing: EventSpacing.md) {
                        Image(systemName: "app.gift")
                            .font(.title2)
                            .foregroundColor(Color.brandPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: EventRadius.small)
                                    .fill(Color.brandPrimary.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Icon")
                                .font(EventTypography.bodyMedium)
                                .foregroundColor(surface.textPrimary)
                            Text(viewModel.selectedAppIcon ?? "Default")
                                .font(EventTypography.footnote)
                                .foregroundColor(surface.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(EventTypography.caption)
                            .foregroundColor(surface.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .frame(minHeight: EventSpacing.touchTarget)
            } header: {
                Label("Appearance", systemImage: "paintbrush")
                    .font(EventTypography.subheadSemibold)
            }
            .sheet(isPresented: $showIconPicker) {
                appIconPicker
            }

            // MARK: - About Section
            Section {
                HStack {
                    Text("Version")
                        .font(EventTypography.body)
                        .foregroundColor(surface.textPrimary)
                    Spacer()
                    Text("1.0.0")
                        .font(EventTypography.body)
                        .foregroundColor(surface.textTertiary)
                }
                .frame(minHeight: EventSpacing.touchTarget)

                NavigationLink {
                    acknowledgementsView
                } label: {
                    Text("Acknowledgements")
                        .font(EventTypography.body)
                        .foregroundColor(surface.textPrimary)
                        .frame(minHeight: EventSpacing.touchTarget)
                }
            } header: {
                Label("About", systemImage: "info.circle")
                    .font(EventTypography.subheadSemibold)
            }
        }
        .formStyle(.grouped)
        .tint(Color.brandPrimary)
        .onAppear {
            viewModel.refreshPermissionStatuses()
            viewModel.loadCalendars()
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            if let error {
                // Surface error to user via alert or toast
                print("Settings error: \(error)")
            }
        }
    }

    // MARK: - Permission Row

    private func permissionRow(
        icon: String,
        title: String,
        status: String,
        statusColor: Color,
        needsSettings: Bool
    ) -> some View {
        HStack(spacing: EventSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(EventTypography.bodyMedium)
                    .foregroundColor(surface.textPrimary)

                Text(status)
                    .font(EventTypography.footnote)
                    .foregroundColor(statusColor)
            }

            Spacer()

            if needsSettings {
                Button("Fix") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(EventTypography.footnoteSemibold)
                .foregroundColor(Color.brandPrimary)
                .frame(minWidth: 44, minHeight: EventSpacing.touchTarget)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(Color.semanticSuccess)
            }
        }
        .frame(minHeight: EventSpacing.touchTarget)
    }

    // MARK: - App Icon Picker

    private var appIconPicker: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: EventSpacing.xl
                ) {
                    ForEach(appIconOptions, id: \.name) { icon in
                        Button {
                            viewModel.selectedAppIcon = icon.name
                            showIconPicker = false
                        } label: {
                            VStack(spacing: EventSpacing.sm) {
                                Image(systemName: icon.systemImage)
                                    .font(.system(size: 36))
                                    .foregroundColor(iconColor(for: icon.name))
                                    .frame(width: 72, height: 72)
                                    .background(
                                        RoundedRectangle(cornerRadius: EventRadius.large)
                                            .fill(iconBackground(for: icon.name))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: EventRadius.large)
                                            .stroke(
                                                viewModel.selectedAppIcon == icon.name
                                                    ? Color.brandPrimary
                                                    : surface.border,
                                                lineWidth: viewModel.selectedAppIcon == icon.name ? 3 : 1
                                            )
                                    )

                                Text(icon.displayName)
                                    .font(EventTypography.caption)
                                    .foregroundColor(surface.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: EventSpacing.touchTarget)
                        .accessibilityLabel("\(icon.displayName) icon")
                        .accessibilityAddTraits(viewModel.selectedAppIcon == icon.name ? .isSelected : [])
                    }
                }
                .padding(EventSpacing.xxl)
            }
            .background(surface.background)
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showIconPicker = false
                    }
                    .font(EventTypography.bodyMedium)
                    .foregroundColor(Color.brandPrimary)
                    .frame(minWidth: 44, minHeight: EventSpacing.touchTarget)
                }
            }
        }
    }

    // MARK: - Acknowledgements

    private var acknowledgementsView: some View {
        List {
            ForEach(acknowledgements, id: \.name) { ack in
                HStack(spacing: EventSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ack.name)
                            .font(EventTypography.bodyMedium)
                            .foregroundColor(surface.textPrimary)
                        if let license = ack.license {
                            Text(license)
                                .font(EventTypography.footnote)
                                .foregroundColor(surface.textTertiary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    if let url = ack.url {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(Color.brandSecondary)
                        }
                        .frame(minWidth: 44, minHeight: EventSpacing.touchTarget)
                    }
                }
                .frame(minHeight: EventSpacing.touchTarget)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Permission Color Helpers

    private func permissionStatusColor(for status: AVAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return Color.semanticSuccess
        case .denied, .restricted: return Color.semanticError
        case .notDetermined: return surface.textTertiary
        @unknown default: return surface.textTertiary
        }
    }

    private func permissionStatusColor(for status: SFSpeechRecognizerAuthorizationStatus) -> Color {
        switch status {
        case .authorized: return Color.semanticSuccess
        case .denied, .restricted: return Color.semanticError
        case .notDetermined: return surface.textTertiary
        @unknown default: return surface.textTertiary
        }
    }

    private func permissionStatusColor(for status: EKAuthorizationStatus) -> Color {
        switch status {
        case .writeOnly, .fullAccess: return Color.semanticSuccess
        case .denied, .restricted: return Color.semanticError
        case .notDetermined: return surface.textTertiary
        @unknown default: return surface.textTertiary
        }
    }

    // MARK: - Icon Helpers

    private func iconColor(for name: String?) -> Color {
        switch name {
        case "AppIconClassic": return Color.brandPrimary
        case "AppIconDark": return .primary
        case "AppIconLight": return Color.brandSecondary
        case "AppIconPride": return .pink
        case "AppIconMono": return surface.textTertiary
        default: return Color.brandPrimary
        }
    }

    private func iconBackground(for name: String?) -> Color {
        switch name {
        case "AppIconDark": return Color.black
        case "AppIconLight": return Color.white
        case "AppIconPride": return Color.pink.opacity(0.15)
        case "AppIconMono": return surface.textTertiary.opacity(0.15)
        default: return Color.brandPrimary.opacity(0.1)
        }
    }

    // MARK: - Data

    private let durationOptions: [(label: String, interval: TimeInterval)] = [
        ("30 minutes", 1800),
        ("1 hour", 3600),
        ("1.5 hours", 5400),
        ("2 hours", 7200),
        ("3 hours", 10800),
        ("All day", 86400),
    ]

    private let alertOptions: [(label: String, offset: TimeInterval)] = [
        ("None", 0),
        ("At time of event", 0),
        ("5 minutes before", -300),
        ("15 minutes before", -900),
        ("30 minutes before", -1800),
        ("1 hour before", -3600),
        ("1 day before", -86400),
    ]

    private let appIconOptions: [(name: String?, displayName: String, systemImage: String)] = [
        (nil, "Default", "app.badge"),
        ("AppIconClassic", "Classic", "app.badge.fill"),
        ("AppIconDark", "Dark", "moon.fill"),
        ("AppIconLight", "Light", "sun.max.fill"),
        ("AppIconPride", "Pride", "sparkles"),
        ("AppIconMono", "Mono", "circle.lefthalf.fill"),
    ]

    private let acknowledgements: [(name: String, license: String?, url: URL?)] = [
        ("SwiftSoup", "MIT License", URL(string: "https://github.com/scinfu/SwiftSoup")),
        ("Lottie", "Apache 2.0", URL(string: "https://github.com/airbnb/lottie-ios")),
        ("SwiftGen", "MIT License", URL(string: "https://github.com/SwiftGen/SwiftGen")),
    ]
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environment(SettingsViewModel(
                    calendarService: CalendarService(),
                    permissionManager: PermissionManager()
                ))
                .environment(PermissionManager())
                .navigationTitle("Settings")
        }
    }
}
#endif