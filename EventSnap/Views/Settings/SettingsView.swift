import SwiftUI
import AVFoundation
import Speech
import EventKit

/// Standard grouped Form with sections for defaults, privacy, appearance, and about.
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

    var body: some View {
        Form {
            // MARK: - Defaults Section
            Section {
                // Default Calendar
                let selectedCalendar = viewModel.defaultCalendar ?? viewModel.availableCalendars.first
                Picker("Default Calendar", selection: Binding<EKCalendar?>(
                    get: { selectedCalendar },
                    set: { newValue in
                        if let cal = newValue {
                            viewModel.updateDefaultCalendar(cal)
                        }
                    }
                )) {
                    ForEach(viewModel.availableCalendars, id: \.calendarIdentifier) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(cgColor: calendar.cgColor))
                                .frame(width: 10, height: 10)
                            Text(calendar.title)
                        }
                        .tag(calendar as EKCalendar?)
                    }
                }
                .frame(minHeight: 44)

                // Default Duration
                Picker("Default Duration", selection: Binding(
                    get: { viewModel.defaultDuration },
                    set: { viewModel.updateDefaultDuration($0) }
                )) {
                    ForEach(durationOptions, id: \.interval) { option in
                        Text(option.label).tag(option.interval)
                    }
                }
                .frame(minHeight: 44)

                // Default Alert
                Picker("Default Alert", selection: Binding(
                    get: { viewModel.defaultAlertOffset },
                    set: { viewModel.updateDefaultAlertOffset($0) }
                )) {
                    ForEach(alertOptions, id: \.offset) { option in
                        Text(option.label).tag(option.offset)
                    }
                }
                .frame(minHeight: 44)
            } header: {
                Label("Defaults", systemImage: "gearshape.2")
            }

            // MARK: - Privacy Section
            Section {
                // On-device processing info
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
.foregroundColor(Color.privacyGreen)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("On-Device Processing")
                            .font(.body.weight(.medium))
                        Text("All event data is processed locally. Nothing is sent to servers.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minHeight: 44)

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
            }

            // MARK: - Appearance Section
            Section {
                Button {
                    showIconPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "app.gift")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("App Icon")
                                .font(.body.weight(.medium))
                                .foregroundColor(.primary)
                            Text(viewModel.selectedAppIcon ?? "Default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            } header: {
                Label("Appearance", systemImage: "paintbrush")
            }
            .sheet(isPresented: $showIconPicker) {
                appIconPicker
            }

            // MARK: - About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 44)

                NavigationLink {
                    acknowledgementsView
                } label: {
                    Text("Acknowledgements")
                        .frame(minHeight: 44)
                }
            } header: {
                Label("About", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .tint(Color.accentPrimary)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))

                Text(status)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }

            Spacer()

            if needsSettings {
                Button("Fix") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.accentPrimary)
                .frame(minWidth: 44, minHeight: 44)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundColor(Color.privacyGreen)
            }
        }
        .frame(minHeight: 44)
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
                    spacing: 20
                ) {
                    ForEach(appIconOptions, id: \.name) { icon in
                        Button {
                            viewModel.selectedAppIcon = icon.name
                            showIconPicker = false
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: icon.systemImage)
                                    .font(.system(size: 36))
                                    .foregroundColor(iconColor(for: icon.name))
                                    .frame(width: 72, height: 72)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(iconBackground(for: icon.name))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                viewModel.selectedAppIcon == icon.name
                                                    ? Color.accentPrimary
                                                    : Color.secondary.opacity(0.2),
                                                lineWidth: viewModel.selectedAppIcon == icon.name ? 3 : 1
                                            )
                                    )

                                Text(icon.displayName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("\(icon.displayName) icon")
                        .accessibilityAddTraits(viewModel.selectedAppIcon == icon.name ? .isSelected : [])
                    }
                }
                .padding(24)
            }
            .background(
                colorScheme == .dark ? Color(.systemGray6) : Color(.systemGroupedBackground)
            )
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showIconPicker = false
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.accentPrimary)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    // MARK: - Acknowledgements

    private var acknowledgementsView: some View {
        List {
            ForEach(acknowledgements, id: \.name) { ack in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ack.name)
                            .font(.body.weight(.medium))
                        if let license = ack.license {
                            Text(license)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    if let url = ack.url {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(Color.accentTeal)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                }
                .frame(minHeight: 44)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Permission Color Helpers

    private func permissionStatusColor(for status: AVAuthorizationStatus) -> Color {
        status == .authorized ? Color.privacyGreen : (status == .notDetermined ? .secondary : Color.accentPrimary)
    }

    private func permissionStatusColor(for status: SFSpeechRecognizerAuthorizationStatus) -> Color {
        status == .authorized ? Color.privacyGreen : (status == .notDetermined ? .secondary : Color.accentPrimary)
    }

    private func permissionStatusColor(for status: EKAuthorizationStatus) -> Color {
        (status == .authorized || status == .writeOnly || status == .fullAccess) ? Color.privacyGreen : (status == .notDetermined ? .secondary : Color.accentPrimary)
    }

    // MARK: - Icon Helpers

    private func iconColor(for name: String?) -> Color {
        switch name {
        case "AppIconClassic": return Color.accentPrimary
        case "AppIconDark": return .primary
        case "AppIconLight": return Color.accentTeal
        case "AppIconPride": return .pink
        case "AppIconMono": return .secondary
        default: return Color.accentPrimary
        }
    }

    private func iconBackground(for name: String?) -> Color {
        switch name {
        case "AppIconDark": return Color.black
        case "AppIconLight": return Color.white
        case "AppIconPride": return Color.pink.opacity(0.15)
        case "AppIconMono": return Color.secondary.opacity(0.15)
        default: return Color.accentPrimary.opacity(0.1)
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