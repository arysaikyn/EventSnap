import SwiftUI

/// Premium segmented control with sliding pill indicator and spring animation.
/// Inspired by Raycast's mode switcher — minimal, precise, typography-first.
struct InputSelector: View {
    @Binding var selectedMode: InputMode
    @Namespace private var namespace
    @Environment(\.colorScheme) private var colorScheme

    private let modes: [InputMode] = [.camera, .voice, .text]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(EventAnimation.tabSwitch) {
                        selectedMode = mode
                    }
                    EventHaptics.selection()
                } label: {
                    HStack(spacing: EventSpacing.sm) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 16, weight: .medium))

                        Text(mode.title)
                            .font(EventTypography.captionMedium)
                    }
                    .foregroundStyle(selectedMode == mode ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        ZStack {
                            if selectedMode == mode {
                                Capsule()
                                    .fill(Color.brandPrimary)
                                    .matchedGeometryEffect(id: "selectorPill", in: namespace)
                                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.title) input mode")
                .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
                .frame(minWidth: EventSpacing.touchTarget, minHeight: 36)
            }
        }
        .padding(EventSpacing.xs)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
        )
    }
}

#if DEBUG
struct InputSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            InputSelector(selectedMode: .constant(.camera))
                .padding(.horizontal)
            InputSelector(selectedMode: .constant(.voice))
                .padding(.horizontal)
            InputSelector(selectedMode: .constant(.text))
                .padding(.horizontal)
            InputSelector(selectedMode: .constant(.camera))
                .preferredColorScheme(.dark)
                .padding(.horizontal)
        }
        .padding()
    }
}
#endif