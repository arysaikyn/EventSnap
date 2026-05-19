import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - EventSnap Design System v3 — "Illuminated Scanner"
//
// Aesthetic: Light-reactive surfaces, spatial depth, confident typography.
// The camera is a window illuminating events hidden in noise.
// Every interaction responds to light and depth.
//
// Brand palette: Terracotta (#E85D3A) + Teal (#3A8F8F) + Amber (#F5A623)

// ─── BRAND COLORS ────────────────────────────────────────────────────────
// Defined in Color+Hex.swift. Extended here with semantic tints and glows.

extension Color {
    // ── Glow / Scan States ──
    /// Scanning state — cool blue-gray, calm and focused
    static let scanNeutral  = Color(red: 0.40, green: 0.50, blue: 0.60)    // #668099
    /// Partial text — warm amber, "getting there"
    static let scanPartial  = Color(red: 0.96, green: 0.65, blue: 0.14)    // #F5A623
    /// Event found — success green, celebration-ready
    static let scanSuccess  = Color(red: 0.20, green: 0.78, blue: 0.50)    // #33C780
    /// Error state — clear red
    static let scanError    = Color(red: 0.85, green: 0.19, blue: 0.15)    // #D93025

    // ── Semantic ──
    static let semanticSuccess = Color(red: 0.18, green: 0.71, blue: 0.36)
    static let semanticWarning = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let semanticError   = Color(red: 0.85, green: 0.19, blue: 0.15)

    // ── Glow Variants (used for scan brackets, focus rings) ──
    static let glowTerracotta = Color.brandPrimary.opacity(0.4)
    static let glowTeal       = Color.brandSecondary.opacity(0.4)
    static let glowAmber      = Color.brandAccent.opacity(0.4)
    static let glowGreen      = scanSuccess.opacity(0.4)
}

#if canImport(UIKit)
extension UIColor {
    static let scanNeutral  = UIColor(red: 0.40, green: 0.50, blue: 0.60, alpha: 1.0)
    static let scanPartial  = UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0)
    static let scanSuccess  = UIColor(red: 0.20, green: 0.78, blue: 0.50, alpha: 1.0)
    static let scanError    = UIColor(red: 0.85, green: 0.19, blue: 0.15, alpha: 1.0)
    static let semanticSuccess = UIColor(red: 0.18, green: 0.71, blue: 0.36, alpha: 1.0)
    static let semanticWarning = UIColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0)
    static let semanticError   = UIColor(red: 0.85, green: 0.19, blue: 0.15, alpha: 1.0)
}
#endif

// ─── SURFACE LAYERS (Light) ────────────────────────────────────────────
// 4-layer depth: background → elevated → subtle → overlay

extension Color {
    static let surfaceBackground = Color(red: 0.96, green: 0.96, blue: 0.97)  // #F5F5F7
    static let surfaceBase       = Color(red: 0.97, green: 0.97, blue: 0.97)   // #F7F7F8
    static let surfaceRaised     = Color.white
    static let surfaceSubtle     = Color(red: 0.94, green: 0.94, blue: 0.94)   // #EFEFF0
    static let surfaceDim        = Color(red: 0.90, green: 0.90, blue: 0.91)   // #E5E5E7
    static let surfaceOverlay    = Color.black.opacity(0.4)
}

// ─── SURFACE LAYERS (Dark) ─────────────────────────────────────────────

extension Color {
    static let surfaceBackgroundDark = Color(red: 0.06, green: 0.06, blue: 0.07) // #0F0F11
    static let surfaceBaseDark       = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
    static let surfaceRaisedDark     = Color(red: 0.15, green: 0.15, blue: 0.16) // #262628
    static let surfaceSubtleDark     = Color(red: 0.20, green: 0.20, blue: 0.21) // #333336
    static let surfaceDimDark        = Color(red: 0.28, green: 0.28, blue: 0.29) // #48484A
    static let surfaceOverlayDark    = Color.black.opacity(0.6)
}

// ─── TEXT HIERARCHY ─────────────────────────────────────────────────────

extension Color {
    static let textPrimary    = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let textSecondary  = Color(red: 0.43, green: 0.43, blue: 0.45)
    static let textTertiary   = Color(red: 0.68, green: 0.68, blue: 0.70)
    static let textQuaternary = Color(red: 0.78, green: 0.78, blue: 0.80)
}

