import Foundation

enum WaterUnit: String, CaseIterable, Identifiable {
    case ml
    case oz

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .ml: return "ml"
        case .oz: return "oz"
        }
    }

    var goalMl: Double {
        switch self {
        case .ml: return 2_000
        case .oz: return 64 * Self.mlPerOz
        }
    }

    var goalDisplay: Double {
        switch self {
        case .ml: return 2_000
        case .oz: return 64
        }
    }

    var presets: [WaterPreset] {
        switch self {
        case .ml:
            return [
                WaterPreset(emoji: "💧", name: "Sip",    displayAmount: 100, unit: .ml),
                WaterPreset(emoji: "🥛", name: "Glass",  displayAmount: 250, unit: .ml),
                WaterPreset(emoji: "🍼", name: "Bottle", displayAmount: 500, unit: .ml),
                WaterPreset(emoji: "🍶", name: "Large",  displayAmount: 750, unit: .ml)
            ]
        case .oz:
            return [
                WaterPreset(emoji: "💧", name: "Sip",    displayAmount: 3,  unit: .oz),
                WaterPreset(emoji: "🥛", name: "Glass",  displayAmount: 8,  unit: .oz),
                WaterPreset(emoji: "🍼", name: "Bottle", displayAmount: 16, unit: .oz),
                WaterPreset(emoji: "🍶", name: "Large",  displayAmount: 24, unit: .oz)
            ]
        }
    }

    static let mlPerOz: Double = 29.5735

    static var defaultForLocale: WaterUnit {
        if #available(iOS 16, *) {
            return Locale.current.measurementSystem == .us ? .oz : .ml
        } else {
            return (Locale.current.usesMetricSystem == false) ? .oz : .ml
        }
    }

    func displayFromMl(_ ml: Double) -> Double {
        switch self {
        case .ml: return ml
        case .oz: return ml / Self.mlPerOz
        }
    }

    func mlFromDisplay(_ display: Double) -> Double {
        switch self {
        case .ml: return display
        case .oz: return display * Self.mlPerOz
        }
    }

    func formatted(ml: Double) -> String {
        switch self {
        case .ml:
            let rounded = Int(ml.rounded())
            return "\(rounded) ml"
        case .oz:
            let oz = ml / Self.mlPerOz
            if oz >= 10 {
                return "\(Int(oz.rounded())) oz"
            } else {
                return String(format: "%.1f oz", oz)
            }
        }
    }
}

struct WaterPreset: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let displayAmount: Double
    let unit: WaterUnit

    var amountInMl: Double {
        unit.mlFromDisplay(displayAmount)
    }

    var amountLabel: String {
        switch unit {
        case .ml: return "\(Int(displayAmount)) ml"
        case .oz: return "\(Int(displayAmount)) oz"
        }
    }
}
