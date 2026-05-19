import SwiftUI

/// Privacy badge: "On-Device" with green shield icon.
/// Placed in top-left of camera and voice views.
/// Typography-first, minimal color.
struct OnDeviceBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: EventSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(EventTypography.captionMedium)
                .foregroundStyle(Color.semanticSuccess)

            Text("On-Device")
                .font(EventTypography.footnoteSemibold)
                .foregroundStyle(
                    colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary
                )
        }
        .padding(.horizontal, EventSpacing.md)
        .padding(.vertical, EventSpacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
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
    }
}
#endif