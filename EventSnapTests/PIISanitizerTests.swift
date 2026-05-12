import XCTest
@testable import EventSnap

// MARK: - PIISanitizerTests

final class PIISanitizerTests: XCTestCase {
    
    // MARK: - Email Sanitization Tests
    
    func testSanitize_Email_Basic() async throws {
        // Given
        let textWithEmail = "Contact john.doe@example.com about the meeting"
        let expectedSanitized = "Contact [EMAIL] about the meeting"
        
        // When
        let sanitized = PIISanitizer.sanitizeEmails(textWithEmail)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testSanitize_Email_Multiple() async throws {
        // Given
        let textWithMultipleEmails = "Email john@example.com or jane@company.org"
        let expectedSanitized = "Email [EMAIL] or [EMAIL]"
        
        // When
        let sanitized = PIISanitizer.sanitizeEmails(textWithMultipleEmails)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testSanitize_Email_NoEmails() async throws {
        // Given
        let cleanText = "Meeting at the office tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitizeEmails(cleanText)
        
        // Then
        XCTAssertEqual(sanitized, cleanText)
    }
    
    func testSanitize_Email_InSentence() async throws {
        // Given
        let textWithEmail = "Please RSVP to sarah@team.com by Friday"
        let expectedSanitized = "Please RSVP to [EMAIL] by Friday"
        
        // When
        let sanitized = PIISanitizer.sanitizeEmails(textWithEmail)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    // MARK: - Phone Number Sanitization Tests
    
    func testSanitize_Phone_Basic() async throws {
        // Given
        let textWithPhone = "Call me at 555-123-4567 tomorrow"
        let expectedSanitized = "Call me at [PHONE] tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitizePhoneNumbers(textWithPhone)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testSanitize_Phone_DifferentFormats() async throws {
        // Given
        let testCases = [
            ("Call 555-123-4567", "Call [PHONE]"),
            ("Call 555.123.4567", "Call [PHONE]"),
            ("Call 5551234567", "Call [PHONE]"),
            ("(555) 123-4567", "[PHONE]"),
            ("555 123 4567", "[PHONE]"),
        ]
        
        for (input, expected) in testCases {
            // When
            let sanitized = PIISanitizer.sanitizePhoneNumbers(input)
            
            // Then
            XCTAssertEqual(sanitized, expected, "Failed for input: \(input)")
        }
    }
    
    func testSanitize_Phone_NoPhoneNumbers() async throws {
        // Given
        let cleanText = "Meeting at the office tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitizePhoneNumbers(cleanText)
        
        // Then
        XCTAssertEqual(sanitized, cleanText)
    }
    
    // MARK: - SSN Sanitization Tests
    
    func testSanitize_SSN_Basic() async throws {
        // Given
        let textWithSSN = "My SSN is 123-45-6789"
        let expectedSanitized = "My SSN is [SSN]"
        
        // When
        let sanitized = PIISanitizer.sanitizeSSN(textWithSSN)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testSanitize_SSN_NoSSN() async throws {
        // Given
        let cleanText = "Meeting at the office tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitizeSSN(cleanText)
        
        // Then
        XCTAssertEqual(sanitized, cleanText)
    }
    
    // MARK: - URL Sanitization Tests
    
    func testSanitize_URL_Basic() async throws {
        // Given
        let textWithURL = "Visit https://example.com for details"
        let expectedSanitized = "Visit [URL] for details"
        
        // When
        let sanitized = PIISanitizer.sanitizeURLs(textWithURL)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testSanitize_URL_NoURLs() async throws {
        // Given
        let cleanText = "Meeting at the office tomorrow"
        
        // When
        let sanitized = PIISanitizer.sanitizeURLs(cleanText)
        
        // Then
        XCTAssertEqual(sanitized, cleanText)
    }
    
    // MARK: - Combined PII Sanitization Tests
    
    func testSanitize_MultiplePII_Types() async throws {
        // Given
        let textWithMultiplePII = "Email john@example.com or call 555-123-4567. My SSN is 123-45-6789."
        let expectedSanitized = "Email [EMAIL] or call [PHONE]. My SSN is [SSN]."
        
        // When
        let sanitized = PIISanitizer.sanitize(textWithMultiplePII)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    func testSanitize_Aggressive() async throws {
        // Given
        let textWithAllPII = "Visit https://example.com and email john@example.com or call 555-123-4567."
        let expectedSanitized = "Visit [URL] and [EMAIL] or [PHONE]."
        
        // When
        let sanitized = PIISanitizer.sanitizeAggressive(textWithAllPII)
        
        // Then
        XCTAssertEqual(sanitized, expectedSanitized)
    }
    
    // MARK: - Edge Cases
    
    func testSanitize_EmptyString() async throws {
        // Given
        let emptyText = ""
        
        // When
        let sanitized = PIISanitizer.sanitize(emptyText)
        
        // Then
        XCTAssertEqual(sanitized, emptyText)
    }
    
    func testSanitize_WhitespaceOnly() async throws {
        // Given
        let whitespaceText = "   \n\t  "
        
        // When
        let sanitized = PIISanitizer.sanitize(whitespaceText)
        
        // Then
        XCTAssertEqual(sanitized, whitespaceText)
    }
    
    func testSanitize_NoPII() async throws {
        // Given
        let cleanText = "Meeting at the office tomorrow at 3pm"
        
        // When
        let sanitized = PIISanitizer.sanitize(cleanText)
        
        // Then
        XCTAssertEqual(sanitized, cleanText)
    }
    
    // MARK: - Input Sanitization Tests
    
    func testSanitizeInput_ControlCharacters() async throws {
        // Given
        let textWithControlChars = "Meeting\u{00}tomorrow\u{01}at\u{023}pm"
        
        // When
        let sanitized = PIISanitizer.sanitizeInput(textWithControlChars)
        
        // Then
        // Should remove control characters and preserve PII sanitization
        XCTAssertFalse(sanitized.contains("\u{00}"))
        XCTAssertFalse(sanitized.contains("\u{01}"))
        XCTAssertFalse(sanitized.contains("\u{02}"))
    }
    
    func testSanitizeInput_WithPII() async throws {
        // Given
        let textWithPII = "Contact john@example.com at 555-123-4567"
        
        // When
        let sanitized = PIISanitizer.sanitizeInput(textWithPII)
        
        // Then
        XCTAssertEqual(sanitized, "Contact [EMAIL] at [PHONE]")
    }
    
    func testSanitizeInput_WithNewlines() async throws {
        // Given
        let textWithNewlines = "Meeting tomorrow\nat 3pm\nJohn's email: john@example.com"
        
        // When
        let sanitized = PIISanitizer.sanitizeInput(textWithNewlines)
        
        // Then
        // Should preserve newlines but sanitize PII
        XCTAssertTrue(sanitized.contains("\n"))
        XCTAssertEqual(sanitized, "Meeting tomorrow\nat 3pm\nJohn's email: [EMAIL]")
    }
    
    // MARK: - Individual Method Tests
    
    func testSanitizeEmails_OnlyEmails() async throws {
        // Given
        let text = "Email test@example.com and user@domain.org"
        
        // When
        let sanitized = PIISanitizer.sanitizeEmails(text)
        
        // Then
        XCTAssertEqual(sanitized, "Email [EMAIL] and [EMAIL]")
    }
    
    func testSanitizePhoneNumbers_OnlyPhones() async throws {
        // Given
        let text = "Call 555-123-4567 or 555.987.6543"
        
        // When
        let sanitized = PIISanitizer.sanitizePhoneNumbers(text)
        
        // Then
        XCTAssertEqual(sanitized, "Call [PHONE] or [PHONE]")
    }
    
    func testSanitizeSSN_OnlySSN() async throws {
        // Given
        let text = "My SSN is 123-45-6789 and my friend's is 987-65-4321"
        
        // When
        let sanitized = PIISanitizer.sanitizeSSN(text)
        
        // Then
        XCTAssertEqual(sanitized, "My SSN is [SSN] and my friend's is [SSN]")
    }
    
    func testSanitizeURLs_OnlyURLs() async throws {
        // Given
        let text = "Visit https://example.com and check http://test.org"
        
        // When
        let sanitized = PIISanitizer.sanitizeURLs(text)
        
        // Then
        XCTAssertEqual(sanitized, "Visit [URL] and check [URL]")
    }
    
    // MARK: - Performance Tests
    
    func testSanitize_LargeText() async throws {
        // Given
        let largeText = "Contact john@example.com for support. Call 555-123-4567 for emergencies.\nVisit https://company.com for more info. My SSN is 123-45-6789.\nEmail support@company.org with questions. Call 555.987.6543 for help.\nCheck https://help.company.com for documentation."
        
        // When
        let sanitized = PIISanitizer.sanitize(largeText)
        
        // Then
        XCTAssertEqual(sanitized, "Contact [EMAIL] for support. Call [PHONE] for emergencies.\nVisit [URL] for more info. My SSN is [SSN].\nEmail [EMAIL] with questions. Call [PHONE] for help.\nCheck [URL] for documentation.")
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testSanitize_Email_CaseInsensitive() async throws {
        // Given
        let testCases = [
            ("John@EXAMPLE.COM", "John@[EMAIL]"),
            ("user@Domain.Org", "user@[EMAIL]"),
            ("TEST@MAIL.COM", "[EMAIL]"),
        ]
        
        for (input, expected) in testCases {
            // When
            let sanitized = PIISanitizer.sanitizeEmails(input)
            
            // Then
            XCTAssertEqual(sanitized, expected, "Failed for input: \(input)")
        }
    }
    
    func testSanitize_Phone_NumberFormats() async throws {
        // Given
        let testCases = [
            ("5551234567", "[PHONE]"),
            ("555-123-4567", "[PHONE]"),
            ("555.123.4567", "[PHONE]"),
            ("555 123 4567", "[PHONE]"),
            ("(555)123-4567", "[PHONE]"),
            ("1-555-123-4567", "[PHONE]"),
        ]
        
        for (input, expected) in testCases {
            // When
            let sanitized = PIISanitizer.sanitizePhoneNumbers(input)
            
            // Then
            XCTAssertEqual(sanitized, expected, "Failed for input: \(input)")
        }
    }
}