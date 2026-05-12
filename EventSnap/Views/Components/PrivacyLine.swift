import SwiftUI

/// A bottom-of-card privacy disclosure line: lock icon + "Processed on-device"
struct PrivacyLine: View {
    @Environment(\.colorScheme) private var colorScheme

    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.shield")
                .font(.caption2)
            Text("Processed on-device")
                .font(.caption2)
        }
        .foregroundColor(textColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Privacy: Processed on-device")
    }
}

#if DEBUG
struct PrivacyLine_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrivacyLine()
            PrivacyLine()
                .preferredColorScheme(.dark)
        }
        .padding()
    }
}
#endif