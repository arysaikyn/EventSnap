import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class TextInputViewModel {
    // MARK: - Published State

    var textInput = ""
    var isParsing = false
    var hasClipboardContent = false
    var validationError: String?

    // MARK: - Init

    init() {
        refreshClipboardStatus()
    }

    // MARK: - Parsing

    /// Parse the current text input and return a `ParsedEvent`.
    /// - Throws: `ValidationError.emptyText` if input is blank, or propagates NLParser errors.
    func parseEvent() async throws -> ParsedEvent {
        let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            validationError = "Please enter some text to parse."
            isParsing = false
            throw ValidationError.emptyText
        }

        validationError = nil
        isParsing = true

        do {
            guard let result = NLParser.parse(trimmed, inputType: .text) else {
                isParsing = false
                validationError = "Could not parse event: unable to extract event details."
                throw ValidationError.parsingFailed
            }

            isParsing = false

            return ParsedEvent(
                title: result.title,
                startDate: result.startDate,
                endDate: result.endDate,
                location: result.location,
                notes: result.notes,
                calendar: nil, // will be set by the creation coordinator
                confidence: result.confidence,
                uncertainFields: result.uncertainFields,
                sourceText: textInput,
                inputType: .text
            )
        } catch let error as ValidationError {
            isParsing = false
            validationError = error.localizedDescription
            throw error
        } catch {
            isParsing = false
            validationError = "Could not parse event: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Clipboard

    /// Paste content from the system pasteboard into `textInput`.
    func pasteFromClipboard() {
        guard let pasteboardString = UIPasteboard.general.string else {
            hasClipboardContent = false
            return
        }

        textInput = pasteboardString
        hasClipboardContent = true
        validationError = nil
    }

    /// Refresh whether the clipboard contains any strings.
    func refreshClipboardStatus() {
        hasClipboardContent = UIPasteboard.general.hasStrings
    }

    /// Clear all text and validation state.
    func clearText() {
        textInput = ""
        validationError = nil
    }
}

// MARK: - Validation Errors

extension TextInputViewModel {
    enum ValidationError: LocalizedError {
        case emptyText
        case parsingFailed

        var errorDescription: String? {
            switch self {
            case .emptyText: return "Please enter some text to parse."
            case .parsingFailed: return "Could not parse event: unable to extract event details."
            }
        }
    }
}