extension Color {
    static let textPrimaryDark    = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let textSecondaryDark  = Color(red: 0.60, green: 0.60, blue: 0.62)
    static let textTertiaryDark   = Color(red: 0.39, green: 0.39, blue: 0.40)
    static let textQuaternaryDark = Color(red: 0.28, green: 0.28, blue: 0.29)
}

// ─── BORDERS & DIVIDERS ─────────────────────────────────────────────────

extension Color {
    static let borderSubtle     = Color(red: 0.90, green: 0.90, blue: 0.91)
    static let borderStrong     = Color(red: 0.78, green: 0.78, blue: 0.80)
    static let borderSubtleDark = Color(red: 0.22, green: 0.22, blue: 0.23)
    static let borderStrongDark = Color(red: 0.28, green: 0.28, blue: 0.29)
    static let divider          = Color(red: 0.88, green: 0.88, blue: 0.89)
    static let dividerDark      = Color(red: 0.22, green: 0.22, blue: 0.23)
}

// ─── TYPOGRAPHY ─────────────────────────────────────────────────────────

enum EventTypography {
    // ── Display / Hero (large, impactful) ──
    static let displayLarge   = Font.system(size: 40, weight: .bold, design: .default)
    static let displayMedium  = Font.system(size: 34, weight: .bold, design: .default)
    static let displaySmall   = Font.system(size: 28, weight: .bold, design: .default)

    // ── Section / Header ──
    static let sectionTitle   = Font.system(size: 22, weight: .semibold)
    static let sectionLabel   = Font.system(size: 20, weight: .medium)
    static let pageTitle      = Font.system(size: 28, weight: .bold)

    // ── Content ──
    static let headline       = Font.system(size: 17, weight: .semibold)
    static let body           = Font.system(size: 17, weight: .regular)
    static let bodyMedium     = Font.system(size: 17, weight: .medium)
    static let callout        = Font.system(size: 16, weight: .regular)
    static let calloutMedium  = Font.system(size: 16, weight: .medium)

    // ── Support ──
    static let subheadline     = Font.system(size: 15, weight: .regular)
    static let subheadMedium   = Font.system(size: 15, weight: .medium)
    static let subheadSemibold = Font.system(size: 15, weight: .semibold)
    static let footnote        = Font.system(size: 13, weight: .regular)
    static let footnoteSemibold = Font.system(size: 13, weight: .semibold)
    static let caption         = Font.system(size: 12, weight: .regular)
    static let captionMedium   = Font.system(size: 12, weight: .medium)
    static let caption2        = Font.system(size: 11, weight: .regular)

    // ── Special ──
    static let bigNumber    = Font.system(size: 34, weight: .bold, design: .rounded)
    static let iconTitle    = Font.system(size: 20, weight: .medium)
    static let waveformIcon = Font.system(size: 44, weight: .medium)
    static let stopIcon     = Font.system(size: 20, weight: .bold)
    static let timerNumber  = Font.system(size: 52, weight: .semibold, design: .rounded)
    static let eventTitle   = Font.system(size: 24, weight: .bold) // Event preview header

    // ── Icons (SF Symbol sizing, not text) ──
    static let heroIcon     = Font.system(size: 40, design: .rounded)
    static let errorIcon    = Font.system(size: 64, weight: .regular)
    static let tabBarIcon   = Font.system(size: 28, weight: .medium)
    static let settingsIcon = Font.system(size: 34, weight: .medium)
    static let placeholderIcon = Font.system(size: 28, weight: .light)
}

// ─── SPACING (8-pt grid) ────────────────────────────────────────────────

enum EventSpacing {
    static let xs: CGFloat   = 4
    static let tight: CGFloat = 5
    static let sm: CGFloat   = 8
    static let ten: CGFloat  = 10
    static let md: CGFloat   = 12
    static let lg: CGFloat   = 16
    static let xl: CGFloat   = 20
    static let xxl: CGFloat  = 24
    static let huge: CGFloat = 32
    static let massive: CGFloat = 48

    // Component-specific
    static let cardPadding: CGFloat       = 20
    static let cardCornerRadius: CGFloat  = 16  // Slightly more generous
    static let buttonHeight: CGFloat      = 52
    static let smallButtonHeight: CGFloat = 44
    static let inputHeight: CGFloat       = 48
    static let touchTarget: CGFloat       = 44
    static let pageMargin: CGFloat        = 20

