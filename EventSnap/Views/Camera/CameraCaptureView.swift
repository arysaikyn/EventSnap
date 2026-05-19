import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

/// The HOME screen. Full-bleed camera viewfinder with viewfinder brackets,
/// scanning beam, reactive capture button, and alternate image sources.
/// Design v3: Illuminated Scanner — light-reactive surfaces, spatial depth.
struct CameraCaptureView: View {
    @Environment(CameraViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLongPressing = false
    @State private var multiPageCount = 0
    @State private var showPermissionDenied = false
    @State private var captureButtonScale: CGFloat = 1.0
    @State private var showCaptureFlash = false

    // MARK: - Alternate Image Source State

    @State private var showPhotoPicker = false
    @State private var hasClipboardImage = false

    /// Called when the user captures a photo and confirms they want to proceed.
    var onImageCaptured: ((UIImage) -> Void)?

    // Computed scan state colors
    private var bracketColor: Color {
        switch viewModel.scanReadiness {
        case .eventReady: return .scanSuccess
        case .textDetected, .needsMoreDetail, .processing: return .scanPartial
        case .noText, .looking, .idle: return .white.opacity(0.7)
        case .error(_): return .scanError
        }
    }

    private var isScanningActive: Bool {
        if case .error = viewModel.scanReadiness { return false }
        return !viewModel.isProcessing
    }

    var body: some View {
        ZStack {
            // ── Camera feed or permission denied ──
            if showPermissionDenied {
                ZStack {
                    EventMeshGradient.scannerBackground()
                    PermissionOverlay(
                        title: "Camera Access Needed",
                        message: "EventSnap needs camera access to scan event flyers, posters, and invitations.",
                        iconName: "camera.fill"
                    )
                }
                .ignoresSafeArea()
            } else {
                cameraPreviewLayer
                    .ignoresSafeArea()
            }

            // ── Bottom UI overlay ──
            VStack(spacing: 0) {
                if !showPermissionDenied {
                    topBar
                        .padding(.top, safeAreaTop)
                } else {
                    Spacer()
                }

                Spacer()

                if !showPermissionDenied {
                    scanningOverlay
                        .padding(.horizontal, EventSpacing.xxl)
                        .padding(.bottom, EventSpacing.lg)
                } else {
                    alternateSourceCallout
                        .padding(.horizontal, EventSpacing.pageMargin)
                        .padding(.bottom, EventSpacing.lg)
                }

                // Image source gallery
                ImageSourceGallery(
                    showPhotoPicker: $showPhotoPicker,
                    hasClipboardImage: hasClipboardImage,
                    onPasteImage: {
                        if let image = UIPasteboard.general.images?.first {
                            onImageCaptured?(validateAndPrepareImage(image))
                        }
                    }
                )
                .padding(.horizontal, EventSpacing.pageMargin)
                .padding(.bottom, EventSpacing.md)

                // Capture button
                if !showPermissionDenied {
                    captureButtonSection
                        .padding(.bottom, EventSpacing.xxl)
                } else {
                    Spacer().frame(height: EventSpacing.xxl)
                }
            }

            // ── Capture flash overlay ──
            if showCaptureFlash {
                Color.white
                    .opacity(0.8)
                    .transition(.opacity)
                    .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            checkAndRequestPermissions()
            viewModel.startLiveScanning()
            checkClipboardForImage()
        }
        .onDisappear {
            viewModel.stopLiveScanning()
            if !viewModel.isProcessing {
                viewModel.stopSession()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { checkClipboardForImage() }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(onImageSelected: { image in
                onImageCaptured?(validateAndPrepareImage(image))
            })
        }
        .onDrop(of: [.image], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: UIImage.self) { result, _ in
                guard let image = result as? UIImage else { return }
                Task { @MainActor in
                    onImageCaptured?(validateAndPrepareImage(image))
                }
            }
            return true
        }
        .animation(EventAnimation.default_, value: viewModel.isProcessing)
        .animation(EventAnimation.gentle, value: viewModel.scanReadiness)
        .overlay(alignment: .bottom) {
            // Minimal status pill — only show when camera is truly unavailable
            if case .error(let message) = viewModel.scanReadiness {
                statusPill(title: "Camera unavailable", message: message)
                    .padding(.bottom, EventSpacing.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(EventAnimation.gentle, value: showPermissionDenied)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: EventSpacing.sm) {
            Spacer()

            if viewModel.isProcessing || viewModel.scanReadiness == .eventReady {
                if multiPageCount > 1 {
                    Text("\(multiPageCount)")
                        .font(EventTypography.footnoteSemibold)
                        .foregroundStyle(.white)
                        .frame(minWidth: EventSpacing.touchTarget, minHeight: EventSpacing.touchTarget)
                        .background(Capsule().fill(Color.brandPrimary))
                        .padding(.trailing, EventSpacing.xs)
                        .transition(.scale.combined(with: .opacity))
                }

                Button {
                    EventHaptics.tap()
                    viewModel.toggleFlash()
                } label: {
                    Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                        .font(EventTypography.iconTitle)
                        .foregroundStyle(viewModel.isFlashOn ? Color.brandAccent : .white)
                        .frame(width: EventSpacing.touchTarget, height: EventSpacing.touchTarget)
                        .background(Circle().fill(.black.opacity(0.25)))
                        .overlay(
                            Circle().stroke(
                                viewModel.isFlashOn ? Color.brandAccent.opacity(0.4) : .white.opacity(0.15),
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
        .padding(.horizontal, EventSpacing.pageMargin)
        .padding(.vertical, EventSpacing.md)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.3), .black.opacity(0)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Camera Preview with Viewfinder Brackets

    private var cameraPreviewLayer: some View {
        CameraPreview(session: viewModel.captureSession)
            .overlay(
                viewModel.isProcessing ? Color.black.opacity(0.30) : Color.clear
            )
            // Viewfinder brackets
            .overlay {
                ViewfinderBrackets(
                    tintColor: bracketColor,
                    lineWidth: viewModel.scanReadiness == .eventReady ? 3.5 : 2.5,
                    cornerRadius: 10
                )
                .animation(EventAnimation.default_, value: viewModel.scanReadiness)
            }
            // Scanning beam
            .overlay {
                if isScanningActive {
                    ScanningBeam(isActive: true, beamColor: bracketColor)
                        .padding(EventSpacing.viewfinderInset + 4)
                }
            }
            // Ready glow pulse
            .overlay {
                if viewModel.scanReadiness == .eventReady {
                    RoundedRectangle(cornerRadius: EventRadius.xl, style: .continuous)
                        .stroke(bracketColor.opacity(0.5), lineWidth: 2)
                        .padding(EventSpacing.viewfinderInset - 4)
                        .transition(.opacity)
                }
            }
    }

    // MARK: - Status Pill (Error Only)

    private func statusPill(title: String, message: String) -> some View {
        HStack(spacing: EventSpacing.sm) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .shadow(color: .red.opacity(0.5), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(EventTypography.footnoteSemibold)
                    .foregroundStyle(.white)
                Text(message)
                    .font(EventTypography.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
        .padding(.horizontal, EventSpacing.md)
        .padding(.vertical, EventSpacing.sm)
        .background(
            Capsule()
                .fill(.black.opacity(0.6))
        )
        .padding(.horizontal, EventSpacing.pageMargin)
    }

    // MARK: - Scan Readiness Card

    private var scanReadinessCard: some View {
        HStack(spacing: EventSpacing.sm) {
            Circle()
                .fill(bracketColor)
                .frame(width: 10, height: 10)
                .shadow(color: bracketColor.opacity(0.7), radius: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.scanReadiness.message)
                    .font(EventTypography.subheadSemibold)
                    .foregroundStyle(.white)

                if let title = viewModel.detectedEventTitle, viewModel.scanReadiness == .eventReady {
                    Text(title)
                        .font(EventTypography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.85))
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
        .background {
            EventGlass.pill {
                Capsule().fill(.black.opacity(0.35))
            }
        }
        .overlay(
            Capsule()
                .stroke(bracketColor.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Scanning Overlay

    @ViewBuilder
    private var scanningOverlay: some View {
        if viewModel.isProcessing || !viewModel.extractedTextPreview.isEmpty {
            VStack(spacing: EventSpacing.lg) {
                // Scanning header
                HStack(spacing: EventSpacing.sm) {
                    Image(systemName: viewModel.scanReadiness == .eventReady ? "checkmark.circle.fill" : "viewfinder")
                        .font(EventTypography.subheadSemibold)
                        .foregroundStyle(bracketColor)
                    Text(viewModel.scanReadiness == .eventReady ? "Ready to review" : "Scanning...")
                        .font(EventTypography.subheadSemibold)
                        .foregroundStyle(colorScheme == .dark ? Color.textPrimaryDark : Color.textPrimary)
                }

                if viewModel.isProcessing {
                    shimmerProgressBar
                        .padding(.horizontal, EventSpacing.xs)
                }

                if !viewModel.extractedTextPreview.isEmpty {
                    VStack(spacing: EventSpacing.md) {
                        Text(viewModel.extractedTextPreview)
                            .font(EventTypography.callout)
                            .foregroundStyle(colorScheme == .dark ? Color.textSecondaryDark : Color.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

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
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .glassCard()
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Shimmer Progress Bar

    private var shimmerProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorScheme == .dark ? Color.surfaceSubtleDark.opacity(0.5) : Color.surfaceSubtle.opacity(0.5))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.brandPrimary.opacity(0.6), .brandPrimary, .brandPrimary.opacity(0.6)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .frame(width: geometry.size.width * 0.4)
                    .offset(x: shimmerOffset * geometry.size.width * 0.6)
                    .animation(EventAnimation.shimmer, value: shimmerOffset)
            }
        }
        .frame(height: 6)
        .onAppear { shimmerOffset = 1.0 }
    }

    @State private var shimmerOffset: CGFloat = -0.5

    // MARK: - Capture Button Section

    private var captureButtonSection: some View {
        CaptureButton(
            action: capturePhoto,
            isReady: viewModel.scanReadiness == .eventReady,
            isDisabled: viewModel.isProcessing,
            scale: captureButtonScale
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 60) { pressing in
            withAnimation(EventAnimation.snappy) {
                captureButtonScale = pressing ? 0.88 : 1.0
            }
        } perform: {
            EventHaptics.heavy()
            multiPageCount += 1
            capturePhoto()
        }
    }

    // MARK: - Alt Source Callout (Permission Denied)

    private var alternateSourceCallout: some View {
        VStack(spacing: EventSpacing.md) {
            VStack(spacing: EventSpacing.sm) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(EventTypography.sectionTitle)
                    .foregroundStyle(Color.brandAccent)

                Text("Import from another source")
                    .font(EventTypography.subheadSemibold)
                    .foregroundStyle(.white)

                Text("Choose an image from Photos, paste from clipboard, or drag & drop.")
                    .font(EventTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, EventSpacing.lg)
            .padding(.vertical, EventSpacing.md)
            .background(.ultraThinMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: EventRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: EventRadius.large)
                    .stroke(Color.brandAccent.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func capturePhoto() {
        // Flash animation
        withAnimation(.easeOut(duration: 0.15)) {
            showCaptureFlash = true
        }
        EventHaptics.captureSequence()

        Task {
            viewModel.clearScanResult()
            guard let image = await viewModel.capturePhoto() else { return }

            withAnimation(.easeOut(duration: 0.4)) {
                showCaptureFlash = false
            }
            onImageCaptured?(image)
        }
    }

    private func checkAndRequestPermissions() {
        let status = permissionManager.cameraStatus
        switch status {
        case .notDetermined:
            Task {
                let granted = await permissionManager.requestCameraAccess()
                if granted {
                    viewModel.startSession()
                } else {
                    await MainActor.run {
                        withAnimation(EventAnimation.gentle) { showPermissionDenied = true }
                    }
                }
            }
        case .authorized:
            viewModel.startSession()
        case .denied, .restricted:
            withAnimation(EventAnimation.gentle) { showPermissionDenied = true }
        @unknown default:
            showPermissionDenied = true
        }
    }

    private func checkClipboardForImage() {
        hasClipboardImage = UIPasteboard.general.hasImages
    }

    // MARK: - Image Validation

    private static let maxImagePixels: Int64 = 25 * 1024 * 1024

    private func validateAndPrepareImage(_ image: UIImage) -> UIImage {
        let pixelCount = Int64(image.size.width * image.size.height * image.scale * image.scale)
        guard pixelCount > Self.maxImagePixels else { return image }

        let scaleFactor = sqrt(Double(Self.maxImagePixels) / Double(pixelCount))
        let targetSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private var safeAreaTop: CGFloat {
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
            // Safe: layerClass override guarantees this type at runtime
            // swiftlint:disable:next force_cast
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
