import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import EventKit

// MARK: - ShareExtensionViewModel

/// View model for the iOS Share Extension.
/// Handles loading shared content (text/images), parsing event details via NLParser,
/// and saving to calendar via CalendarService.
@MainActor
final class ShareExtensionViewModel: ObservableObject {

    // MARK: - State

    /// Represents the current processing state of the share extension.
    enum State: Identifiable {
        case loading
        case parsing
        case preview(ParsedEvent)
        case success(EventHistory)
        case error(String)

        var id: String {
            switch self {
            case .loading: return "loading"
            case .parsing: return "parsing"
            case .preview: return "preview"
            case .success: return "success"
            case .error: return "error"
            }
        }
    }

    // MARK: - Published Properties

    @Published private(set) var state: State = .loading
    @Published private(set) var sharedImage: UIImage?
    @Published private(set) var sharedText: String = ""

    // MARK: - Dependencies

    private let extensionContext: NSExtensionContext?
    private let calendarService: CalendarService

    // MARK: - Init

    init(extensionContext: NSExtensionContext? = nil) {
        self.extensionContext = extensionContext
        self.calendarService = CalendarService()
    }

    // MARK: - Load Shared Items

    /// Extracts shared content from the extension context.
    /// Looks for text (public.plain-text) and images (public.image) from NSExtensionItem providers.
    func loadSharedItems() {
        guard let extensionContext else {
            state = .error("No extension context available")
            return
        }

        let items = extensionContext.inputItems as! [NSExtensionItem]
        guard !items.isEmpty else {
            state = .error("No shared content found")
            return
        }

        Task {
            await processExtensionItems(items)
        }
    }

    private func processExtensionItems(_ items: [NSExtensionItem]) async {
        var foundText: String?
        var foundImage: UIImage?

        for item in items {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if foundText == nil && provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    foundText = await loadText(from: provider)
                } else if foundImage == nil && provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    foundImage = await loadImage(from: provider)
                }

                if foundText != nil && foundImage != nil {
                    break
                }
            }

            if foundText != nil {
                break
            }
        }

        if let text = foundText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sharedText = text
            await parseText(text)
        } else if let image = foundImage {
            sharedImage = image
            await processImage(image)
        } else {
            state = .error("Unsupported content type. Please share text or an image.")
        }
    }

    // MARK: - Text Extraction

    private func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.plainText.identifier,
                options: nil
            ) { item, error in
                if let error = error {
                    print("ShareExtension: Failed to load text: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                let result: String?
                if let data = item as? Data {
                    result = String(data: data, encoding: .utf8)
                } else if let string = item as? String {
                    result = string
                } else if let url = item as? URL {
                    result = try? String(contentsOf: url, encoding: .utf8)
                } else {
                    result = nil
                }

                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Image Extraction

    private func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.image.identifier,
                options: nil
            ) { item, error in
                if let error = error {
                    print("ShareExtension: Failed to load image: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                let result: UIImage?
                if let image = item as? UIImage {
                    result = image
                } else if let url = item as? URL {
                    result = UIImage(contentsOfFile: url.path)
                } else if let data = item as? Data {
                    result = UIImage(data: data)
                } else {
                    result = nil
                }

                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Parse Text

    private func parseText(_ text: String) async {
        state = .parsing

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .error("No text content to parse")
            return
        }

        guard let parsedEvent = NLParser.parse(trimmed, inputType: .text) else {
            state = .error("Could not find event details in the shared text. Try sharing text with a date and time.")
            return
        }

        if !parsedEvent.isReadyForCalendar {
            state = .error("Event details are incomplete. Please ensure the text includes an event name and date.")
            return
        }

        state = .preview(parsedEvent)
    }

    // MARK: - Process Image

    private func processImage(_ image: UIImage) async {
        state = .parsing

        guard let cgImage = image.cgImage else {
            state = .error("Couldn't read the shared image")
            return
        }

        let ocrService = OCRService()
        let extractedText = await ocrService.recognizeText(from: cgImage, preferAccuracy: true)

        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .error("No text found in the image. Try a clearer photo of your event.")
            return
        }

        sharedText = extractedText

        guard let parsedEvent = NLParser.parse(extractedText, inputType: .camera) else {
            state = .error("Could not find event details in the image. Try a clearer photo.")
            return
        }

        if !parsedEvent.isReadyForCalendar {
            state = .error("Event details are incomplete. Make sure the image shows a date and time.")
            return
        }

        state = .preview(parsedEvent)
    }

    // MARK: - Save to Calendar

    /// Saves the parsed event to the calendar and transitions to success state.
    func saveToCalendar(event parsedEvent: ParsedEvent) {
        Task {
            do {
                if !calendarService.isAccessGranted {
                    let granted = try await calendarService.requestAccess()
                    if !granted {
                        state = .error("Calendar access is required to save events. Please enable it in Settings.")
                        return
                    }
                }

                let ekEvent = try await calendarService.addEvent(parsedEvent)

                let history = EventHistory(
                    title: parsedEvent.title,
                    startDate: parsedEvent.startDate,
                    endDate: parsedEvent.endDate,
                    location: parsedEvent.location,
                    calendarIdentifier: ekEvent.calendar.calendarIdentifier,
                    inputType: parsedEvent.inputType,
                    confidence: parsedEvent.confidence,
                    eventIdentifier: ekEvent.eventIdentifier
                )

                state = .success(history)

                calendarService.openEventInCalendar(with: ekEvent.eventIdentifier)

            } catch CalendarService.CalendarError.accessDenied {
                state = .error("Calendar access was denied. Please enable it in Settings > Privacy > Calendars.")
            } catch CalendarService.CalendarError.accessRestricted {
                state = .error("Calendar access is restricted on this device.")
            } catch CalendarService.CalendarError.eventCreationFailed(let underlying) {
                state = .error("Failed to create event: \(underlying?.localizedDescription ?? "Unknown error")")
            } catch {
                state = .error("Unexpected error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Close Extension

    /// Dismisses the share extension and returns to the host app.
    func closeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // MARK: - Reset

    /// Resets the view model to its initial loading state.
    func reset() {
        sharedText = ""
        sharedImage = nil
        state = .loading
    }
}
