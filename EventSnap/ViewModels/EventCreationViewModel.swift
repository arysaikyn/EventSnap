import SwiftUI
import EventKit
import SwiftData

// MARK: - State Machine

enum CreationState: Equatable {
    case idle
    case capturing(InputType)
    case processing(Double) // progress 0.0–1.0
    case preview(ParsedEvent)
    case confirming
    case completed(EventHistory)
    case error(String)

    static func == (lhs: CreationState, rhs: CreationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.capturing(let a), .capturing(let b)): return a == b
        case (.processing(let a), .processing(let b)): return a == b
        case (.preview, .preview): return true
        case (.confirming, .confirming): return true
        case (.completed, .completed): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Input Data

enum InputData {
    case image(UIImage)
    case text(String)
    case transcription(String)
}

// MARK: - ViewModel

@Observable
final class EventCreationViewModel {
    // MARK: - Published State

    var state: CreationState = .idle
    var parsedEvent: ParsedEvent?
    var errorMessage: String?
    var processingProgress: Double = 0.0

    // MARK: - Dependencies

    private let calendarService: CalendarService
    private let ocrService: OCRService
    private let speechService: SpeechService
    private let modelContext: ModelContext

    // MARK: - Init

    init(
        calendarService: CalendarService,
        ocrService: OCRService,
        speechService: SpeechService,
        modelContext: ModelContext
    ) {
        self.calendarService = calendarService
        self.ocrService = ocrService
        self.speechService = speechService
        self.modelContext = modelContext
    }

    // MARK: - State Transitions

    /// Transition: idle → capturing
    func startCapture(_ type: InputType) {
        state = .capturing(type)
        parsedEvent = nil
        errorMessage = nil
        processingProgress = 0.0
    }

    /// Transition: capturing → processing → preview | error
    func processInput(_ input: InputData) async {
        state = .processing(0.0)
        processingProgress = 0.0
        errorMessage = nil

        do {
            let sourceText: String
            let inputType: InputType

            switch input {
            case .image(let image):
                inputType = .camera
                await updateProgress(0.2)

                let ocrResult = try await ocrService.recognizeText(from: image)
                await updateProgress(0.6)
                sourceText = ocrResult.fullText

            case .text(let text):
                inputType = .text
                sourceText = text

            case .transcription(let text):
                inputType = .voice
                sourceText = text
            }

            await updateProgress(0.7)

            guard let result = NLParser.parse(sourceText, inputType: inputType) else {
                throw EventError.parsingFailed(NSError(domain: "EventSnap", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not parse event details from input."]))
            }
            await updateProgress(0.9)

            let event = ParsedEvent(
                title: result.title,
                startDate: result.startDate,
                endDate: result.endDate,
                location: result.location,
                notes: result.notes,
                calendar: calendarService.defaultCalendar,
                confidence: result.confidence,
                uncertainFields: result.uncertainFields,
                sourceText: sourceText,
                inputType: inputType
            )

            parsedEvent = event
            await updateProgress(1.0)

            state = .preview(event)

        } catch {
            await handleError(error)
        }
    }

    /// Transition: preview → confirming → completed | error
    func confirmEvent() async {
        guard let event = parsedEvent else {
            await handleError(EventError.noEventToConfirm)
            return
        }

        state = .confirming
        errorMessage = nil

        do {
            let ekEvent = try await calendarService.addEvent(event)

            // Persist to SwiftData history
            let history = EventHistory(
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                calendarIdentifier: ekEvent.calendar.calendarIdentifier,
                inputType: event.inputType,
                confidence: event.confidence,
                eventIdentifier: ekEvent.eventIdentifier
            )

            modelContext.insert(history)
            try modelContext.save()

            state = .completed(history)

        } catch {
            await handleError(error)
        }
    }

    /// Allow the user to go back to editing the parsed event
    func editEvent() {
        guard let event = parsedEvent else { return }
        state = .preview(event)
    }

    /// Called by the edit view when the user has finished modifying fields
    func updateParsedEvent(_ updatedEvent: ParsedEvent) {
        parsedEvent = updatedEvent
        state = .preview(updatedEvent)
    }

    /// Reset to idle (discard current flow)
    func reset() {
        state = .idle
        parsedEvent = nil
        errorMessage = nil
        processingProgress = 0.0
    }

    // MARK: - Helpers

    @MainActor
    private func updateProgress(_ value: Double) {
        processingProgress = value
        if case .processing = state {
            state = .processing(value)
        }
    }

    @MainActor
    private func handleError(_ error: Error) {
        let message: String
        if let eventError = error as? EventError {
            message = eventError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        errorMessage = message
        state = .error(message)
    }
}

// MARK: - Errors

enum EventError: LocalizedError {
    case noEventToConfirm
    case ocrFailed(Error)
    case parsingFailed(Error)
    case calendarSaveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noEventToConfirm:
            return "No event to confirm. Please capture or enter an event first."
        case .ocrFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .parsingFailed(let error):
            return "Could not parse event details: \(error.localizedDescription)"
        case .calendarSaveFailed(let error):
            return "Could not save to calendar: \(error.localizedDescription)"
        }
    }
}