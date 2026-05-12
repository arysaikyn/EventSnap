import Foundation

/// The method by which event text is obtained. Shared across the UI layer.
enum InputMode: String, CaseIterable, Identifiable {
    case camera
    case voice
    case text

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .camera: return "camera.viewfinder"
        case .voice: return "waveform"
        case .text: return "text.alignleft"
        }
    }

    var title: String {
        switch self {
        case .camera: return "Camera"
        case .voice: return "Voice"
        case .text: return "Text"
        }
    }

    /// Maps to the `InputType` used by the parsing layer.
    var asInputType: InputType {
        switch self {
        case .camera: return .camera
        case .voice: return .voice
        case .text: return .text
        }
    }
}