    /// Viewfinder inset from screen edges
    static let viewfinderInset: CGFloat = 32
    /// Viewfinder corner bracket length
    static let bracketLength: CGFloat   = 28
    /// Capture button outer ring diameter
    static let captureButtonOuter: CGFloat = 76
    /// Capture button inner diameter
    static let captureButtonInner: CGFloat = 64

    /// Bottom safe area padding for voice/recordings
    static let bottomSafe: CGFloat = 50

    /// Gallery button (Photos/Paste/Drop) pill height
    static let galleryButtonHeight: CGFloat = 72

    /// Input selector pill height
    static let inputSelectorHeight: CGFloat = 36

    /// Content padding below scroll content for floating button area
    static let floatingButtonPadding: CGFloat = 80

    /// Content padding for TextInput floating button area
    static let textInputFloatingPadding: CGFloat = 100

    /// Tab bar horizontal padding
    static let tabBarPadding: CGFloat = 15
}

// ─── CORNER RADIUS ──────────────────────────────────────────────────────

enum EventRadius {
    static let small: CGFloat  = 8
    static let medium: CGFloat = 12
    static let large: CGFloat  = 16
    static let xl: CGFloat     = 20
    static let pill: CGFloat   = 999
}

// ─── ANIMATIONS ─────────────────────────────────────────────────────────

enum EventAnimation {
    // Springs
    static let quick      = Animation.spring(response: 0.25, dampingFraction: 0.85)
    static let default_   = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let gentle     = Animation.spring(response: 0.45, dampingFraction: 0.65)
    static let bouncy     = Animation.spring(response: 0.40, dampingFraction: 0.55)
    static let snappy     = Animation.spring(response: 0.20, dampingFraction: 0.90)
    static let tabSwitch  = Animation.spring(response: 0.40, dampingFraction: 0.70)
    static let sheetSlide = Animation.spring(response: 0.5, dampingFraction: 0.75)

