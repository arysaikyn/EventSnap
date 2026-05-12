import SwiftUI

/// A pill-shaped badge showing the lock.shield.fill icon with "On-Device" text in privacy green.
struct OnDeviceBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.shield.fill")
                .font(.caption2.weight(.semibold))
            Text("On-Device")
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            Capsule()
                .fill(Color.privacyGreen)
        )
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
        .accessibilityLabel("On-device processing")
        .accessibilityHint("All data is processed locally on your device")
    }
}

#if DEBUG
struct OnDeviceBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            OnDeviceBadge()
            OnDeviceBadge()
                .preferredColorScheme(.dark)
        }
        .padding()
    }
}
#endif