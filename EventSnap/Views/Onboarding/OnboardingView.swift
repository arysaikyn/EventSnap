import SwiftUI

/// 3-card onboarding shown on first launch. Appears only once via `hasCompletedOnboarding` flag.
/// Premium design with brandPrimary, brandSecondary, semanticSuccess page colors, spring animations,
/// capsule-shaped page indicators, and primary/ghost button styles from the design system.
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme

    private var surface: AdaptiveSurface {
        AdaptiveSurface(scheme: colorScheme)
    }

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
            surface.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            EventHaptics.tap()
                            completeOnboarding()
                        }
                        .buttonStyle(GhostButtonStyle())
                        .padding(.trailing, EventSpacing.pageMargin)
                        .padding(.top, safeAreaTop + EventSpacing.sm)
                        .accessibilityLabel("Skip onboarding")
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(EventAnimation.gentle, value: currentPage)

                // Bottom section: dots + button
                VStack(spacing: EventSpacing.xxl) {
                    // Page indicator dots — animated capsule that expands when active
                    HStack(spacing: EventSpacing.sm) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? pages[index].color : (colorScheme == .dark ? Color.textQuaternaryDark : Color.textQuaternary))
                                .frame(
                                    width: currentPage == index ? 28 : 8,
                                    height: 8
                                )
                                .animation(EventAnimation.bouncy, value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        EventHaptics.press()
                        if currentPage < pages.count - 1 {
                            withAnimation(EventAnimation.gentle) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .accessibilityLabel(currentPage < pages.count - 1 ? "Next page" : "Get started with EventSnap")
                }
                .padding(.bottom, EventSpacing.huge)
            }
        }
    }

    // MARK: - Page Content

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: EventSpacing.huge) {
            Spacer()

            // Icon in subtle circle
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundColor(page.color)
            }
            .padding(.bottom, EventSpacing.sm)

            // Title
            Text(page.title)
                .font(EventTypography.pageTitle)
                .foregroundColor(surface.textPrimary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(EventTypography.callout)
                .foregroundColor(surface.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, EventSpacing.huge)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        EventHaptics.success()
    }

    private var safeAreaTop: CGFloat {
        // NOTE: Using UIApplication.shared.connectedScenes here is a known approach.
        // This should be replaced with safeAreaInset or GeometryReader in a future refactor
        // for better SwiftUI integration, but it works correctly for now.
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 44
    }
}

// MARK: - Onboarding Page Model

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