import Foundation
import CoreGraphics

/// Capture modes for the food scanner. Drives UI framing, coaching copy, and
/// which GPT-4o prompt variant the analysis service uses.
enum FoodCaptureMode: String, CaseIterable, Identifiable, Hashable {
    case photo
    case barcode
    case label

    var id: String { rawValue }

    /// Short label shown in the mode pill row.
    var shortTitle: String {
        switch self {
        case .photo: return "Photo"
        case .barcode: return "Barcode"
        case .label: return "Label"
        }
    }

    /// Coaching line shown just above the mode pill row.
    var coachingText: String {
        switch self {
        case .photo: return "Point at your meal ✨"
        case .barcode: return "Align the barcode 🔎"
        case .label: return "Frame the full label 🧾"
        }
    }

    /// Loading copy during analysis.
    var loadingText: String {
        switch self {
        case .photo: return "Reading your meal... ✨"
        case .barcode: return "Scanning the barcode 🔎"
        case .label: return "Reading the label 🧾"
        }
    }

    /// Aspect ratio (w / h) of the corner-bracket frame. Photo = wide; barcode
    /// emphasises horizontal; label is tall portrait.
    var bracketAspect: CGFloat {
        switch self {
        case .photo: return 1.0
        case .barcode: return 1.8
        case .label: return 0.62
        }
    }

    /// Width factor relative to preview width (0-1).
    var bracketWidthFactor: CGFloat {
        switch self {
        case .photo: return 0.78
        case .barcode: return 0.82
        case .label: return 0.70
        }
    }

    /// Fallback food name when user doesn't type one.
    var defaultFoodName: String {
        switch self {
        case .photo: return "Meal"
        case .barcode: return "Packaged product"
        case .label: return "Packaged food"
        }
    }
}
