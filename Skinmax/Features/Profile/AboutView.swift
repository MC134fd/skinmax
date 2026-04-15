import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // App icon
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [SkinmaxColors.peachLight, SkinmaxColors.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("S")
                            .font(.gbDisplayL)
                            .foregroundStyle(.white)
                    )

                Text("Skinmax")
                    .font(.gbTitleL)
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Text("Version 1.0")
                    .font(.gbBodyM)
                    .foregroundStyle(SkinmaxColors.lightTaupe)

                // Description
                Text("Skinmax uses AI to analyze your skin health and track how your diet affects your skin. Scan your face daily, log your meals, and discover personalized insights.")
                    .font(.gbBodyM)
                    .foregroundStyle(SkinmaxColors.warmBrown)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .padding(SkinmaxSpacing.cardPadding)
                    .background(SkinmaxColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
                    .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)

                // Links
                VStack(spacing: 0) {
                    linkRow(label: "Privacy Policy", icon: "lock.fill")
                    Divider().foregroundStyle(SkinmaxColors.softTan)
                    linkRow(label: "Terms of Service", icon: "doc.text.fill")
                    Divider().foregroundStyle(SkinmaxColors.softTan)
                    mailRow()
                }
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)

                Text("Made with ❤️ for better skin")
                    .font(.gbCaption)
                    .foregroundStyle(SkinmaxColors.lightTaupe)
                    .padding(.top, 8)
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func linkRow(label: String, icon: String) -> some View {
        Button {
            // Placeholder URLs
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(SkinmaxColors.coral)
                    .frame(width: 24)
                Text(label)
                    .font(.gbBodyM)
                    .foregroundStyle(SkinmaxColors.darkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
    }

    private func mailRow() -> some View {
        Button {
            if let url = URL(string: "mailto:support@skinmax.app") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(SkinmaxColors.coral)
                    .frame(width: 24)
                Text("Contact Us")
                    .font(.gbBodyM)
                    .foregroundStyle(SkinmaxColors.darkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
    }
}
