import XCTest
import SwiftUI
@testable import EventSnap

// MARK: - DesignSystemTests

/// Tests the design system foundation: colors, typography, spacing, radius, animations, haptics.
final class DesignSystemTests: XCTestCase {

    // MARK: - Color Tests

    func testBrandColorsExist() {
        // Verify all brand colors can be created and are not default black
        let primary = Color.brandPrimary
        let secondary = Color.brandSecondary
        let accent = Color.brandAccent

        XCTAssertNotEqual(primary, Color.black, "brandPrimary should not be black")
        XCTAssertNotEqual(secondary, Color.black, "brandSecondary should not be black")
        XCTAssertNotEqual(accent, Color.black, "brandAccent should not be black")
    }

    func testSemanticColorsExist() {
        let success = Color.semanticSuccess
        let warning = Color.semanticWarning
        let error = Color.semanticError

        XCTAssertNotEqual(success, Color.black)
        XCTAssertNotEqual(warning, Color.black)
        XCTAssertNotEqual(error, Color.black)
    }

    func testNeutralSurfaceColorsExist() {
        // Light mode surfaces
        let base = Color.surfaceBase
        let raised = Color.surfaceRaised
        let subtle = Color.surfaceSubtle
        let dim = Color.surfaceDim

        XCTAssertNotEqual(base, Color.clear)
        XCTAssertNotEqual(raised, Color.clear)
        XCTAssertNotEqual(subtle, Color.clear)
        XCTAssertNotEqual(dim, Color.clear)
    }

    func testDarkModeSurfaceColorsExist() {
        let baseDark = Color.surfaceBaseDark
        let raisedDark = Color.surfaceRaisedDark
        let subtleDark = Color.surfaceSubtleDark
        let dimDark = Color.surfaceDimDark

        XCTAssertNotEqual(baseDark, Color.clear)
        XCTAssertNotEqual(raisedDark, Color.clear)
        XCTAssertNotEqual(subtleDark, Color.clear)
        XCTAssertNotEqual(dimDark, Color.clear)
    }

    func testTextHierarchyColorsExist() {
        // Light mode text hierarchy
        let primary = Color.textPrimary
        let secondary = Color.textSecondary
        let tertiary = Color.textTertiary
        let quaternary = Color.textQuaternary

        XCTAssertNotEqual(primary, Color.clear)
        XCTAssertNotEqual(secondary, Color.clear)
        XCTAssertNotEqual(tertiary, Color.clear)
        XCTAssertNotEqual(quaternary, Color.clear)

        // Dark mode text hierarchy
        let primaryDark = Color.textPrimaryDark
        let secondaryDark = Color.textSecondaryDark
        let tertiaryDark = Color.textTertiaryDark
        let quaternaryDark = Color.textQuaternaryDark

        XCTAssertNotEqual(primaryDark, Color.clear)
        XCTAssertNotEqual(secondaryDark, Color.clear)
        XCTAssertNotEqual(tertiaryDark, Color.clear)
        XCTAssertNotEqual(quaternaryDark, Color.clear)
    }

    func testBorderColorExist() {
        let subtle = Color.borderSubtle
        let strong = Color.borderStrong
        let subtleDark = Color.borderSubtleDark
        let strongDark = Color.borderStrongDark

        XCTAssertNotEqual(subtle, Color.clear)
        XCTAssertNotEqual(strong, Color.clear)
        XCTAssertNotEqual(subtleDark, Color.clear)
        XCTAssertNotEqual(strongDark, Color.clear)
    }

    func testColorHexInit_Valid6CharHex() {
        let color = Color(hex: "#E85D3A")
        XCTAssertNotEqual(color, Color.black)
    }

    func testColorHexInit_Valid8CharHex() {
        let color = Color(hex: "#E85D3AFF")
        XCTAssertNotEqual(color, Color.black)
    }

    func testColorHexInit_InvalidHex_DefaultsToBlack() {
        let color = Color(hex: "invalid")
        XCTAssertEqual(color, Color(red: 0, green: 0, blue: 0))
    }

    func testColorHexInit_NoPrefix() {
        let color = Color(hex: "E85D3A")
        XCTAssertNotEqual(color, Color.black)
    }

    // MARK: - Typography Tests

    func testTypography_PageTitle() {
        let font = EventTypography.pageTitle
        // Verify it's a valid system font (can't directly check size/weight in tests,
        // but we can verify the enum compiles and produces a Font)
        XCTAssertNotNil(font)
    }

    func testTypography_AllStylesExist() {
        // Verify all typography styles compile and produce fonts
        let styles: [Font] = [
            EventTypography.pageTitle,
            EventTypography.sectionTitle,
            EventTypography.headline,
            EventTypography.body,
            EventTypography.bodyMedium,
            EventTypography.callout,
            EventTypography.calloutMedium,
            EventTypography.subheadline,
            EventTypography.subheadMedium,
            EventTypography.subheadSemibold,
            EventTypography.footnote,
            EventTypography.footnoteSemibold,
            EventTypography.caption,
            EventTypography.captionMedium,
            EventTypography.caption2,
            EventTypography.bigNumber,
            EventTypography.iconTitle,
        ]
        XCTAssertEqual(styles.count, 17, "Should have 17 typography styles")
    }

