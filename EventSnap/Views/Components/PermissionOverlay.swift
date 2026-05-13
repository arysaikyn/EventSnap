import SwiftUI

/// Permission denied overlay — clean, actionable, typography-first.
struct PermissionOverlay: View {
    let title: String
    let message: String
    let iconName: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: EventSpacing.xxl) {
            // Icon in subtle circle
            Image(systemName: iconName)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.12))
                )

            VStack(spacing: EventSpacing.sm) {
                Text(title)
                    .font(EventTypography.sectionTitle)
                    .foregroundStyle(
                        colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary
                    )

                Text(message)
                    .font(EventTypography.subheadline)
                    .foregroundStyle(
                        colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EventSpacing.xl)
            }

            // Open Settings button
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(EventTypography.bodyMedium)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: EventSpacing.smallButtonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: EventRadius.medium)
                            .fill(Color.brandPrimary)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Settings to grant permission")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase
        )
    }
}

#if DEBUG
struct PermissionOverlay_Previews: PreviewProvider {
    static var previews: some View {
        PermissionOverlay(
            title: "Camera Access Needed",
            message: "EventSnap needs camera access to scan event flyers and invitations.",
            iconName: "camera.fill"
        )
    }
}
#endif