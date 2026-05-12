import SwiftUI

/// A 4pt height progress bar with accentPrimary fill and an optional pulse animation during processing.
struct ProgressBar: View {
    let progress: Double // 0.0 ... 1.0
    let isPulsing: Bool

    @State private var pulseOpacity: Double = 0.3
    @Environment(\.colorScheme) private var colorScheme

    private let accentColor = Color.accentPrimary
    private let barHeight: CGFloat = 4

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(trackColor)
                    .frame(height: barHeight)

                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress, height: barHeight)
                    .overlay(
                        isPulsing
                            ? RoundedRectangle(cornerRadius: 2)
                                .fill(accentColor)
                                .frame(width: geometry.size.width * progress, height: barHeight)
                                .opacity(pulseOpacity)
                            : nil
                    )
            }
        }
        .frame(height: barHeight)
        .onChange(of: isPulsing) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.7
                }
            } else {
                pulseOpacity = 0.3
            }
        }
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Indeterminate Progress Bar

struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = -100
    @Environment(\.colorScheme) private var colorScheme

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(trackColor)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentPrimary)
                    .frame(width: geometry.size.width * 0.3, height: 4)
                    .offset(x: offset)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: false)
                        ) {
                            offset = geometry.size.width + 100
                        }
                    }
            }
        }
        .frame(height: 4)
    }
}

#if DEBUG
struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ProgressBar(progress: 0.33, isPulsing: false)
            ProgressBar(progress: 0.67, isPulsing: true)
            ProgressBar(progress: 1.0, isPulsing: false)
            IndeterminateProgressBar()
            ProgressBar(progress: 0.5, isPulsing: false)
                .preferredColorScheme(.dark)
        }
        .padding()
    }
}
#endif