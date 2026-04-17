import Foundation
import UIKit

/// Manages the app icon the user currently sees on their home screen.
///
/// Glowbite ships two icons:
///   • Scanner Classic — the default icon (uses the primary AppIcon asset)
///   • Glow Aura — an alternate icon keyed as "GlowAura" in Info.plist
///
/// The alternate icon files (AppIcon-Glow@2x.png / AppIcon-Glow@3x.png) live as
/// loose PNGs inside the app bundle — iOS requires that for alternate icons,
/// they cannot live inside an .xcassets catalog.
@MainActor
enum AppIconManager {

    /// All selectable icon options in Glowbite.
    enum Option: String, CaseIterable, Identifiable {
        case classic = "Classic"   // nil alternateIconName = primary AppIcon
        case glow    = "GlowAura"  // must match Info.plist CFBundleAlternateIcons key

        var id: String { rawValue }

        /// User-facing display name.
        var displayName: String {
            switch self {
            case .classic: return "Scanner Classic"
            case .glow:    return "Glow Aura"
            }
        }

        /// Short description shown under the preview.
        var subtitle: String {
            switch self {
            case .classic: return "Warm peach + sparkles"
            case .glow:    return "Radiant halo glow"
            }
        }

        /// Asset name for the in-app preview tile (from Assets.xcassets).
        var previewAsset: String {
            switch self {
            case .classic: return "IconClassic"
            case .glow:    return "IconGlow"
            }
        }

        /// Value to pass to UIApplication.setAlternateIconName —
        /// nil restores the primary icon.
        var alternateIconName: String? {
            switch self {
            case .classic: return nil
            case .glow:    return "GlowAura"
            }
        }
    }

    /// Whether the device supports alternate icons at all.
    /// Returns false on iPad multitasking or unusual configurations.
    static var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    /// The currently active icon option.
    static var current: Option {
        if let name = UIApplication.shared.alternateIconName,
           let match = Option.allCases.first(where: { $0.alternateIconName == name }) {
            return match
        }
        return .classic
    }

    /// Switch to the chosen icon. iOS shows a native confirmation alert automatically
    /// on first install (in iOS 15+ you can suppress it with a private API — we don't).
    static func set(_ option: Option) async throws {
        guard supportsAlternateIcons else { return }
        // No-op if already selected
        if current == option { return }
        try await UIApplication.shared.setAlternateIconName(option.alternateIconName)
        HapticManager.notification(.success)
    }
}
