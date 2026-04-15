import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // App icon
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [GlowbiteColors.peachLight, GlowbiteColors.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("G")
                            .font(.gbDisplayL)
                            .tracking(-1.0)
                            .foregroundStyle(.white)
                    )

                Text("Glowbite")
                    .font(.gbTitleL)
                    .tracking(-0.3)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text("Version 1.0")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                // Description
                Text("Glowbite uses AI to analyze your skin health and track how your diet affects your skin. Scan your face daily, log your meals, and discover personalized insights.")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .padding(GlowbiteSpacing.cardPadding)
                    .background(GlowbiteColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
                    .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)

                // Links
                VStack(spacing: 0) {
                    linkRow(label: "Privacy Policy", icon: "lock.fill")
                    Divider().foregroundStyle(GlowbiteColors.softTan)
                    linkRow(label: "Terms of Service", icon: "doc.text.fill")
                    Divider().foregroundStyle(GlowbiteColors.softTan)
                    mailRow()
                }
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)

                Text("Made with ❤️ for better skin")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
                    .padding(.top, 8)
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(GlowbiteColors.creamBG.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linkRow(label: String, icon: String) -> some View {
        Button {
            // Placeholder URLs
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.gbBodyL)
                    .foregroundStyle(GlowbiteColors.coral)
                    .frame(width: 24)
                Text(label)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
    }

    private func mailRow() -> some View {
        Button {
            if let url = URL(string: "mailto:support@glowbite.app") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.gbBodyL)
                    .foregroundStyle(GlowbiteColors.coral)
                    .frame(width: 24)
                Text("Contact Us")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
    }
}
