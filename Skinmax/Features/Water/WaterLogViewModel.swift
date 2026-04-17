import Foundation
import Observation

@Observable
@MainActor
final class WaterLogViewModel {
    var unit: WaterUnit
    var alreadyConsumedMl: Double
    var pendingMl: Double = 0
    var pourHistory: [Double] = []
    var showCustom: Bool = false
    var customInput: String = ""

    let goalMl: Double

    init(alreadyConsumedMl: Double = 0, goalMl: Double = 2_000, unit: WaterUnit = .defaultForLocale) {
        self.alreadyConsumedMl = alreadyConsumedMl
        self.goalMl = goalMl
        self.unit = unit
    }

    var projectedTotalMl: Double {
        alreadyConsumedMl + pendingMl
    }

    var projectedRatio: Double {
        guard goalMl > 0 else { return 0 }
        return min(projectedTotalMl / goalMl, 1.0)
    }

    var canLog: Bool {
        pendingMl > 0
    }

    var centerNumber: String {
        switch unit {
        case .ml:
            return "\(Int(projectedTotalMl.rounded()))"
        case .oz:
            let oz = projectedTotalMl / WaterUnit.mlPerOz
            if oz >= 10 {
                return "\(Int(oz.rounded()))"
            } else {
                return String(format: "%.1f", oz)
            }
        }
    }

    var centerUnit: String {
        unit.shortLabel.uppercased()
    }

    var progressSubtitle: String {
        let pct = Int((projectedRatio * 100).rounded())
        if pct >= 100 { return "GOAL HIT 🎉" }
        return "\(pct)% OF GOAL"
    }

    var goalLabel: String {
        switch unit {
        case .ml: return "of \(Int(goalMl)) ml goal"
        case .oz: return "of 64 oz goal"
        }
    }

    func addPreset(_ preset: WaterPreset) {
        let ml = preset.amountInMl
        pendingMl += ml
        pourHistory.append(ml)
        HapticManager.impact(.light)
    }

    func addCustomAmount() {
        let trimmed = customInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value > 0 else { return }
        let ml = unit.mlFromDisplay(value)
        pendingMl += ml
        pourHistory.append(ml)
        customInput = ""
        showCustom = false
        HapticManager.impact(.light)
    }

    func undoLastPour() {
        guard let last = pourHistory.popLast() else { return }
        pendingMl = max(pendingMl - last, 0)
        HapticManager.notification(.warning)
    }

    func toggleUnit(_ newUnit: WaterUnit) {
        guard newUnit != unit else { return }
        unit = newUnit
        HapticManager.selection()
    }

    func reset() {
        pendingMl = 0
        pourHistory.removeAll()
        customInput = ""
        showCustom = false
    }
}