    // Repeating
    static var pulse: Animation {
        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
    static var slowPulse: Animation {
        Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
    }
    static var shimmer: Animation {
        Animation.linear(duration: 1.2).repeatForever(autoreverses: false)
    }
    static var idleWaveform: Animation {
        Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
    }
    static var countdown: Animation {
        Animation.linear(duration: 1.0)
    }
    /// Scanning beam sweep (3 seconds per pass)
    static var scanBeam: Animation {
        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }
    /// Breathing orb (slow, meditative)
    static var breathe: Animation {
        Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    }

    // Timing
    static let fadeInDuration: Double  = 0.25
    static let fadeOutDuration: Double = 0.20
    static let staggerDelay: Double    = 0.08
}

// ─── HAPTICS ────────────────────────────────────────────────────────────

enum EventHaptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func press() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    /// Orchestrated capture sequence: soft tap + medium impact + success
    static func captureSequence() {
        soft()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { press() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { success() }
    }
}

// ─── GRADIENT PRESETS ───────────────────────────────────────────────────

enum EventGradient {
    // Linear gradients for backgrounds
    static let hero = LinearGradient(
        colors: [
            Color.brandPrimary.opacity(0.15),
            Color.brandAccent.opacity(0.08),
            Color.brandSecondary.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cameraOverlay = LinearGradient(
        colors: [
            .black.opacity(0.55),
            .black.opacity(0.15),
            .black.opacity(0.0),
            .black.opacity(0.0),
            .black.opacity(0.55)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let scanBeam = LinearGradient(
        colors: [
            Color.brandPrimary.opacity(0.0),
            Color.brandPrimary.opacity(0.6),
            Color.brandPrimary.opacity(0.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let terracottaGlow = AngularGradient(
        colors: [
            Color.brandPrimary,
            Color.brandAccent,
            Color.brandSecondary,
            Color.brandPrimary
        ],
        center: .center
    )

    // ── Voice Experience ──
    /// Waveform bar gradient — terracotta to teal
    static let voiceWaveform = LinearGradient(
        colors: [.brandPrimary, Color(red: 0.62, green: 0.45, blue: 0.35), .brandSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
    /// Idle waveform — muted terracotta
    static let voiceIdle = LinearGradient(
        colors: [.brandPrimary.opacity(0.5), .brandPrimary.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )
    /// Orb gradient — warm, breathing
    static let orbGradient = RadialGradient(
        colors: [
            .brandPrimary.opacity(0.3),
            .brandPrimary.opacity(0.1),
            .clear
        ],
        center: .center,
        startRadius: 20,
        endRadius: 140
    )
    /// Ring tint for idle state
    static let ringIdle = Color.brandPrimary.opacity(0.15)
    /// Ring tint for recording state
    static let ringActive = Color.brandPrimary.opacity(0.35)
    /// Background gradient for voice view
    static let voiceBackground = RadialGradient(
        colors: [
            Color.brandPrimary.opacity(0.04),
            .clear
        ],
        center: .top,
        startRadius: 0,
        endRadius: 300
    )

    /// Confetti particle colors — brand-consistent only
    static let confettiColors: [Color] = [
        .brandPrimary, .brandSecondary, .brandAccent,
        .semanticSuccess, .white
    ]
}

// ─── BUTTON STYLES ──────────────────────────────────────────────────────

/// Primary CTA — solid brand fill with press animation
struct PrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EventTypography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: EventSpacing.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: EventRadius.medium)
                    .fill(isDisabled ? Color.textTertiary : Color.brandPrimary)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(EventAnimation.quick, value: configuration.isPressed)
    }
}

/// Enhanced primary with loading state and optional icon
struct EnhancedPrimaryButtonStyle: ButtonStyle {
    let isLoading: Bool
    let icon: String?
    let isDisabled: Bool

    init(isLoading: Bool = false, icon: String? = nil, isDisabled: Bool = false) {
        self.isLoading = isLoading
        self.icon = icon
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: EventSpacing.sm) {
            if isLoading {
                ProgressView().tint(.white).scaleEffect(0.8)
            } else if let icon {
                Image(systemName: icon)
                    .font(EventTypography.subheadMedium)
            }
            configuration.label
        }
        .font(EventTypography.bodyMedium)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: EventSpacing.buttonHeight)
        .background(
            RoundedRectangle(cornerRadius: EventRadius.medium)
                .fill(isDisabled || isLoading ? Color.textTertiary : Color.brandPrimary)
        )
        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
        .animation(EventAnimation.quick, value: configuration.isPressed)
    }
}

/// Secondary CTA — outlined
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EventTypography.bodyMedium)
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: EventSpacing.smallButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: EventRadius.medium)
                    .stroke(Color.brandPrimary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(EventAnimation.quick, value: configuration.isPressed)
    }
}

/// Ghost — minimal text button
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EventTypography.bodyMedium)
            .foregroundStyle(Color.textSecondary)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(EventAnimation.quick, value: configuration.isPressed)
    }
}

/// Icon button — circular with translucent background
struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let isActive: Bool

    init(size: CGFloat = EventSpacing.touchTarget, isActive: Bool = false) {
        self.size = size
        self.isActive = isActive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EventTypography.iconTitle)
            .foregroundStyle(isActive ? Color.brandAccent : .white)
            .frame(width: size, height: size)
            .background(Circle().fill(.black.opacity(0.25)))
            .overlay(
                Circle().stroke(
                    isActive ? Color.brandAccent.opacity(0.4) : .white.opacity(0.15),
                    lineWidth: 1
                )
            )
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(EventAnimation.snappy, value: configuration.isPressed)
    }
}

// ─── CARD / GLASS MODIFIERS ─────────────────────────────────────────────

/// Elevated card surface with shadow
struct EventCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(EventSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                    .fill(colorScheme == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised)
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                radius: 8, x: 0, y: 4
            )
    }
}

/// Glass card — frosted translucent surface
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EventSpacing.cardPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

/// Input field — minimal with subtle focus ring
struct EventInputModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let isFocused: Bool

    init(isFocused: Bool = false) { self.isFocused = isFocused }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, EventSpacing.md)
            .padding(.vertical, EventSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: EventRadius.medium)
                    .fill(colorScheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: EventRadius.medium)
                    .stroke(isFocused ? Color.brandPrimary.opacity(0.6) : Color.clear, lineWidth: 2)
            )
            .animation(EventAnimation.quick, value: isFocused)
    }
}

