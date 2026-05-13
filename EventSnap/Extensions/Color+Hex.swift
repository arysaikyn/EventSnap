import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Creates a color from a hex string (e.g. "#E85D3A").
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

    // MARK: - Brand Colors (defined here, used everywhere)

    /// Warm terracotta — CTA buttons, active states, brand identity (#E85D3A)
    static let brandPrimary = Color(hex: "#E85D3A")

    /// Deep teal — links, calendar actions, secondary brand (#3A8F8F)
    static let brandSecondary = Color(hex: "#3A8F8F")

    /// Amber — highlights, badges, accent (#F5A623)
    static let brandAccent = Color(hex: "#F5A623")
}

#if canImport(UIKit)
extension UIColor {
    /// Creates a UIColor from a hex string (e.g. "#E85D3A").
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

    // Brand colors (matching SwiftUI Color counterparts)
    static let brandPrimary = UIColor(hex: "#E85D3A")
    static let brandSecondary = UIColor(hex: "#3A8F8F")
    static let brandAccent = UIColor(hex: "#F5A623")
}
#endif