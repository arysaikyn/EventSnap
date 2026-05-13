import SwiftUI

/// Privacy reassurance line: "Your data stays on this device."
/// Used at the bottom of event preview and confirmation screens.
struct PrivacyLine: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: EventSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.semanticSuccess)

            Text("Your data stays on this device")
                .font(EventTypography.footnote)
                .foregroundStyle(
                    colorScheme == .dark ? Color.textTertiaryDark : Color.textTertiary
                )
        }
        .padding(.vertical, EventSpacing.sm)
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
    }
}
#endif