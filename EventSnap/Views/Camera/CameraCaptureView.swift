import SwiftUI
import AVFoundation

/// The HOME screen. Full-bleed camera viewfinder with capture button,
/// on-device badge, flash toggle, and scanning overlay.
/// Premium design: typography-first, spring animations, glass materials.
struct CameraCaptureView: View {
    @Environment(CameraViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLongPressing = false
    @State private var multiPageCount = 0
    @State private var showPermissionDenied = false
    @State private var captureButtonScale: CGFloat = 1.0
    @State private var pulseReadinessRing = false

    /// Called when the user captures a photo and confirms they want to proceed.
    var onImageCaptured: ((UIImage) -> Void)?

    var body: some View {
        ZStack {
            // ── Full-bleed camera feed ──
            cameraPreviewLayer
                .ignoresSafeArea(edges: .top)

            // ── Capture overlay UI ──
            VStack(spacing: 0) {
                topBar
                    .padding(.top, safeAreaTop + EventSpacing.sm)

                Spacer()

                scanReadinessCard
                    .padding(.horizontal, EventSpacing.pageMargin)
                    .padding(.bottom, EventSpacing.md)

                scanningOverlay
                    .padding(.horizontal, EventSpacing.xl)
                    .padding(.bottom, EventSpacing.lg)

                captureButton
                    .padding(.bottom, EventSpacing.massive)
            }

            // ── Permission denied overlay ──
            if showPermissionDenied {
                PermissionOverlay(
                    title: "Camera Access Needed",
                    message: "EventSnap needs camera access to scan event flyers, posters, and invitations.",
                    iconName: "camera.fill"
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            checkAndRequestPermissions()
            viewModel.startLiveScanning()
            pulseReadinessRing = true
        }
        .onDisappear {
            viewModel.stopLiveScanning()
            if !viewModel.isProcessing {
                viewModel.stopSession()
            }
        }
        .animation(EventAnimation.default_, value: viewModel.isProcessing)
        .animation(EventAnimation.gentle, value: viewModel.scanReadiness)
        .animation(EventAnimation.gentle, value: showPermissionDenied)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: EventSpacing.sm) {
            OnDeviceBadge()

            Spacer()

            if viewModel.isProcessing || viewModel.scanReadiness == .eventReady {
                // Multi-page counter badge
                if multiPageCount > 1 {
                    Text("\(multiPageCount)")
                        .font(EventTypography.footnoteSemibold)
                        .foregroundStyle(.white)
                        .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
                        .background(
                            Capsule()
                                .fill(Color.brandPrimary)
                        )
                        .padding(.trailing, EventSpacing.xs)
                        .transition(.scale.combined(with: .opacity))
                }

                // Flash toggle
                Button {
                    EventHaptics.tap()
                    viewModel.toggleFlash()
                } label: {
                    Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                        .font(EventTypography.iconTitle)
                        .foregroundStyle(viewModel.isFlashOn ? Color.brandAccent : .white)
                        .frame(width: EventSpacing.touchTarget, height: EventSpacing.touchTarget)
                        .background(
                            Circle()
                                .fill(.black.opacity(0.25))
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    viewModel.isFlashOn
                                        ? Color.brandAccent.opacity(0.4)
                                        : .white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle flash")
                .accessibilityHint(viewModel.isFlashOn ? "Flash is on" : "Flash is off")
                .padding(.trailing, EventSpacing.pageMargin)
            }
        }
        .padding(.leading, EventSpacing.pageMargin)
    }

    // MARK: - Camera Preview

    private var cameraPreviewLayer: some View {
        CameraPreview(session: viewModel.captureSession)
            .overlay(
                viewModel.isProcessing
                    ? Color.black.opacity(0.30)
                    : Color.clear
            )
            .overlay(alignment: .center) {
                RoundedRectangle(cornerRadius: EventRadius.xl)
                    .stroke(
                        viewModel.scanReadiness.tintColor.opacity(pulseReadinessRing ? 0.95 : 0.45),
                        lineWidth: 3
                    )
                    .padding(EventSpacing.pageMargin)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseReadinessRing
                    )
            }
    }

    private var scanReadinessCard: some View {
        HStack(spacing: EventSpacing.sm) {
            Circle()
                .fill(viewModel.scanReadiness.tintColor)
                .frame(width: 10, height: 10)
                .shadow(color: viewModel.scanReadiness.tintColor.opacity(0.7), radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.scanReadiness.message)
                    .font(EventTypography.subheadSemibold)
                    .foregroundStyle(.white)

                if let title = viewModel.detectedEventTitle, viewModel.scanReadiness == .eventReady {
                    Text(title)
                        .font(EventTypography.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                } else if viewModel.scanReadiness == .needsMoreDetail {
                    Text("Make sure the event date, time, and title are visible.")
                        .font(EventTypography.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                } else {
                    Text("Live scan checks every second — nothing leaves your iPhone.")
                        .font(EventTypography.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, EventSpacing.md)
        .padding(.vertical, EventSpacing.sm)
        .background(.black.opacity(0.42), in: Capsule())
        .overlay(
            Capsule()
                .stroke(viewModel.scanReadiness.tintColor.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Scanning Overlay

    @ViewBuilder
    private var scanningOverlay: some View {
        if viewModel.isProcessing || !viewModel.extractedTextPreview.isEmpty {
            VStack(spacing: EventSpacing.lg) {
                // Scanning header
                HStack(spacing: EventSpacing.sm) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(viewModel.scanReadiness.tintColor)
                    Text(viewModel.scanReadiness == .eventReady ? "Ready to review" : "Scanning...")
                        .font(EventTypography.subheadSemibold)
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color.textPrimaryDark
                                : Color.textPrimary
                        )
                }

                if viewModel.isProcessing {
                    // Shimmer progress bar
                    shimmerProgressBar
                        .padding(.horizontal, EventSpacing.xs)
                }

                // OCR text preview
                if !viewModel.extractedTextPreview.isEmpty {
                    VStack(spacing: EventSpacing.md) {
                        Text(viewModel.extractedTextPreview)
                            .font(EventTypography.callout)
                            .foregroundStyle(
                                colorScheme == .dark
                                    ? Color.textSecondaryDark
                                    : Color.textSecondary
                            )
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        // Continue button
                        Button {
                            EventHaptics.press()
                            if let capturedImage = viewModel.capturedImage {
                                onImageCaptured?(capturedImage)
                            }
                        } label: {
                            Text(viewModel.scanReadiness == .eventReady ? "Review Event" : "Try This Scan")
                                .font(EventTypography.bodyMedium)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(maxWidth: 260)
                        .accessibilityLabel("Continue to event preview")
                    }
                    .transition(
                        .opacity.combined(with: .move(edge: .bottom))
                    )
                }
            }
            .padding(EventSpacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius))
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
            .transition(
                .opacity.combined(with: .scale(scale: 0.95))
            )
        }
    }

    // MARK: - Shimmer Progress Bar

    private var shimmerProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        colorScheme == .dark
                            ? Color.surfaceSubtleDark.opacity(0.5)
                            : Color.surfaceSubtle.opacity(0.5)
                    )
                    .frame(height: 6)

                // Animated shimmer fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary.opacity(0.6),
                                Color.brandPrimary,
                                Color.brandPrimary.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .frame(
                        width: geometry.size.width * 0.4
                    )
                    .offset(x: shimmerOffset * geometry.size.width * 0.6)
                    .animation(
                        Animation.linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            }
        }
        .frame(height: 6)
        .onAppear {
            shimmerOffset = 1.0
        }
    }

    @State private var shimmerOffset: CGFloat = -0.5

    // MARK: - Capture Button

    private var captureButton: some View {
        Button {
            capturePhoto()
        } label: {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 76, height: 76)

                // Inner solid ring
                Circle()
                    .fill(.white)
                    .frame(width: 66, height: 66)

                // Innermost accent dot
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.brandPrimary.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            }
            .scaleEffect(captureButtonScale)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing)
        .opacity(viewModel.isProcessing ? 0.55 : 1.0)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    EventHaptics.heavy()
                    isLongPressing = true
                    multiPageCount += 1
                    capturePhoto()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLongPressing = false
                    }
                }
        )
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 60
        ) {} onPressingChanged: { pressing in
            withAnimation(EventAnimation.snappy) {
                captureButtonScale = pressing ? 0.88 : 1.0
            }
        }
        .accessibilityLabel("Capture event")
        .accessibilityHint("Double-tap to capture. Long-press for multi-page scanning.")
    }

    // MARK: - Actions

    private func capturePhoto() {
        EventHaptics.press()

        Task {
            viewModel.clearScanResult()
            guard let image = await viewModel.capturePhoto() else { return }

            EventHaptics.success()
            onImageCaptured?(image)
        }
    }

    private func checkAndRequestPermissions() {
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .notDetermined:
                let granted = await permissionManager.requestCameraAccess()
                if granted {
                    viewModel.startSession()
                } else {
                    withAnimation(EventAnimation.gentle) {
                        showPermissionDenied = true
                    }
                }
            case .authorized:
                viewModel.startSession()
            case .denied, .restricted:
                withAnimation(EventAnimation.gentle) {
                    showPermissionDenied = true
                }
            @unknown default:
                showPermissionDenied = true
            }
        }
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

// MARK: - UIViewRepresentable Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.accessibilityLabel = "Camera viewfinder"
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

#if DEBUG
struct CameraCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        let ocrService = OCRService()
        let vm = CameraViewModel(ocrService: ocrService)
        let pm = PermissionManager()

        CameraCaptureView()
            .environment(vm)
            .environment(pm)
    }
}
#endif
