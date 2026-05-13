import Foundation

/// Centralized PII (Personally Identifiable Information) sanitization utility.
///
/// Provides static methods to redact emails, phone numbers, SSNs, and URLs
/// from text. All regex patterns are compiled once and cached as static lets.
///
/// **Concurrency:** This is a pure-function utility. Regex patterns are immutable
/// `static let` constants and `NSRegularExpression` is Sendable on the app's
/// supported iOS versions, so public sanitization methods are explicitly
/// `nonisolated` for safe use from actors and background callbacks.
///
/// Usage:
/// ```swift
/// let clean = PIISanitizer.sanitize("Email me at test@example.com")
/// // "Email me at [EMAIL]"
/// ```
public struct PIISanitizer: @unchecked Sendable {

    // MARK: - Regex Patterns (cached)

    private nonisolated static let emailRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,}",
            options: []
        )
    }()

    private nonisolated static let phoneRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b",
            options: []
        )
    }()

    private nonisolated static let ssnRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "\\b\\d{3}-\\d{2}-\\d{4}\\b",
            options: []
        )
    }()

    private nonisolated static let urlRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "https?://[^\\s]+",
            options: []
        )
    }()

    // MARK: - Replacement Tokens

    private nonisolated static let emailReplacement = "[EMAIL]"
    private nonisolated static let phoneReplacement = "[PHONE]"
    private nonisolated static let ssnReplacement = "[SSN]"
    private nonisolated static let urlReplacement = "[URL]"

    // MARK: - Public API

    /// Sanitizes PII from any text: removes emails, phone numbers, and SSNs.
    /// - Parameter text: The raw text to sanitize.
    /// - Returns: Text with PII replaced by `[EMAIL]`, `[PHONE]`, and `[SSN]`.
    public nonisolated static func sanitize(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return sanitizeSSN(sanitizePhoneNumbers(sanitizeEmails(text)))
    }

    /// More aggressive sanitization: also strips URLs in addition to emails,
    /// phone numbers, and SSNs.
    /// - Parameter text: The raw text to sanitize.
    /// - Returns: Text with PII and URLs replaced.
    public nonisolated static func sanitizeAggressive(_ text: String) -> String {
        let result = sanitize(text)
        return sanitizeURLs(result)
    }

    /// Replaces email addresses with `[EMAIL]`.
    public nonisolated static func sanitizeEmails(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return emailRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: emailReplacement
        )
    }

    /// Replaces phone numbers with `[PHONE]`.
    public nonisolated static func sanitizePhoneNumbers(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return phoneRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: phoneReplacement
        )
    }

    /// Replaces SSNs with `[SSN]`.
    public nonisolated static func sanitizeSSN(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return ssnRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: ssnReplacement
        )
    }

    /// Replaces URLs with `[URL]`.
    public nonisolated static func sanitizeURLs(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        return urlRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: urlReplacement
        )
    }

    /// Sanitizes input text by removing control characters and potential injection patterns.
    /// This is meant for user-provided text before it's used in event fields.
    public nonisolated static func sanitizeInput(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        // Remove control characters (except common whitespace)
        let allowedControlChars = CharacterSet(charactersIn: "\n\r\t")
        let filtered = text.unicodeScalars.filter {
            allowedControlChars.contains($0) || !CharacterSet.controlCharacters.contains($0)
        }
        let result = String(filtered)

        // Apply standard PII sanitization
        return sanitize(result)
    }
}