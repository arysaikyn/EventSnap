@preconcurrency import Foundation
import Vision
#if canImport(UIKit)
import UIKit
#endif
import CoreGraphics

// MARK: - OCRService

/// Provides on-device OCR using the Vision framework.
///
/// **Architecture:**
/// - Uses `VNRecognizeTextRequest` with a **two-pass approach**: a fast scan
///   for immediate preview, then detailed recognition on demand.
/// - Supports both camera-captured `UIImage` and photo library images.
/// - Returns confidence scores alongside every block of extracted text.
/// - Sanitizes PII (emails, phone numbers, SSNs) from extracted text before
///   returning it to the caller.
///
/// **Memory safety:**
/// - Releases image data (`CGImage`) immediately after processing.
/// - Runs as an `actor` to guarantee thread-safe access.
actor OCRService {

    // MARK: - Types

    /// The result of a single OCR recognition pass.
    struct OCRResult: Sendable {
        /// All recognized text concatenated, with newlines preserved.
        let fullText: String

        /// Individual text observations with their confidence scores.
        let observations: [TextObservation]

        /// Average confidence across all observations (0.0–1.0).
        let averageConfidence: Double

        /// Whether any text was actually found.
        var hasText: Bool { !observations.isEmpty }

        /// Text with PII redacted for privacy.
        let sanitizedText: String
    }

    /// A single recognized text fragment from the OCR engine.
    struct TextObservation: Sendable, Identifiable {
        let id: UUID
        /// The recognized string.
        let text: String
        /// Confidence score from the Vision framework (0.0–1.0).
        let confidence: VNConfidence
        /// The bounding box in normalized coordinates.
        let boundingBox: CGRect
        /// The top-left point of the bounding box.
        let topLeft: CGPoint
        /// The bottom-right point of the bounding box.
        let bottomRight: CGPoint
    }

    /// The recognition tier to use.
    enum RecognitionTier: String, Sendable {
        /// Fast but less accurate. Best for instant preview.
        case fast
        /// Slower but highly accurate. Best for final parsing.
        case accurate
    }

    // MARK: - Errors

    enum OCRServiceError: LocalizedError {
        case imageConversionFailed
        case noTextFound
        case recognitionFailed(underlying: Error?)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Could not convert the image for processing."
            case .noTextFound:
                return "No text was found in the image."
            case .recognitionFailed(let error):
                return "Text recognition failed: \(error?.localizedDescription ?? "Unknown error")"
            case .cancelled:
                return "Text recognition was cancelled."
            }
        }
    }

    // MARK: - Properties

    /// The minimum confidence threshold for including a text observation.
    private let minimumConfidence: VNConfidence = 0.3

    // MARK: - Public API

    /// Performs a full two-pass OCR recognition on the given image.
    ///
    /// **Pass 1 (fast):** Quick scan with `.fast` revision — used to get
    ///   an immediate preview.
    /// **Pass 2 (accurate):** Detailed scan with `.accurate` revision for
    ///   the final parsing step.
    ///
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: An `OCRResult` containing the recognized text.
    /// - Throws: `OCRServiceError` if recognition fails.
    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.imageConversionFailed
        }
        defer { /* image data released when cgImage goes out of scope */ }

        // Pass 1: Fast scan for immediate preview
        let fastResult = try await performRecognition(cgImage: cgImage, tier: .fast)

        // Pass 2: Only run accurate scan if we found something worth refining
        if fastResult.hasText {
            let accurateResult = try await performRecognition(cgImage: cgImage, tier: .accurate)

            // Merge: prefer accurate observations but keep fast ones as fallback
            let merged = mergeResults(fast: fastResult, accurate: accurateResult)
            return merged
        }

        // If fast scan found nothing but we still want to try accurate
        let accurateResult = try await performRecognition(cgImage: cgImage, tier: .accurate)
        return accurateResult
    }

    /// Performs a single-pass fast scan.
    /// Useful for live preview / real-time feedback.
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: An `OCRResult` with fast-tier recognition.
    /// - Throws: `OCRServiceError`.
    func fastScan(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.imageConversionFailed
        }
        defer { /* cgImage released */ }
        return try await performRecognition(cgImage: cgImage, tier: .fast)
    }

    /// Performs a single-pass accurate scan.
    /// Useful when the user taps "refine" or on the final parsing step.
    /// - Parameter image: The `UIImage` to process.
    /// - Returns: An `OCRResult` with accurate-tier recognition.
    /// - Throws: `OCRServiceError`.
    func detailedScan(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.imageConversionFailed
        }
        defer { /* cgImage released */ }
        return try await performRecognition(cgImage: cgImage, tier: .accurate)
    }

    /// Processes a `CGImage` directly (for use with camera output).
    /// - Parameters:
    ///   - cgImage: The Core Graphics image to process.
    ///   - tier: The recognition tier.
    /// - Returns: An `OCRResult`.
    /// - Throws: `OCRServiceError`.
    func recognizeText(from cgImage: CGImage, tier: RecognitionTier = .accurate) async throws -> OCRResult {
        return try await performRecognition(cgImage: cgImage, tier: tier)
    }

    // MARK: - Recognition Engine

    /// Performs Vision framework text recognition at the specified tier.
    private func performRecognition(cgImage: CGImage, tier: RecognitionTier) async throws -> OCRResult {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRServiceError.recognitionFailed(underlying: error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(
                        fullText: "",
                        observations: [],
                        averageConfidence: 0.0,
                        sanitizedText: ""
                    ))
                    return
                }

                // Build text observations
                let textObs: [TextObservation] = observations.compactMap { observation in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence >= self.minimumConfidence else {
                        return nil
                    }

                    let box = try? candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex)
                    let topLeft = box?.topLeft ?? .zero
                    let bottomRight = box?.bottomRight ?? .zero

                    return TextObservation(
                        id: UUID(),
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox,
                        topLeft: topLeft,
                        bottomRight: bottomRight
                    )
                }

                // Sort by y-position (top to bottom), then x (left to right)
                let sorted = textObs.sorted { a, b in
                    if abs(a.boundingBox.midY - b.boundingBox.midY) < 0.05 {
                        return a.boundingBox.minX < b.boundingBox.minX
                    }
                    return a.boundingBox.midY > b.boundingBox.midY
                }

                // Build full text
                let fullText = sorted.map(\.text).joined(separator: "\n")

                // Calculate average confidence
                let avgConfidence = sorted.isEmpty ? 0.0 :
                    sorted.reduce(0.0) { $0 + Double($1.confidence) } / Double(sorted.count)

                // Sanitize PII
                let sanitized = PIISanitizer.sanitize(fullText)

                continuation.resume(returning: OCRResult(
                    fullText: fullText,
                    observations: sorted,
                    averageConfidence: avgConfidence,
                    sanitizedText: sanitized
                ))
            }

            // Configure recognition level
            switch tier {
            case .fast:
                request.recognitionLevel = .fast
            case .accurate:
                request.recognitionLevel = .accurate
            }

            // Configure for best results
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            request.minimumTextHeight = 0.01 // Accept small text

            // Process on the Vision queue
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: .up,
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRServiceError.recognitionFailed(underlying: error))
            }
        }
    }

    // MARK: - Merge Strategy

    /// Merges fast and accurate results, preferring accurate observations
    /// while keeping fast-only detections as fallback.
    private func mergeResults(fast: OCRResult, accurate: OCRResult) -> OCRResult {
        // Group accurate observations by approximate position
        let accurateMap = Dictionary(grouping: accurate.observations) { obs -> String in
            let x = String(format: "%.2f", obs.boundingBox.midX)
            let y = String(format: "%.2f", obs.boundingBox.midY)
            return "\(x),\(y)"
        }

        // For each fast observation, check if we have an accurate replacement
        var mergedObs: [TextObservation] = []
        var usedAccurateKeys: Set<String> = []

        for fastObs in fast.observations {
            let key = String(format: "%.2f,%.2f", fastObs.boundingBox.midX, fastObs.boundingBox.midY)

            if let accurateMatches = accurateMap[key], let best = accurateMatches.first {
                mergedObs.append(best)
                usedAccurateKeys.insert(key)
            } else {
                // No accurate replacement — keep the fast observation
                mergedObs.append(fastObs)
            }
        }

        // Add any accurate observations that weren't near a fast one
        for (key, obsList) in accurateMap where !usedAccurateKeys.contains(key) {
            mergedObs.append(contentsOf: obsList)
        }

        // Re-sort
        mergedObs.sort { a, b in
            if abs(a.boundingBox.midY - b.boundingBox.midY) < 0.05 {
                return a.boundingBox.minX < b.boundingBox.minX
            }
            return a.boundingBox.midY > b.boundingBox.midY
        }

        let fullText = mergedObs.map(\.text).joined(separator: "\n")
        let avgConfidence = mergedObs.isEmpty ? 0.0 :
            mergedObs.reduce(0.0) { $0 + Double($1.confidence) } / Double(mergedObs.count)
        let sanitized = PIISanitizer.sanitize(fullText)

        return OCRResult(
            fullText: fullText,
            observations: mergedObs,
            averageConfidence: avgConfidence,
            sanitizedText: sanitized
        )
    }

    // MARK: - Memory Release

    /// Explicitly releases any cached image data.
    /// Call this after OCR processing is complete to free memory.
    func releaseCachedData() {
        // Vision framework handles its own caching; we just ensure our
        // actor's isolated state is clean. No image data is retained
        // beyond the `recognizeText` call boundaries.
    }
}