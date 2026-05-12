import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Creates a color from a hex string (e.g. "#FF6B35").
    /// Supports 6-character hex strings with or without the leading `#`.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Design System Colors

    /// Warm orange accent for active elements and CTA buttons (#FF6B35)
    static let accentPrimary = Color(hex: "#FF6B35")
    /// Teal accent for "View in Calendar" links (#5AC8FA)
    static let accentTeal = Color(hex: "#5AC8FA")
    /// Green for on-device privacy badge (#34C759)
    static let privacyGreen = Color(hex: "#34C759")
}

#if canImport(UIKit)
extension UIColor {
    /// Creates a UIColor from a hex string (e.g. "#FF6B35").
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    // Design system colors (matching SwiftUI Color counterparts)
    static let accentPrimary = UIColor(hex: "#FF6B35")
    static let accentTeal = UIColor(hex: "#5AC8FA")
    static let privacyGreen = UIColor(hex: "#34C759")
}
#endif