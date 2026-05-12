import SwiftUI
import AVFoundation

/// The HOME screen. Full-bleed camera viewfinder with capture button,
/// on-device badge, flash toggle, and scanning overlay.
struct CameraCaptureView: View {
    @Environment(CameraViewModel.self) private var viewModel
    @Environment(PermissionManager.self) private var permissionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLongPressing = false
    @State private var multiPageCount = 0
    @State private var showPermissionDenied = false

    /// Called when the user captures a photo and confirms they want to proceed.
    var onImageCaptured: ((UIImage) -> Void)?

    var body: some View {
        ZStack {
            cameraPreviewLayer
                .ignoresSafeArea(edges: .top)

            // Capture overlay UI
            VStack {
                // Top bar
                HStack(alignment: .top) {
                    OnDeviceBadge()
                        .padding(.leading, 16)
                        .padding(.top, safeAreaTop)

                    Spacer()

                    if viewModel.isProcessing {
                        // Multi-page counter badge
                        if multiPageCount > 1 {
                            Text("\(multiPageCount)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .frame(height: 24)
                                .background(Capsule().fill(Color.accentPrimary))
                                .padding(.trailing, 8)
                        }

                        Button {
                            viewModel.toggleFlash()
                        } label: {
                            Image(systemName: viewModel.isFlashOn ? "bolt.circle.fill" : "bolt.slash.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, safeAreaTop)
                        .accessibilityLabel("Toggle flash")
                        .accessibilityHint(viewModel.isFlashOn ? "Flash is on" : "Flash is off")
                    }
                }

                Spacer()

                // Scanning overlay
                if viewModel.isProcessing {
                    scanningOverlay
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Capture button
                captureButton
                    .padding(.bottom, 40)
                    .padding(.horizontal, 16)
            }

            // Permission denied overlay
            if showPermissionDenied {
                PermissionOverlay(
                    title: "Camera Access Needed",
                    message: "EventSnap needs camera access to scan event flyers, posters, and invitations.",
                    iconName: "camera.fill"
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            checkAndRequestPermissions()
        }
        .onDisappear {
            if !viewModel.isProcessing {
                viewModel.stopSession()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isProcessing)
        .animation(.easeInOut(duration: 0.3), value: showPermissionDenied)
    }

    // MARK: - Camera Preview

    private var cameraPreviewLayer: some View {
        CameraPreview(session: viewModel.captureSession)
            .overlay(
                // Dim overlay when processing
                viewModel.isProcessing
                    ? Color.black.opacity(0.35)
                    : Color.clear
            )
    }

    // MARK: - Scanning Overlay

    private var scanningOverlay: some View {
        VStack(spacing: 12) {
            Text("Scanning...")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            IndeterminateProgressBar()
                .padding(.horizontal, 40)

            // OCR text preview
            if !viewModel.extractedTextPreview.isEmpty {
                Text(viewModel.extractedTextPreview)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Continue button to proceed to event preview
                Button {
                    if let image = viewModel.capturedImage {
                        onImageCaptured?(image)
                    }
                } label: {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.accentPrimary)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .accessibilityLabel("Continue to event preview")
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 32)
    }

    // MARK: - Capture Button

    private var captureButton: some View {
        Button {
            capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 69, height: 69)

                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 59, height: 59)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isProcessing)
        .opacity(viewModel.isProcessing ? 0.6 : 1.0)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    isLongPressing = true
                    multiPageCount += 1
                    capturePhoto()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLongPressing = false
                    }
                }
        )
        .accessibilityLabel("Capture event")
        .accessibilityHint("Double-tap to capture. Long-press for multi-page scanning.")
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - Actions

    private func capturePhoto() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            guard let image = await viewModel.capturePhoto() else { return }

            // OCR is triggered inside viewModel.capturePhoto() callback
            // Additional event creation flow handled by parent coordinator
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
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
                    withAnimation {
                        showPermissionDenied = true
                    }
                }
            case .authorized:
                viewModel.startSession()
            case .denied, .restricted:
                withAnimation {
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

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds

        view.layer.addSublayer(previewLayer)
        view.accessibilityLabel = "Camera viewfinder"

        // Store reference for updates
        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        weak var previewLayer: AVCaptureVideoPreviewLayer?
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