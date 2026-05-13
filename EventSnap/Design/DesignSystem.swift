import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - EventSnap Design System
// Inspired by Things 3, Arc, Linear, Raycast — 95% neutral, 5% color
// Typography-first hierarchy, 8pt grid, spring animations
//
// Brand colors defined in Color+Hex.swift. This file adds the full
// semantic/neutral palette, typography, spacing, animations, and
// reusable view modifiers.

// ─── SEMANTIC COLORS ───────────────────────────────────────────────────

extension Color {
    // Semantic
    static let semanticSuccess = Color(red: 0.18, green: 0.71, blue: 0.36)   // #2DB55D
    static let semanticWarning = Color(red: 0.96, green: 0.65, blue: 0.14)   // #F5A623
    static let semanticError   = Color(red: 0.85, green: 0.19, blue: 0.15)   // #D93025
}

// ─── NEUTRAL SURFACES (Light) ──────────────────────────────────────────

extension Color {
    static let surfaceBase       = Color(red: 0.97, green: 0.97, blue: 0.97)   // #F7F7F8
    static let surfaceRaised     = Color(red: 1.0,  green: 1.0,  blue: 1.0)    // #FFFFFF
    static let surfaceSubtle     = Color(red: 0.94, green: 0.94, blue: 0.94)   // #EFEFF0
    static let surfaceDim        = Color(red: 0.90, green: 0.90, blue: 0.91)   // #E5E5E7
}

// ─── NEUTRAL SURFACES (Dark) ───────────────────────────────────────────

extension Color {
    static let surfaceBaseDark       = Color(red: 0.11, green: 0.11, blue: 0.12)   // #1C1C1E
    static let surfaceRaisedDark     = Color(red: 0.17, green: 0.17, blue: 0.18)   // #2C2C2E
    static let surfaceSubtleDark     = Color(red: 0.23, green: 0.23, blue: 0.24)   // #3A3A3C
    static let surfaceDimDark        = Color(red: 0.28, green: 0.28, blue: 0.29)   // #48484A
}

// ─── TEXT HIERARCHY (Light) ─────────────────────────────────────────────

extension Color {
    static let textPrimary    = Color(red: 0.11, green: 0.11, blue: 0.12)   // #1C1C1E
    static let textSecondary  = Color(red: 0.43, green: 0.43, blue: 0.45)   // #6E6E73
    static let textTertiary   = Color(red: 0.68, green: 0.68, blue: 0.70)   // #AEAEB2
    static let textQuaternary = Color(red: 0.78, green: 0.78, blue: 0.80)   // #C7C7CC
}

// ─── TEXT HIERARCHY (Dark) ──────────────────────────────────────────────

extension Color {
    static let textPrimaryDark    = Color(red: 0.96, green: 0.96, blue: 0.97)   // #F5F5F7
    static let textSecondaryDark  = Color(red: 0.60, green: 0.60, blue: 0.62)   // #98989D
    static let textTertiaryDark   = Color(red: 0.39, green: 0.39, blue: 0.40)   // #636366
    static let textQuaternaryDark = Color(red: 0.28, green: 0.28, blue: 0.29)   // #48484A
}

// ─── BORDERS ────────────────────────────────────────────────────────────

extension Color {
    static let borderSubtle     = Color(red: 0.90, green: 0.90, blue: 0.91)   // #E5E5E7
    static let borderStrong     = Color(red: 0.78, green: 0.78, blue: 0.80)   // #C7C7CC
    static let borderSubtleDark = Color(red: 0.22, green: 0.22, blue: 0.23)   // #38383A
    static let borderStrongDark = Color(red: 0.28, green: 0.28, blue: 0.29)   // #48484A
}

// ─── TYPOGRAPHY ─────────────────────────────────────────────────────────

enum EventTypography {
    // Page-level
    static let pageTitle     = Font.system(size: 28, weight: .bold)
    static let sectionTitle  = Font.system(size: 22, weight: .semibold)

    // Content-level
    static let headline      = Font.system(size: 17, weight: .semibold)
    static let body          = Font.system(size: 17, weight: .regular)
    static let bodyMedium    = Font.system(size: 17, weight: .medium)
    static let callout       = Font.system(size: 16, weight: .regular)
    static let calloutMedium = Font.system(size: 16, weight: .medium)

    // Support-level
    static let subheadline      = Font.system(size: 15, weight: .regular)
    static let subheadMedium    = Font.system(size: 15, weight: .medium)
    static let subheadSemibold  = Font.system(size: 15, weight: .semibold)
    static let footnote         = Font.system(size: 13, weight: .regular)
    static let footnoteSemibold = Font.system(size: 13, weight: .semibold)
    static let caption          = Font.system(size: 12, weight: .regular)
    static let captionMedium    = Font.system(size: 12, weight: .medium)
    static let caption2         = Font.system(size: 11, weight: .regular)

