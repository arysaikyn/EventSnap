import SwiftUI

/// Permission-denied overlay with explanation and an "Open Settings" button.
struct PermissionOverlay: View {
    let title: String
    let message: String
    let iconName: String

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.85) : Color.white.opacity(0.95)
    }

    var body: some View {
        backgroundColor
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    Image(systemName: iconName)
                        .font(.system(size: 48))
                        .foregroundColor(Color.accentPrimary)

                    Text(title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gearshape")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(Color.accentPrimary)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Settings to grant permission")
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(24)
            )
    }
}

#if DEBUG
struct PermissionOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PermissionOverlay(
                title: "Camera Access Needed",
                message: "EventSnap needs camera access to scan event flyers, posters, and invitations.",
                iconName: "camera.fill"
            )
            PermissionOverlay(
                title: "Microphone Access Needed",
                message: "EventSnap needs microphone access to capture voice input for events.",
                iconName: "mic.fill"
            )
            .preferredColorScheme(.dark)
        }
    }
}
#endif