/// Glass surface with optional accent glow (for scan-ready states)
struct GlassGlowModifier: ViewModifier {
    let glowColor: Color
    let glowOpacity: CGFloat

    init(color: Color = Color.brandPrimary, opacity: CGFloat = 0.3) {
        self.glowColor = color
        self.glowOpacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .padding(EventSpacing.cardPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                    .stroke(glowColor.opacity(glowOpacity), lineWidth: 1.5)
            )
    }
}

// ─── VIEW EXTENSIONS ────────────────────────────────────────────────────

extension View {
    func eventCard() -> some View { modifier(EventCardModifier()) }
    func glassCard() -> some View { modifier(GlassCardModifier()) }
    func glassGlow(color: Color = .brandPrimary, opacity: CGFloat = 0.3) -> some View {
        modifier(GlassGlowModifier(color: color, opacity: opacity))
    }
    func eventInput(isFocused: Bool = false) -> some View {
        modifier(EventInputModifier(isFocused: isFocused))
    }

    /// Stagger reveal animation for sequential appearance
    func staggerReveal(delay: Int = 0, trigger: Bool = true) -> some View {
        self
            .opacity(trigger ? 1 : 0)
            .offset(y: trigger ? 0 : 16)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.75)
                    .delay(Double(delay) * EventAnimation.staggerDelay),
                value: trigger
            )
    }
}

// ─── ADAPTIVE SURFACE ───────────────────────────────────────────────────

struct AdaptiveSurface {
    let scheme: ColorScheme

    var background: Color { scheme == .dark ? .surfaceBackgroundDark : .surfaceBackground }
    var raised: Color { scheme == .dark ? .surfaceRaisedDark : .surfaceRaised }
    var subtle: Color { scheme == .dark ? .surfaceSubtleDark : .surfaceSubtle }
    var dim: Color { scheme == .dark ? .surfaceDimDark : .surfaceDim }
    var border: Color { scheme == .dark ? .borderSubtleDark : .borderSubtle }
    var textPrimary: Color { scheme == .dark ? .textPrimaryDark : .textPrimary }
    var textSecondary: Color { scheme == .dark ? .textSecondaryDark : .textSecondary }
    var textTertiary: Color { scheme == .dark ? .textTertiaryDark : .textTertiary }
}

// ─── EVENT GLASS SURFACES ───────────────────────────────────────────────

enum EventGlass {
    @ViewBuilder
    static func surface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius))
    }

    @ViewBuilder
    static func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .modifier(GlassCardModifier())
    }

    @ViewBuilder
    static func tabBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
    }

    @ViewBuilder
    static func pill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(.ultraThinMaterial, in: Capsule())
    }

    @ViewBuilder
    static func header<Content: View>(safeAreaTop: CGFloat = 0, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, EventSpacing.pageMargin)
            .padding(.top, safeAreaTop)
            .padding(.bottom, EventSpacing.lg)
            .background(.ultraThinMaterial)
    }
}

// ─── MESH GRADIENT (iOS 18+) ────────────────────────────────────────────

enum EventMeshGradient {
    /// Hero mesh — terracotta → amber → teal
    @ViewBuilder
    static func heroBackground() -> some View {
        if #available(iOS 18, *) {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .brandPrimary.opacity(0.8), .brandAccent.opacity(0.4), .brandSecondary.opacity(0.3),
                    .brandAccent.opacity(0.5), .brandPrimary.opacity(0.6), .brandSecondary.opacity(0.4),
                    .brandSecondary.opacity(0.6), .brandPrimary.opacity(0.3), .brandAccent.opacity(0.5)
                ]
            )
            .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [.brandPrimary.opacity(0.6), .brandSecondary.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    /// Subtle accent background for cards
    @ViewBuilder
    static func accentBackground() -> some View {
        if #available(iOS 18, *) {
            MeshGradient(
                width: 2, height: 2,
                points: [[0, 0], [1, 0], [0, 1], [1, 1]],
                colors: [
                    .brandPrimary.opacity(0.15), .brandAccent.opacity(0.1),
                    .brandSecondary.opacity(0.1), .brandPrimary.opacity(0.12)
                ]
            )
        } else {
            Color.brandPrimary.opacity(0.08)
        }
    }

    /// Deep scanner background — dark terracotta → deep navy
    @ViewBuilder
    static func scannerBackground() -> some View {
        if #available(iOS 18, *) {
            MeshGradient(
                width: 2, height: 2,
                points: [[0, 0], [1, 0], [0, 1], [1, 1]],
                colors: [
                    .brandPrimary.opacity(0.2), Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.08, green: 0.04, blue: 0.12), .brandSecondary.opacity(0.15)
                ]
            )
            .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.04, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

