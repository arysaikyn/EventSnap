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
                .font(EventTypography.bigNumber)
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
            }
            .buttonStyle(EnhancedPrimaryButtonStyle(icon: "gear"))
            .frame(width: 200)
            .accessibilityLabel("Open Settings to grant permission")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                if colorScheme == .dark {
                    Color.surfaceBaseDark.ignoresSafeArea()
                } else {
                    Color.surfaceBase.ignoresSafeArea()
                }
                EventMeshGradient.accentBackground()
            }
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