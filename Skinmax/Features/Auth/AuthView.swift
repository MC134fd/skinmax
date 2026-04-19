import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthService.self) private var authService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailSection = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer().frame(height: 40)

                heroSection

                signInButtons

                if showEmailSection {
                    emailSection
                }

                if let error = authService.authError {
                    errorBanner(error)
                }

                Spacer()

                termsFooter
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.bottom, 40)
        }
        .background(GlowbiteColors.creamBG.ignoresSafeArea())
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            GlowbiteLockup(variant: .caveat, iconSize: 48, gap: 10, wordmarkSize: 52)
                .padding(.bottom, 8)

            Text("Your skin's new best friend")
                .font(.gbBodyL)
                .foregroundStyle(GlowbiteColors.mediumTaupe)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Sign In Buttons

    private var signInButtons: some View {
        VStack(spacing: 12) {
            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                        Task {
                            await authService.signInWithApple(credential: credential)
                        }
                    }
                case .failure:
                    break
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.pillCornerRadius, style: .continuous))

            // Sign in with Google
            Button {
                HapticManager.impact(.medium)
                Task {
                    await authService.signInWithGoogle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "g.circle.fill")
                        .font(.gbBodyL)
                    Text("Continue with Google")
                        .font(.gbTitleM)
                }
                .foregroundStyle(GlowbiteColors.darkBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.pillCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: GlowbiteSpacing.pillCornerRadius, style: .continuous)
                        .stroke(GlowbiteColors.border, lineWidth: 1)
                )
            }

            // Email toggle
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showEmailSection.toggle()
                }
                HapticManager.impact(.light)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.gbBodyM)
                    Text("Continue with Email")
                        .font(.gbTitleM)
                }
                .foregroundStyle(GlowbiteColors.darkBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.pillCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: GlowbiteSpacing.pillCornerRadius, style: .continuous)
                        .stroke(GlowbiteColors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Email Section

    private var emailSection: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .font(.gbBodyM)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.inputFieldRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: GlowbiteSpacing.inputFieldRadius, style: .continuous)
                        .stroke(GlowbiteColors.border, lineWidth: 1)
                )

            SecureField("Password", text: $password)
                .font(.gbBodyM)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding(14)
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.inputFieldRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: GlowbiteSpacing.inputFieldRadius, style: .continuous)
                        .stroke(GlowbiteColors.border, lineWidth: 1)
                )

            // Submit button
            Button {
                HapticManager.impact(.medium)
                Task {
                    if isSignUp {
                        await authService.signUpWithEmail(email: email, password: password)
                    } else {
                        await authService.signInWithEmail(email: email, password: password)
                    }
                }
            } label: {
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(.gbTitleM)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        GlowbiteColors.buttonGradient
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.pillCornerRadius, style: .continuous))
                    .shadow(color: GlowbiteColors.buttonGlowColor, radius: 16, x: 0, y: 6)
            }
            .disabled(email.isEmpty || password.isEmpty)
            .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

            // Toggle sign in / sign up
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isSignUp.toggle()
                    authService.authError = nil
                }
            } label: {
                Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Create one**")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.mediumTaupe)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(GlowbiteColors.redAlert)
            Text(message)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.warmBrown)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowbiteColors.redAlert.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Footer

    private var termsFooter: some View {
        Text("By continuing, you agree to our Terms & Privacy Policy")
            .font(.gbCaption)
            .foregroundStyle(GlowbiteColors.lightTaupe)
            .multilineTextAlignment(.center)
    }
}
