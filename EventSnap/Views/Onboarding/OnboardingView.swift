import SwiftUI

/// 3-card onboarding shown on first launch. Appears only once via `hasCompletedOnboarding` flag.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "Snap. Done.",
            subtitle: "Point your camera at any flyer, invitation, or screenshot.",
            color: Color.brandPrimary
        ),
        OnboardingPage(
            icon: "waveform",
            title: "Speak Freely.",
            subtitle: "Just say what you need. We'll handle the rest.",
            color: Color.brandSecondary
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Your Privacy.",
            subtitle: "Everything stays on your device. Nothing leaves.",
            color: Color.semanticSuccess
        )
    ]

    var body: some View {
        ZStack {
            EventMeshGradient.heroBackground()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            completeOnboarding()
                        }
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.textSecondary)
                        .padding(.trailing, EventSpacing.pageMargin)
                        .padding(.top, EventSpacing.lg)
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        PageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom section: dots + button
                VStack(spacing: EventSpacing.xxl) {
                    // Page indicator dots (dimeApp pattern: simple circles, no width animation)
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(pageDotColor(index))
                                .frame(width: dotWidth(index), height: dotWidth(index))
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: EventSpacing.buttonHeight)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: EventRadius.medium)
                                .fill(currentPage == pages.count - 1 ? Color.semanticSuccess : Color.brandPrimary)
                        )
                        .scaleEffect(0.97)
                    }
                    .padding(.horizontal, EventSpacing.pageMargin)
                }
                .padding(.bottom, EventSpacing.huge)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Dots

    private func pageDotColor(_ index: Int) -> Color {
        if currentPage == index {
            return Color.brandPrimary
        }
        return colorScheme == .dark ? Color.textQuaternaryDark : Color.textQuaternary
    }

    private func dotWidth(_ index: Int) -> CGFloat {
        currentPage == index ? 10 : 8
    }

    // MARK: - Actions

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - PageView

private struct PageView: View {
    let page: OnboardingPage
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var iconScale: CGFloat = 0.8

    var body: some View {
        EventGlass.card {
            VStack(spacing: EventSpacing.huge) {
                Spacer()

                // Icon with animated circle + pulse
                ZStack {
                    // Pulsing outer ring
                    Circle()
                        .stroke(page.color.opacity(0.15), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(appeared ? 1.0 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 1.2, dampingFraction: 0.5).delay(0.2), value: appeared)

                    // Circle fill
                    Circle()
                        .fill(page.color.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(iconScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: iconScale)

                    // Icon
                    Image(systemName: page.icon)
                        .font(.system(.title, design: .rounded).weight(.medium))
                        .foregroundStyle(page.color)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15), value: appeared)
                }
                .padding(.bottom, EventSpacing.sm)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        appeared = true
                        iconScale = 1.0
                    }
                    // Subtle idle pulse
                    withAnimation(
                        .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(1.0)
                    ) {
                        iconScale = 1.05
                    }
                }
                .onDisappear {
                    appeared = false
                    iconScale = 0.8
                }

                Text(page.title)
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .foregroundStyle(surface.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: appeared)

                Text(page.subtitle)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(surface.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EventSpacing.huge)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.35), value: appeared)

                Spacer()
                Spacer()
            }
        }
        .padding(.horizontal, EventSpacing.pageMargin)
    }

    private var surface: AdaptiveSurface {
        AdaptiveSurface(scheme: colorScheme)
    }
}

// MARK: - Page Model

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}
#endif