// ─── SKELETON LOADING ───────────────────────────────────────────────────

struct SkeletonModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: shimmerOffset * geometry.size.width * 1.5)
                    .animation(EventAnimation.shimmer, value: shimmerOffset)
                }
                .mask(content)
            )
            .onAppear { shimmerOffset = 1.0 }
            .allowsHitTesting(false)
    }
}

extension View {
    func skeleton() -> some View { modifier(SkeletonModifier()) }
}

// ─── ANIMATED GRADIENT BORDER ───────────────────────────────────────────

struct AnimatedGradientBorder: ViewModifier {
    let isActive: Bool
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: isActive
                                ? [.brandPrimary, .brandAccent, .brandSecondary, .brandPrimary]
                                : [.clear],
                            center: .center, angle: .degrees(rotation)
                        ),
                        lineWidth: isActive ? 2 : 0
                    )
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: rotation)
            )
            .onAppear { if isActive { rotation = 360 } }
            .onChange(of: isActive) { _, newValue in rotation = newValue ? 360 : 0 }
    }
}

extension View {
    func animatedBorder(isActive: Bool) -> some View {
        modifier(AnimatedGradientBorder(isActive: isActive))
    }
}

// ─── VIEWFINDER BRACKETS ────────────────────────────────────────────────
// Corner brackets for the camera viewfinder

struct ViewfinderBrackets: View {
    let tintColor: Color
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    init(
        tintColor: Color = .white,
        lineWidth: CGFloat = 3,
        cornerRadius: CGFloat = 8
    ) {
        self.tintColor = tintColor
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        GeometryReader { geo in
            let inset: CGFloat = EventSpacing.viewfinderInset
            let len: CGFloat = EventSpacing.bracketLength

            ZStack {
                // Top-left
                BracketCorner(radius: cornerRadius, lineWidth: lineWidth)
                    .stroke(tintColor, style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: len, height: len, alignment: .topLeading)
                    .position(x: inset, y: inset)

                // Top-right
                BracketCorner(radius: cornerRadius, lineWidth: lineWidth)
                    .stroke(tintColor, style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: len, height: len, alignment: .topTrailing)
                    .position(x: geo.size.width - inset, y: inset)

                // Bottom-left
                BracketCorner(radius: cornerRadius, lineWidth: lineWidth)
                    .stroke(tintColor, style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: len, height: len, alignment: .bottomLeading)
                    .position(x: inset, y: geo.size.height - inset)

                // Bottom-right
                BracketCorner(radius: cornerRadius, lineWidth: lineWidth)
                    .stroke(tintColor, style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: len, height: len, alignment: .bottomTrailing)
                    .position(x: geo.size.width - inset, y: geo.size.height - inset)
            }
        }
    }
}

/// A single corner bracket shape
struct BracketCorner: Shape {
    let radius: CGFloat
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.width / 2, rect.height / 2)
        let t = lineWidth / 2 // offset so stroke is centered

        if rect.width > rect.height {
            // Horizontal bracket
            path.move(to: CGPoint(x: t, y: rect.height / 2))
            path.addLine(to: CGPoint(x: r + t, y: rect.height / 2))
            path.addLine(to: CGPoint(x: r + t, y: t))
            path.addLine(to: CGPoint(x: rect.width - t, y: t))
        } else {
            // Vertical bracket
            path.move(to: CGPoint(x: rect.width / 2, y: t))
            path.addLine(to: CGPoint(x: rect.width / 2, y: r + t))
            path.addLine(to: CGPoint(x: t, y: r + t))
            path.addLine(to: CGPoint(x: t, y: rect.height - t))
        }

        return path
    }
}

// ─── SCANNING BEAM LINE ─────────────────────────────────────────────────

struct ScanningBeam: View {
    let isActive: Bool
    let beamColor: Color