    // Special
    static let bigNumber  = Font.system(size: 34, weight: .bold, design: .rounded)
    static let iconTitle  = Font.system(size: 20, weight: .medium)
}

// ─── SPACING (8-pt grid) ────────────────────────────────────────────────

enum EventSpacing {
    // Micro
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8

    // Standard
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 20
    static let xxl: CGFloat = 24

    // Large
    static let huge: CGFloat    = 32
    static let massive: CGFloat = 48

    // Component-specific
    static let cardPadding: CGFloat      = 20
    static let cardCornerRadius: CGFloat = 14
    static let buttonHeight: CGFloat     = 52
    static let smallButtonHeight: CGFloat = 44
    static let inputHeight: CGFloat      = 48
    static let touchTarget: CGFloat      = 44
    static let pageMargin: CGFloat       = 20
}

// ─── CORNER RADIUS ──────────────────────────────────────────────────────

enum EventRadius {
    static let small: CGFloat  = 8
    static let medium: CGFloat = 12
    static let large: CGFloat  = 16
    static let xl: CGFloat     = 20
}

// ─── ANIMATIONS ─────────────────────────────────────────────────────────

enum EventAnimation {
    // Springs (the heart of premium feel)
    static let quick     = Animation.spring(response: 0.25, dampingFraction: 0.85)
    static let default_  = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let gentle    = Animation.spring(response: 0.45, dampingFraction: 0.65)
    static let bouncy    = Animation.spring(response: 0.40, dampingFraction: 0.55)
    static let snappy    = Animation.spring(response: 0.20, dampingFraction: 0.90)
    static let tabSwitch = Animation.spring(response: 0.40, dampingFraction: 0.70)

    // Durations
    static let fadeInDuration: Double  = 0.25
    static let fadeOutDuration: Double = 0.20
    static let staggerDelay: Double   = 0.08
}

// ─── HAPTICS ────────────────────────────────────────────────────────────

enum EventHaptics {
    static func tap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }

    static func press() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
    }

    static func heavy() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// ─── VIEW MODIFIERS ─────────────────────────────────────────────────────

/// Primary CTA button — filled with brand color
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

/// Secondary button — outlined with brand color
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

/// Ghost button — minimal, text-only
struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EventTypography.bodyMedium)
            .foregroundStyle(Color.textSecondary)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(EventAnimation.quick, value: configuration.isPressed)
    }
}

/// Card modifier — elevated surface with subtle shadow
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
                radius: colorScheme == .dark ? 12 : 8,
                x: 0, y: colorScheme == .dark ? 4 : 2
            )
    }
}

/// Glass card modifier — frosted translucent background
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EventSpacing.cardPadding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: EventSpacing.cardCornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

/// Input field modifier — clean, minimal with focus ring
struct EventInputModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let isFocused: Bool

    init(isFocused: Bool = false) {
        self.isFocused = isFocused
    }

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
                    .stroke(
                        isFocused ? Color.brandPrimary.opacity(0.6) : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(EventAnimation.quick, value: isFocused)
    }
}

// ─── VIEW EXTENSIONS ────────────────────────────────────────────────────

extension View {
    func eventCard() -> some View {
        modifier(EventCardModifier())
    }

    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    func eventInput(isFocused: Bool = false) -> some View {
        modifier(EventInputModifier(isFocused: isFocused))
    }

    /// Stagger reveal animation (for card fields appearing one by one)
    func staggerReveal(delay: Int, trigger: Bool) -> some View {
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

// ─── ADAPTIVE SURFACE HELPER ────────────────────────────────────────────

/// Returns the appropriate surface color for the current scheme.
/// Use in views via @Environment(\.colorScheme) or create an instance.
struct AdaptiveSurface {
    let scheme: ColorScheme

    var background: Color { scheme == .dark ? Color.surfaceBaseDark : Color.surfaceBase }
    var raised: Color { scheme == .dark ? Color.surfaceRaisedDark : Color.surfaceRaised }
    var subtle: Color { scheme == .dark ? Color.surfaceSubtleDark : Color.surfaceSubtle }
    var dim: Color { scheme == .dark ? Color.surfaceDimDark : Color.surfaceDim }
    var border: Color { scheme == .dark ? Color.borderSubtleDark : Color.borderSubtle }
    var textPrimary: Color { scheme == .dark ? Color.textPrimaryDark : Color.textPrimary }
    var textSecondary: Color { scheme == .dark ? Color.textSecondaryDark : Color.textSecondary }
    var textTertiary: Color { scheme == .dark ? Color.textTertiaryDark : Color.textTertiary }
}