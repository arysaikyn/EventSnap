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
            color: Color.accentPrimary
        ),
        OnboardingPage(
            icon: "waveform",
            title: "Speak Freely.",
            subtitle: "Just say what you need. We'll handle the rest.",
            color: Color.accentTeal
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Your Privacy.",
            subtitle: "Everything stays on your device. Nothing leaves.",
            color: Color.privacyGreen
        )
    ]

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.body.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 24)
                        .padding(.top, safeAreaTop + 8)
                        .frame(minWidth: 44, minHeight: 44)
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
                .animation(.easeInOut, value: currentPage)

                // Bottom section: dots + button
                VStack(spacing: 24) {
                    // Page indicator dots
                    HStack(spacing: 10) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? pages[index].color : Color.secondary.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(pages[currentPage].color)
                            )
                            .padding(.horizontal, 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(currentPage < pages.count - 1 ? "Next page" : "Get started with EventSnap")
                    .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Background

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }

    // MARK: - Page Content

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundColor(page.color)
            }
            .padding(.bottom, 8)

            // Title
            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
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