    @State private var beamPosition: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            if isActive {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                beamColor.opacity(0),
                                beamColor.opacity(0.8),
                                beamColor.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 3)
                    .shadow(color: beamColor.opacity(0.6), radius: 8, x: 0, y: 0)
                    .offset(y: beamPosition * geo.size.height)
                    .animation(
                        Animation.linear(duration: 2.5)
                            .repeatForever(autoreverses: true),
                        value: beamPosition
                    )
                    .onAppear { beamPosition = 1 }
            }
        }
    }
}

// ─── CAPTURE BUTTON ─────────────────────────────────────────────────────

struct CaptureButton: View {
    let action: () -> Void
    let isReady: Bool
    let isDisabled: Bool
    let scale: CGFloat

    init(
        action: @escaping () -> Void,
        isReady: Bool = false,
        isDisabled: Bool = false,
        scale: CGFloat = 1.0
    ) {
        self.action = action
        self.isReady = isReady
        self.isDisabled = isDisabled
        self.scale = scale
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow ring (pulses when ready)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                isReady ? Color.scanSuccess.opacity(0.8) : .white.opacity(0.6),
                                isReady ? Color.scanSuccess.opacity(0.2) : .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isReady ? 5 : 4
                    )
                    .frame(width: EventSpacing.captureButtonOuter)
                    .scaleEffect(isReady ? 1.08 : 1.0)
                    .animation(EventAnimation.slowPulse, value: isReady)

                // Inner solid ring
                Circle()
                    .fill(.white)
                    .frame(width: EventSpacing.captureButtonInner)

                // Innermost accent
                Circle()
                    .fill(isReady ? Color.scanSuccess : Color.brandPrimary)
                    .frame(width: EventSpacing.captureButtonInner - 8)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1.0)
        .accessibilityLabel("Capture event")
    }
}

// ── Animated Checkmark ──────────────────────────────────────────────────

struct AnimatedCheckmark: View {
    let strokeColor: Color
    let lineWidth: CGFloat

    init(strokeColor: Color = .semanticSuccess, lineWidth: CGFloat = 4) {
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }

    var body: some View {
        CheckmarkShape()
            .trim(to: 1)
            .stroke(
                strokeColor,
                style: .init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
            .frame(width: 80, height: 80)
            .scaleEffect(0)
            .animation(
                .easeOut(duration: 0.6).delay(0.2),
                value: true
            )
            .scaleEffect(1)
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.25))
        return path
    }
}

// ── Confetti Particles ──────────────────────────────────────────────────

struct ConfettiBurst: View {
    let isPlaying: Bool
    let particleCount: Int

    @State private var particles: [(x: CGFloat, y: CGFloat, color: Color, rotation: Double, scale: CGFloat)] = []

    init(isPlaying: Bool, count: Int = 12) {
        self.isPlaying = isPlaying
        self.particleCount = count
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particleCount, id: \.self) { i in
                if i < particles.count {
                    let p = particles[i]
                    Circle()
                        .fill(p.color)
                        .frame(width: 8 + CGFloat(i % 3) * 3, height: 8 + CGFloat(i % 3) * 3)
                        .position(x: geo.size.width / 2 + p.x, y: geo.size.height / 2 + p.y)
                        .rotationEffect(.degrees(p.rotation))
                        .shadow(color: p.color.opacity(0.3), radius: 2)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { generateParticles() }
        .onChange(of: isPlaying) { _, newValue in if newValue { generateParticles() } }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { i in
            let angle = Double(i) / Double(particleCount) * 360
            let distance: CGFloat = 80 + CGFloat.random(in: 0...120)
            let rad = angle * .pi / 180
            return (
                x: cos(rad) * distance,
                y: sin(rad) * distance - 40,
                color: EventGradient.confettiColors.randomElement() ?? .brandPrimary,
                rotation: Double.random(in: 0...360),
                scale: 0.8 + CGFloat.random(in: 0...0.5)
            )
        }
    }
}

// ─── BREATHING ORB (Voice) ─────────────────────────────────────────────
/// Central orb for the voice experience — pulses gently when idle,
/// expands and glows when actively recording. Used in VoiceInputView.

struct BreathingOrb: View {
    let isRecording: Bool
    let audioLevel: CGFloat
    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            // Outer glow — reacts to audio
            Circle()
                .fill(EventGradient.orbGradient)
                .frame(width: 120 + audioLevel * 80, height: 120 + audioLevel * 80)
                .opacity(isRecording ? 0.8 : 0.4)
                .animation(.easeInOut(duration: 0.3), value: audioLevel)

