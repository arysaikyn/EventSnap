import Foundation

/// Centralized PII (Personally Identifiable Information) sanitization utility.
///
/// Provides static methods to redact emails, phone numbers, SSNs, and URLs
/// from text. All regex patterns are compiled once and cached as static lets.
///
/// Usage:
/// ```swift
/// let clean = PIISanitizer.sanitize("Email me at test@example.com")
/// // "Email me at [EMAIL]"
/// ```
public struct PIISanitizer {

    // MARK: - Regex Patterns (cached)

    private static let emailRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,}",
            options: []
        )
    }()

    private static let phoneRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b",
            options: []
        )
    }()

    private static let ssnRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b",
            options: []
        )
    }()

    private static let urlRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "https?://[^\\s]+",
            options: []
        )
    }()

    // MARK: - Replacement Tokens

    private static let emailReplacement = "[EMAIL]"
    private static let phoneReplacement = "[PHONE]"
    private static let ssnReplacement = "[SSN]"
    private static let urlReplacement = "[URL]"

    // MARK: - Public API

    /// Sanitizes PII from any text: removes emails, phone numbers, and SSNs.
    /// - Parameter text: The raw text to sanitize.
    /// - Returns: Text with PII replaced by `[EMAIL]`, `[PHONE]`, and `[SSN]`.
    public static func sanitize(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        let result = sanitizeEmails(text)
        let result2 = sanitizePhoneNumbers(result)
        return sanitizeSSN(result2)
    }

    /// More aggressive sanitization: also strips URLs in addition to emails,
    /// phone numbers, and SSNs.
    /// - Parameter text: The raw text to sanitize.
    /// - Returns: Text with PII and URLs replaced.
    public static func sanitizeAggressive(_ text: String) -> String {
        let result = sanitize(text)
        return sanitizeURLs(result)
    }

    /// Replaces email addresses with `[EMAIL]`.
    public static func sanitizeEmails(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return emailRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: emailReplacement
        )
    }

    /// Replaces phone numbers with `[PHONE]`.
    public static func sanitizePhoneNumbers(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return phoneRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: phoneReplacement
        )
    }

    /// Replaces SSNs with `[SSN]`.
    public static func sanitizeSSN(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return ssnRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: ssnReplacement
        )
    }

    /// Replaces URLs with `[URL]`.
    public static func sanitizeURLs(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return urlRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: urlReplacement
        )
    }

    /// Sanitizes input text by removing control characters and potential injection patterns.
    /// This is meant for user-provided text before it's used in event fields.
    public static func sanitizeInput(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        // Remove control characters (except common whitespace)
        let allowedControlChars = CharacterSet(charactersIn: "\n\r\t")
        let filtered = text.unicodeScalars.filter {
            allowedControlChars.contains($0) || !CharacterSet.controlCharacters.contains($0)
        }
        var result = String(filtered)

        // Apply standard PII sanitization
        return sanitize(result)
    }
}