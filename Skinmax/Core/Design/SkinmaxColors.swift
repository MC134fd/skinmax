import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

enum SkinmaxColors {
    // MARK: - Primary
    static let coral = Color(hex: "E8A08A")
    static let peachLight = Color(hex: "F4C7B0")
    static let peachWash = Color(hex: "FCEEE8")
    static let creamBG = Color(hex: "FDF8F5")

    // MARK: - Neutral
    static let darkBrown = Color(hex: "3A2A24")
    static let warmGray = Color(hex: "7A6A64")
    static let mutedTan = Color(hex: "B09A92")
    static let lightTan = Color(hex: "F0E8E4")
    static let white = Color.white

    // MARK: - Metric Accents
    static let hydrationBlue = Color(hex: "81D4FA")
    static let greenGood = Color(hex: "66BB6A")
    static let amberFair = Color(hex: "FFB74D")
    static let redAlert = Color(hex: "E57373")

    // MARK: - Dark Surfaces
    static let darkSurface = Color(hex: "3A2A24")
    static let darkMid = Color(hex: "5A4A44")

    // MARK: - Traffic Light
    static func trafficLight(for score: Double) -> Color {
        switch score {
        case 70...100: return greenGood
        case 40..<70: return amberFair
        default: return redAlert
        }
    }

    static func trafficLightLabel(for score: Double) -> String {
        switch score {
        case 70...100: return "Good"
        case 40..<70: return "Fair"
        default: return "Needs work"
        }
    }
}
