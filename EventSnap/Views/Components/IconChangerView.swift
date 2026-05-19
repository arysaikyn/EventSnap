import SwiftUI

// MARK: - IconChangerView

/// Grid-based icon selector that uses `UIApplication.shared.setAlternateIconName`
/// to switch between registered alternate icons.
struct IconChangerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var switchingIconName: String? = nil
    @State private var errorMessage: String? = nil
    @State private var currentIconName: String?

    let onIconChanged: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: EventSpacing.lg) {
                    // Current icon indicator
                    currentIconIndicator

                    // 2x2 grid of icon options
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: EventSpacing.lg),
                            GridItem(.flexible(), spacing: EventSpacing.lg)
                        ],
                        spacing: EventSpacing.xl
                    ) {
                        ForEach(iconOptions) { icon in
                            iconOptionButton(icon)
                        }
                    }
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.top, EventSpacing.xl)
                }
                .padding(.bottom, EventSpacing.floatingButtonPadding)
            }
            .background(colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        EventHaptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
            .alert("Couldn't Change Icon", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
        }
    }

    // MARK: - Current Icon Indicator

    private var currentIconIndicator: some View {
        VStack(spacing: EventSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: EventRadius.xl)
                    .fill(colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
                    .frame(width: 80, height: 80)
                if let thumbnail = thumbnailForIcon(currentIconName) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: EventRadius.large))
                } else {
                    Image(systemName: "app.badge.fill")
                        .font(EventTypography.settingsIcon)
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: EventRadius.xl)
                    .stroke(Color.brandPrimary.opacity(0.4), lineWidth: 2)
            )
            Text("Current Icon")
                .font(EventTypography.caption)
                .foregroundStyle(Color.textTertiary)
        }
    }

    // MARK: - Icon Option Button

    @ViewBuilder
    private func iconOptionButton(_ icon: IconOption) -> some View {
        Button {
            switchToIcon(icon)
        } label: {
            VStack(spacing: EventSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: EventRadius.xl)
                        .fill(iconBackground(icon.name))
                        .frame(width: 80, height: 80)
                    if let thumbnail = thumbnailForIcon(icon.name) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: EventRadius.large))
                    } else {
                        Image(systemName: icon.systemName)
                            .font(EventTypography.settingsIcon)
                            .foregroundStyle(.white)
                    }
                    // Loading overlay
                    if switchingIconName == icon.name {
                        RoundedRectangle(cornerRadius: EventRadius.xl)
                            .fill(Color.surfaceOverlay)
                            .frame(width: 80, height: 80)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                }
                // Selected indicator ring
                .overlay {
                    if currentIconName == icon.name && switchingIconName == nil {
                        RoundedRectangle(cornerRadius: EventRadius.xl)
                            .stroke(Color.brandPrimary, lineWidth: 3)
                    }
                }
                .animation(EventAnimation.quick, value: currentIconName)

                // Label
                Text(icon.displayName)
                    .font(EventTypography.subheadline)
                    .foregroundStyle(
                        currentIconName == icon.name
                            ? Color.brandPrimary
                            : Color.textSecondary
                    )
                    .fontWeight(currentIconName == icon.name ? .semibold : .regular)

                // "Active" badge
                if currentIconName == icon.name {
                    Text("Active")
                        .font(EventTypography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, EventSpacing.sm)
                        .padding(.vertical, EventSpacing.xs)
                        .background(Color.semanticSuccess, in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(switchingIconName != nil)
        .opacity(switchingIconName != nil && switchingIconName != icon.name ? 0.5 : 1.0)
    }

    // MARK: - Actions

    private func switchToIcon(_ icon: IconOption) {
        EventHaptics.selection()

        // If tapping the already-active icon, do nothing
        guard currentIconName != icon.name else { return }

        switchingIconName = icon.name
        errorMessage = nil

        let targetName = icon.name ?? nil // nil reverts to primary icon
        let supportsAlternates = UIApplication.shared.supportsAlternateIcons

        guard supportsAlternates else {
            switchingIconName = nil
            errorMessage = "App icon switching is not supported on this device."
            return
        }

        Task { @MainActor in
            do {
                try await UIApplication.shared.setAlternateIconName(targetName)
                currentIconName = targetName ?? UIApplication.shared.alternateIconName
                onIconChanged()
                EventHaptics.success()
            } catch {
                errorMessage = error.localizedDescription
            }
            switchingIconName = nil
        }
    }

    // MARK: - Helpers

    private func thumbnailForIcon(_ name: String?) -> UIImage? {
        guard let name else { return nil }
        return UIImage(named: name)
    }

    private func iconBackground(_ name: String?) -> Color {
        guard let name else {
            return Color.brandPrimary.opacity(0.15)
        }
        switch name {
        case "AppIcon-Brackets":
            return Color.brandPrimary.opacity(0.2)
        case "AppIcon-Monogram":
            return Color.brandSecondary.opacity(0.2)
        case "AppIcon-ShieldDot":
            return Color.brandAccent.opacity(0.2)
        case "AppIcon-ShieldLens":
            return Color(red: 0.35, green: 0.25, blue: 0.45).opacity(0.2)
        default:
            return Color.brandPrimary.opacity(0.15)
        }
    }

    // MARK: - Icon Options

    private struct IconOption: Identifiable {
        let id = UUID()
        let name: String?
        let displayName: String
        let systemName: String
    }

    private var iconOptions: [IconOption] {
        [
            IconOption(name: nil, displayName: "Default", systemName: "camera.viewfinder"),
            IconOption(name: "AppIcon-Brackets", displayName: "Brackets", systemName: "viewfinder"),
            IconOption(name: "AppIcon-Monogram", displayName: "Monogram", systemName: "textformat.size"),
            IconOption(name: "AppIcon-ShieldDot", displayName: "Shield Dot", systemName: "shield.checkered"),
            IconOption(name: "AppIcon-ShieldLens", displayName: "Shield Lens", systemName: "shield.lefthalf.filled"),
        ]
    }
}

// MARK: - Preview

#Preview {
    IconChangerView(onIconChanged: {})
}
