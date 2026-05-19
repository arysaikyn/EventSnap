import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// SwiftUI App entry point for the Share Extension.
/// Presented from iOS share sheet when user selects EventSnap.
@main
struct EventSnapShareExtensionApp: App {
    @StateObject private var viewModel = ShareExtensionViewModel()

    var body: some Scene {
        WindowGroup {
            ShareExtensionView(viewModel: viewModel)
                .environmentObject(viewModel)
        }
    }
}

/// Main Share Extension View — handles text and image sharing from other apps.
struct ShareExtensionView: View {
    @ObservedObject var viewModel: ShareExtensionViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with privacy badge
                topBar

                switch viewModel.state {
                case .loading:
                    loadingView

                case .parsing:
                    parsingView

                case .preview(let event):
                    EventPreviewView(event: event) {
                        viewModel.saveToCalendar(event: event)
                    }

                case .success(let history):
                    successView

                case .error(let message):
                    errorView(message: message)
                }
            }
        }
        .task {
            // Start processing shared items when view appears
            viewModel.loadSharedItems()
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.semanticSuccess)

            Text("On-device processing")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.semanticSuccess)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.semanticSuccess.opacity(0.1), in: Capsule())
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var loadingView: some View {
        VStack(spacing: EventSpacing.lg) {
            Spacer()

            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.brandPrimary)

            Text("Reading shared content…")
                .font(EventTypography.callout)
                .foregroundStyle(Color.textSecondary)

            Spacer()
        }
    }

    private var parsingView: some View {
        VStack(spacing: EventSpacing.lg) {
            Spacer()

            // Animated orb
            ZStack {
                Circle()
                    .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.brandPrimary, lineWidth: 2, lineCap: .round)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: true)
            }

            Text("Extracting event details…")
                .font(EventTypography.callout)
                .foregroundStyle(Color.textSecondary)

            Spacer()
        }
    }

    private var successView: some View {
        // Reuse main app's EventConfirmationView styling
        VStack(spacing: EventSpacing.xl) {
            Spacer()

            // Success ring
            ZStack {
                Circle()
                    .stroke(Color.semanticSuccess.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.semanticSuccess.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.semanticSuccess)
            }

            Text("Event added to calendar!")
                .font(EventTypography.subheadSemibold)
                .foregroundStyle(Color.textPrimary)

            Button("Done") {
                viewModel.closeExtension()
            }
            .buttonStyle(
                EnhancedPrimaryButtonStyle(icon: "checkmark")
            )
            .padding(.horizontal, EventSpacing.huge)

            Spacer()
        }
        .padding(.horizontal, EventSpacing.pageMargin)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: EventSpacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.semanticWarning)

            Text("Couldn't find event details")
                .font(EventTypography.subheadSemibold)
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(EventTypography.callout)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, EventSpacing.pageMargin)

            Button("Cancel") {
                viewModel.closeExtension()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, EventSpacing.huge)

            Spacer()
        }
        .padding(.horizontal, EventSpacing.pageMargin)
    }
}

#Preview {
    EventSnapShareExtensionApp()
}