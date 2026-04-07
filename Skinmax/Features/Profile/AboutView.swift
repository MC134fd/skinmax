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
                            .font(.custom("Nunito-Bold", size: 36))
                            .foregroundStyle(.white)
                    )

                Text("Skinmax")
                    .font(SkinmaxFonts.h1())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Text("Version 1.0")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.mutedTan)

                // Description
                Text("Skinmax uses AI to analyze your skin health and track how your diet affects your skin. Scan your face daily, log your meals, and discover personalized insights.")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.warmGray)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .padding(SkinmaxSpacing.cardPadding)
                    .background(SkinmaxColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)

                // Links
                VStack(spacing: 0) {
                    linkRow(label: "Privacy Policy", icon: "lock.fill")
                    Divider().foregroundStyle(SkinmaxColors.lightTan)
                    linkRow(label: "Terms of Service", icon: "doc.text.fill")
                    Divider().foregroundStyle(SkinmaxColors.lightTan)
                    mailRow()
                }
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)

                Text("Made with ❤️ for better skin")
                    .font(SkinmaxFonts.caption())
                    .foregroundStyle(SkinmaxColors.mutedTan)
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
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundStyle(SkinmaxColors.darkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SkinmaxColors.mutedTan)
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
                    .font(.custom("Nunito-Regular", size: 14))
                    .foregroundStyle(SkinmaxColors.darkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
    }
}