    // MARK: - Spacing Tests

    func testSpacing_MicroValues() {
        XCTAssertEqual(EventSpacing.xs, 4)
        XCTAssertEqual(EventSpacing.sm, 8)
    }

    func testSpacing_StandardValues() {
        XCTAssertEqual(EventSpacing.md, 12)
        XCTAssertEqual(EventSpacing.lg, 16)
        XCTAssertEqual(EventSpacing.xl, 20)
        XCTAssertEqual(EventSpacing.xxl, 24)
    }

    func testSpacing_LargeValues() {
        XCTAssertEqual(EventSpacing.huge, 32)
        XCTAssertEqual(EventSpacing.massive, 48)
    }

    func testSpacing_ComponentValues() {
        XCTAssertEqual(EventSpacing.cardPadding, 20)
        XCTAssertEqual(EventSpacing.cardCornerRadius, 14)
        XCTAssertEqual(EventSpacing.buttonHeight, 52)
        XCTAssertEqual(EventSpacing.smallButtonHeight, 44)
        XCTAssertEqual(EventSpacing.inputHeight, 48)
        XCTAssertEqual(EventSpacing.touchTarget, 44)
        XCTAssertEqual(EventSpacing.pageMargin, 20)
    }

    func testSpacing_Follows8ptGrid() {
        // All spacing values should be multiples of 4 (half of 8pt grid)
        let allValues: [CGFloat] = [
            EventSpacing.xs, EventSpacing.sm, EventSpacing.md, EventSpacing.lg,
            EventSpacing.xl, EventSpacing.xxl, EventSpacing.huge, EventSpacing.massive,
        ]
        for value in allValues {
            XCTAssertEqual(value.truncatingRemainder(dividingBy: 4), 0,
                          "Spacing value \(value) should be a multiple of 4")
        }
    }

    // MARK: - Radius Tests

    func testRadius_AllValues() {
        XCTAssertEqual(EventRadius.small, 8)
        XCTAssertEqual(EventRadius.medium, 12)
        XCTAssertEqual(EventRadius.large, 16)
        XCTAssertEqual(EventRadius.xl, 20)
    }

    func testRadius_AscendingOrder() {
        XCTAssertTrue(EventRadius.small < EventRadius.medium)
        XCTAssertTrue(EventRadius.medium < EventRadius.large)
        XCTAssertTrue(EventRadius.large < EventRadius.xl)
    }

    // MARK: - Animation Tests

    func testAnimation_AllPresetsExist() {
        // Verify all animation presets compile
        let _: Animation = EventAnimation.quick
        let _: Animation = EventAnimation.default_
        let _: Animation = EventAnimation.gentle
        let _: Animation = EventAnimation.bouncy
        let _: Animation = EventAnimation.snappy
        let _: Animation = EventAnimation.tabSwitch
    }

    func testAnimation_DurationValues() {
        XCTAssertEqual(EventAnimation.fadeInDuration, 0.25)
        XCTAssertEqual(EventAnimation.fadeOutDuration, 0.20)
        XCTAssertEqual(EventAnimation.staggerDelay, 0.08)
    }

    // MARK: - AdaptiveSurface Tests

    func testAdaptiveSurface_LightMode() {
        let surface = AdaptiveSurface(scheme: .light)

        XCTAssertEqual(surface.background, Color.surfaceBase)
        XCTAssertEqual(surface.raised, Color.surfaceRaised)
        XCTAssertEqual(surface.subtle, Color.surfaceSubtle)
        XCTAssertEqual(surface.dim, Color.surfaceDim)
        XCTAssertEqual(surface.border, Color.borderSubtle)
        XCTAssertEqual(surface.textPrimary, Color.textPrimary)
        XCTAssertEqual(surface.textSecondary, Color.textSecondary)
        XCTAssertEqual(surface.textTertiary, Color.textTertiary)
    }

    func testAdaptiveSurface_DarkMode() {
        let surface = AdaptiveSurface(scheme: .dark)

        XCTAssertEqual(surface.background, Color.surfaceBaseDark)
        XCTAssertEqual(surface.raised, Color.surfaceRaisedDark)
        XCTAssertEqual(surface.subtle, Color.surfaceSubtleDark)
        XCTAssertEqual(surface.dim, Color.surfaceDimDark)
        XCTAssertEqual(surface.border, Color.borderSubtleDark)
        XCTAssertEqual(surface.textPrimary, Color.textPrimaryDark)
        XCTAssertEqual(surface.textSecondary, Color.textSecondaryDark)
        XCTAssertEqual(surface.textTertiary, Color.textTertiaryDark)
    }

    // MARK: - UIColor Tests (UIKit)

    func testUIColorBrandColorsExist() {
        let primary = UIColor.brandPrimary
        let secondary = UIColor.brandSecondary
        let accent = UIColor.brandAccent

        XCTAssertNotEqual(primary, UIColor.black)
        XCTAssertNotEqual(secondary, UIColor.black)
        XCTAssertNotEqual(accent, UIColor.black)
    }

    func testUIColorHexInit() {
        let color = UIColor(hex: "#E85D3A")
        XCTAssertNotEqual(color, UIColor.black)
    }
}