import SwiftUI

enum SkinmaxFonts {
    static func h1() -> Font {
        .custom("Nunito-Bold", size: 22)
    }

    static func h2() -> Font {
        .custom("Nunito-SemiBold", size: 18)
    }

    static func h3() -> Font {
        .custom("Nunito-SemiBold", size: 14)
    }

    static func body() -> Font {
        .custom("Nunito-Regular", size: 13)
    }

    static func caption() -> Font {
        .custom("Nunito-Medium", size: 11)
    }

    static func small() -> Font {
        .custom("Nunito-Medium", size: 9)
    }

    static func scoreDisplay() -> Font {
        .custom("Nunito-Bold", size: 48)
    }

    static func tabLabel() -> Font {
        .custom("Nunito-SemiBold", size: 10)
    }
}

// MARK: - View Modifier for H1 letter spacing
struct H1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SkinmaxFonts.h1())
            .tracking(-0.3)
            .foregroundStyle(SkinmaxColors.darkBrown)
    }
}

extension View {
    func h1Style() -> some View {
        modifier(H1Style())
    }
}
