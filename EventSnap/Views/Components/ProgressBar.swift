import SwiftUI

/// Animated progress bar with two variants: deterministic (progress value) and pulsing indeterminate.
struct ProgressBar: View {
    let progress: Double  // 0.0–1.0
    let isPulsing: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var pulseOffset: CGFloat = -200

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorScheme == .dark ? Color.surfaceDimDark : Color.surfaceDim)

                if isPulsing {
                    // Indeterminate shimmer
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.0),
                                    Color.brandPrimary.opacity(0.6),
                                    Color.brandPrimary.opacity(0.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: pulseOffset)
                        .frame(width: geometry.size.width * 0.4)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                pulseOffset = geometry.size.width + 200
                            }
                        }
                } else {
                    // Deterministic fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.brandPrimary)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                        .animation(EventAnimation.default_, value: progress)
                }
            }
        }
        .frame(height: 4)
    }
}

/// Indeterminate progress bar (shorthand)
struct IndeterminateProgressBar: View {
    var body: some View {
        ProgressBar(progress: 0, isPulsing: true)
    }
}

#if DEBUG
struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBar(progress: 0.3, isPulsing: false)
                .padding(.horizontal)
            ProgressBar(progress: 0.7, isPulsing: false)
                .padding(.horizontal)
            IndeterminateProgressBar()
                .padding(.horizontal)
        }
    }
}
#endif