import SwiftUI
import PhotosUI

// MARK: - PhotoPickerView

/// A SwiftUI wrapper around `PHPickerViewController` from the PhotosUI framework.
///
/// This picker presents the system photo picker configured for **single image selection only**
/// (no videos, no Live Photos). Because `PHPickerViewController` operates without requesting
/// `PHPhotoLibrary` authorization, no permission prompt is required — Apple handles this
/// transparently.
///
/// ## Usage
/// ```swift
/// struct ContentView: View {
///     @State private var showPicker = false
///     @State private var selectedImage: UIImage?
///
///     var body: some View {
///         Button("Pick Photo") { showPicker = true }
///             .sheet(isPresented: $showPicker) {
///                 PhotoPickerView { image in
///                     selectedImage = image
///                     showPicker = false
///                 }
///             }
///     }
/// }
/// ```
struct PhotoPickerView: UIViewControllerRepresentable {

    // MARK: - Configuration

    /// Called on the main actor when the user successfully selects and loads an image.
    let onImageSelected: (UIImage) -> Void

    /// Called when the user dismisses the picker without selecting anything.
    var onCancel: (() -> Void)?

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images             // Still images only — no videos or Live Photos
        config.selectionLimit = 1           // Single selection
        config.preferredAssetRepresentationMode = .automatic

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No-op: configuration is static after initialisation.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onCancel: onCancel)
    }

    // MARK: - Coordinator

    /// Acts as the `PHPickerViewControllerDelegate` and manages image loading via `PHImageManager`.
    @MainActor
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        private let onImageSelected: (UIImage) -> Void
        private let onCancel: (() -> Void)?

        init(onImageSelected: @escaping (UIImage) -> Void, onCancel: (() -> Void)?) {
            self.onImageSelected = onImageSelected
            self.onCancel = onCancel
        }

        // MARK: - PHPickerViewControllerDelegate

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // User cancelled (empty results or tapped "Cancel")
            guard let result = results.first else {
                onCancel?()
                picker.dismiss(animated: true)
                return
            }

            // Provide haptic feedback for the selection
            EventHaptics.tap()

            loadImage(from: result) { [weak self] image in
                guard let self else { return }

                if let image {
                    self.onImageSelected(image)
                } else {
                    // Image failed to load — treat as cancellation
                    self.onCancel?()
                }

                picker.dismiss(animated: true)
            }
        }

        // MARK: - Image Loading

        /// Loads a `UIImage` from a `PHPickerResult`.
        ///
        /// Uses `PHImageManager` when the result has an associated `PHAsset` (higher quality,
        /// respects iCloud), falling back to the `NSItemProvider`-based `UIImage` load otherwise.
        ///
        /// - Parameters:
        ///   - result: The picker result to load the image from.
        ///   - completion: Called on the main actor with the loaded image, or `nil` on failure.
        private func loadImage(from result: PHPickerResult, completion: @escaping @MainActor (UIImage?) -> Void) {
            // ── Prefer PHAsset path: higher quality, iCloud-aware ──
            if let asset = result.assetIdentifier.flatMap({ PHAsset.fetchAssets(withLocalIdentifiers: [$0], options: nil).firstObject }) {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true       // Allow iCloud downloads
                options.resizeMode = .none                  // Full resolution

                let targetSize = PHImageManagerMaximumSize

                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    // Check for cancellation or error
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let error = info?[PHImageErrorKey] as? Error

                    if isCancelled || error != nil {
                        Task { @MainActor in
                            completion(nil)
                        }
                        return
                    }

                    Task { @MainActor in
                        completion(image)
                    }
                }
                return
            }

            // ── Fallback: NSItemProvider path ──
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                Task { @MainActor in
                    completion(nil)
                }
                return
            }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard self != nil else { return }

                let image = object as? UIImage

                if error != nil {
                    Task { @MainActor in
                        completion(nil)
                    }
                    return
                }

                Task { @MainActor in
                    completion(image)
                }
            }
        }
    }
}