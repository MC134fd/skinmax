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
    static let coral = Color(hex: "FF7A5C")
    static let peachLight = Color(hex: "FFB89E")
    static let peachWash = Color(hex: "FFD3B8")
    static let creamBG = Color(hex: "FAF6F2")
    static let sunnyButter = Color(hex: "FFF8E8")

    // MARK: - Supporting
    static let greenGood = Color(hex: "66BB6A")
    static let amberFair = Color(hex: "FFB74D")
    static let redAlert = Color(hex: "E57373")
    static let hydrationBlue = Color(hex: "81D4FA")

    // MARK: - Text
    static let darkBrown = Color(hex: "2B1F1A")
    static let warmBrown = Color(hex: "4B3D36")
    static let mediumTaupe = Color(hex: "6B5C54")
    static let lightTaupe = Color(hex: "9B8C85")
    static let softTan = Color(hex: "F0E8E4")
    static let white = Color.white

    // MARK: - Legacy Aliases (for gradual migration)
    static let warmGray: Color = warmBrown
    static let mutedTan: Color = lightTaupe
    static let lightTan: Color = softTan
    static let darkSurface: Color = darkBrown
    static let darkMid = Color(hex: "4B3D36")

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [coral, peachLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let buttonGradient = LinearGradient(
        colors: [coral, Color(hex: "FF9B7D")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Shadows (warm coral-tinted)
    static let cardShadowColor = Color(hex: "FF7A5C").opacity(0.10)
    static let elevatedShadowColor = Color(hex: "FF7A5C").opacity(0.15)
    static let buttonGlowColor = Color(hex: "FF7A5C").opacity(0.30)
    static let subtleShadowColor = Color(hex: "FF7A5C").opacity(0.06)

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
