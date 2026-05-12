import SwiftUI

/// A custom segmented control for switching between Camera, Voice, and Text input modes.
/// Features a sliding pill indicator with spring animation.
struct InputSelector: View {
    @Binding var selectedMode: InputMode
    @Namespace private var namespace
    @Environment(\.colorScheme) private var colorScheme

    private let modes: [InputMode] = [.camera, .voice, .text]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.iconName)
                            .font(.title3.weight(.medium))
                            .frame(height: 22)
                        Text(mode.title)
                            .font(.caption2.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundColor(selectedMode == mode ? .white : .secondary)
                    .background(
                        ZStack {
                            if selectedMode == mode {
                                Capsule()
                                    .fill(Color.accentPrimary)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                                    .shadow(color: Color.accentPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.title) input mode")
                .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
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