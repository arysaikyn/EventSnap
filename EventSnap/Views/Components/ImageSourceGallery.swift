import SwiftUI

/// Alternate image source buttons (Photos, Paste, Drop hint) for the camera tab.
///
/// Arranged as a horizontal row of premium glass pill buttons, each with icon + short label.
/// All state comes from the parent via bindings/callbacks — this is pure UI.
///
/// - Parameters:
///   - showPhotoPicker: Binding that triggers a PHPicker when set to `true`.
///   - hasClipboardImage: Whether the clipboard currently contains an image.
///   - onPasteImage: Closure called when the user taps the paste button.
///
/// The drop button is informational only; drop handling lives on the parent via `.onDrop`.
struct ImageSourceGallery: View {
    @Binding var showPhotoPicker: Bool
    let hasClipboardImage: Bool
    let onPasteImage: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: EventSpacing.sm) {
            // ── Section label ──
            Text("Alternate Sources")
                .font(EventTypography.captionMedium)
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: EventSpacing.md) {
                // ── Photos button ──
                Button {
                    EventHaptics.tap()
                    showPhotoPicker = true
                } label: {
                    VStack(spacing: EventSpacing.xs) {
                        Image(systemName: "photo.on.rectangle")
                            .font(EventTypography.iconTitle)
                            .foregroundStyle(Color.brandAccent)

                        Text("Photos")
                            .font(EventTypography.captionMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: EventSpacing.galleryButtonHeight)
                    .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: EventRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: EventRadius.large)
                            .stroke(Color.brandAccent.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(SourcePillStyle())
                .accessibilityLabel("Pick from Photos")
                .accessibilityHint("Opens your photo library")

                // ── Paste button (only when clipboard has an image) ──
                if hasClipboardImage {
                    Button {
                        EventHaptics.tap()
                        onPasteImage()
                    } label: {
                        VStack(spacing: EventSpacing.xs) {
                            Image(systemName: "doc.on.clipboard")
                                .font(EventTypography.iconTitle)
                                .foregroundStyle(Color.brandPrimary)

                            Text("Paste")
                                .font(EventTypography.captionMedium)

                            // Brand-primary dot indicating clipboard has content
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 6, height: 6)
                                .offset(y: -2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: EventSpacing.galleryButtonHeight)
                        .background(.ultraThinMaterial.opacity(0.4), in: RoundedRectangle(cornerRadius: EventRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: EventRadius.large)
                                .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(SourcePillStyle())
                    .accessibilityLabel("Paste image")
                    .accessibilityHint("Pastes image from clipboard")
                }

                // ── Drop hint (informational only) ──
                Button {
                    EventHaptics.tap()
                    // No action — drop handling is on the parent via .onDrop
                } label: {
                    VStack(spacing: EventSpacing.xs) {
                        Image(systemName: "arrow.down.circle")
                            .font(EventTypography.iconTitle)
                            .foregroundStyle(.white.opacity(0.5))

                        Text("Drop")
                            .font(EventTypography.captionMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: EventSpacing.galleryButtonHeight)
                    .background(.ultraThinMaterial.opacity(0.2), in: RoundedRectangle(cornerRadius: EventRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: EventRadius.large)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(SourcePillStyle())
                .accessibilityLabel("Drag and drop supported")
                .accessibilityHint("Drop an image onto the camera view to scan it")
            }

            // ── Caption ──
            Text("Pick from Photos, paste, or drop an image")
                .font(EventTypography.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Source Pill Style

/// Press-scale button style for image source pill buttons.
/// Scales down slightly on press with a snappy spring animation.
private struct SourcePillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(EventAnimation.snappy, value: configuration.isPressed)
    }
}

// MARK: - Previews

#if DEBUG
struct ImageSourceGallery_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: EventSpacing.xxl) {
                // State: clipboard has an image
                ImageSourceGallery(
                    showPhotoPicker: .constant(false),
                    hasClipboardImage: true,
                    onPasteImage: {}
                )

                Divider()
                    .background(Color.white.opacity(0.2))

                // State: clipboard has NO image (paste button hidden)
                ImageSourceGallery(
                    showPhotoPicker: .constant(false),
                    hasClipboardImage: false,
                    onPasteImage: {}
                )
            }
            .padding(.horizontal, EventSpacing.pageMargin)
        }
        .preferredColorScheme(.dark)
    }
}
#endif