            // Core orb — breathing animation
            Circle()
                .fill(EventGradient.terracottaGlow)
                .frame(width: 80 + (isRecording ? audioLevel * 40 : 0), height: 80 + (isRecording ? audioLevel * 40 : 0))
                .opacity(isRecording ? 0.6 : 0.3)
                .scaleEffect(isRecording ? 1.0 : (0.9 + 0.1 * cos(phase)))
                .animation(.easeOut(duration: 0.3), value: audioLevel)

            // Inner highlight
            Circle()
                .fill(Color.brandPrimary.opacity(0.9))
                .frame(width: isRecording ? 50 : 30, height: isRecording ? 50 : 30)
                .opacity(isRecording ? 0.7 : 0.5)
                .animation(.easeOut(duration: 0.3), value: isRecording)

        }
        .onAppear {
            startIdleBreath()
        }
        .onChange(of: isRecording) { _, recording in
            if !recording { startIdleBreath() }
        }
    }

    private func startIdleBreath() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            phase = .pi * 2
        }
    }
}

// ─── WAVEFORM BAR (Gradient) ───────────────────────────────────────────
/// Single bar with vertical gradient fill — used in rows for voice waveform.

struct WaveformBar: View {
    let index: Int
    let height: CGFloat
    let isIdle: Bool
    let phase: Double
    let barWidth: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                isIdle ? EventGradient.voiceIdle : EventGradient.voiceWaveform
            )
            .frame(width: barWidth)
            .frame(maxHeight: height)
    }
}

// ─── CONCENTRIC RINGS ───────────────────────────────────────────────────
/// Expanding rings that pulse outward from center, responding to audio level.
/// Used as a background layer behind the BreathingOrb during recording.

struct ConcentricRings: View {
    let audioLevel: CGFloat
    let isRecording: Bool
    @State private var ringPhase: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(
                        Color.brandPrimary.opacity(0.15 - CGFloat(i) * 0.03),
                        lineWidth: 1
                    )
                    .frame(
                        width: 140 + CGFloat(i) * 40 + (isRecording ? audioLevel * 20 : 0),
                        height: 140 + CGFloat(i) * 40 + (isRecording ? audioLevel * 20 : 0)
                    )
                    .opacity(isRecording ? (0.6 - CGFloat(i) * 0.1) : 0.2)
                    .animation(.easeOut(duration: 0.3), value: audioLevel)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isRecording)
    }
}

// ─── VOICE STATUS PILL ──────────────────────────────────────────────────
/// Compact pill showing recording state, duration hint, or countdown.

struct VoiceStatusPill: View {
    let status: VoiceStatus
    @State private var pulse: Bool = false

    enum VoiceStatus {
        case idle
        case recording(seconds: Int)
        case processing
        case countdown(remaining: Int)
        case error(String)
    }

    var body: some View {
        HStack(spacing: EventSpacing.sm) {
            statusIcon
            statusLabel
        }
        .font(EventTypography.captionMedium)
        .padding(.horizontal, EventSpacing.lg)
        .padding(.vertical, EventSpacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            if case .recording = status {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var statusIcon: some View {
        Group {
            switch status {
            case .idle:
                Image(systemName: "mic")
                    .foregroundStyle(Color.brandPrimary)
            case .recording:
                Circle()
                    .fill(pulse ? Color.brandPrimary : .red)
                    .frame(width: 8, height: 8)
            case .processing:
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(Color.brandPrimary)
            case .countdown(let remaining):
                Text("\(remaining)")
                    .font(EventTypography.caption)
                    .foregroundStyle(Color.brandPrimary)
                    .contentTransition(.numericText())
                    .frame(width: 16, height: 16, alignment: .center)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.semanticError)
            }
        }
    }

    private var statusLabel: some View {
        Text(status.text)
            .foregroundStyle(Color.textSecondary)
    }
}

private extension VoiceStatusPill.VoiceStatus {
    var text: String {
        switch self {
        case .idle: return "Tap to speak"
        case .recording: return "Recording…"
        case .processing: return "Processing…"
        case .countdown: return "Auto-stopping…"
        case .error(let message): return message
        }
    }
}
