import SwiftUI

// Legacy font helpers — prefer .gb* extensions from Typography.swift
enum SkinmaxFonts {
    static func h1() -> Font { .gbTitleL }
    static func h2() -> Font { .gbTitleM }
    static func h3() -> Font { .custom("Nunito-SemiBold", size: 14) }
    static func body() -> Font { .gbBodyM }
    static func caption() -> Font { .gbCaption }
    static func small() -> Font { .gbOverline }
    static func scoreDisplay() -> Font { .gbDisplayXL }
    static func tabLabel() -> Font { .gbCaption }
}

// MARK: - View Modifier for H1 letter spacing
struct H1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.gbTitleL)
            .tracking(-0.3)
            .foregroundStyle(SkinmaxColors.darkBrown)
    }
}

extension View {
    func h1Style() -> some View {
        modifier(H1Style())
    }
}
