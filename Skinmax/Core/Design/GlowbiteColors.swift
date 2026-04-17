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

enum GlowbiteColors {
    // MARK: - Primary
    static let coral = Color(hex: "C24A1E")
    static let peachLight = Color(hex: "C24A1E").opacity(0.15)
    static let peachWash = Color(hex: "F2ECE2")
    static let creamBG = Color(hex: "FAF6F0")
    static let sunnyButter = Color(hex: "FFF8E8")

    // MARK: - Supporting
    static let greenGood = Color(hex: "4A7C59")
    static let amberFair = Color(hex: "C49234")
    static let redAlert = Color(hex: "B23A2C")
    static let hydrationBlue = Color(hex: "4A7CB8")
    static let lavender = Color(hex: "CE93D8")
    static let purple = Color(hex: "8B5CF6")

    // MARK: - Text
    static let darkBrown = Color(hex: "1A1510")
    static let warmBrown = Color(hex: "4B3D36")
    static let mediumTaupe = Color(hex: "6B5C54")
    static let lightTaupe = Color(hex: "9A8E82")
    static let softTan = Color(hex: "F2ECE2")
    static let white = Color.white

    // MARK: - Semantic Aliases
    static let ink = darkBrown
    static let paper = Color.white
    static let stone = lightTaupe
    static let softBg = softTan
    static let accent = coral
    static let accentLight = coral.opacity(0.08)
    static let greenLight = greenGood.opacity(0.10)
    static let amberLight = amberFair.opacity(0.12)
    static let redLight = redAlert.opacity(0.10)
    static let blueLight = hydrationBlue.opacity(0.10)
    static let purpleLight = purple.opacity(0.10)
    static let border = Color(hex: "1A1510").opacity(0.08)

    // MARK: - Nutrient Signature Colors
    static let nutrientProtein = Color(hex: "C24A1E")
    static let nutrientProteinLight = Color(hex: "C24A1E").opacity(0.10)

    static let nutrientCarbs = Color(hex: "D4943A")
    static let nutrientCarbsLight = Color(hex: "D4943A").opacity(0.10)

    static let nutrientFat = Color(hex: "A68B6B")
    static let nutrientFatLight = Color(hex: "A68B6B").opacity(0.10)

    static let nutrientFiber = Color(hex: "66BB6A")
    static let nutrientFiberLight = Color(hex: "66BB6A").opacity(0.10)

    static let nutrientSugar = Color(hex: "E57373")
    static let nutrientSugarLight = Color(hex: "E57373").opacity(0.10)

    static let nutrientSodium = Color(hex: "5B9EC4")
    static let nutrientSodiumLight = Color(hex: "5B9EC4").opacity(0.10)

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [Color(hex: "C24A1E"), Color(hex: "C24A1E").opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "C24A1E"), Color(hex: "D4623A")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Shadows (accent-tinted)
    static let cardShadowColor = Color(hex: "C24A1E").opacity(0.08)
    static let elevatedShadowColor = Color(hex: "C24A1E").opacity(0.12)
    static let buttonGlowColor = Color(hex: "C24A1E").opacity(0.25)
    static let subtleShadowColor = Color(hex: "C24A1E").opacity(0.05)

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
