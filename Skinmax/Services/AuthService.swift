import SwiftUI
import Supabase
import AuthenticationServices
import GoogleSignIn

@Observable
@MainActor
final class AuthService {
    var isAuthenticated = false
    var isLoading = true
    var authError: String?
    var currentUserName: String = ""
    var currentUserEmail: String = ""
    var currentUserAvatarURL: String?
    var currentUserId: UUID?

    private let supabase = SupabaseManager.shared
    private var authStateTask: Task<Void, Never>?

    init() {
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in self.supabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session {
                        self.handleSession(session)
                    } else {
                        self.isAuthenticated = false
                    }
                    self.isLoading = false
                case .signedIn:
                    if let session {
                        self.handleSession(session)
                    }
                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUserId = nil
                    self.currentUserName = ""
                    self.currentUserEmail = ""
                    self.currentUserAvatarURL = nil
                default:
                    break
                }
            }
        }
    }

    nonisolated deinit {
    }

    // MARK: - Session

    private func handleSession(_ session: Session) {
        let user = session.user
        isAuthenticated = true
        currentUserId = user.id
        currentUserEmail = user.email ?? ""

        let meta = user.userMetadata
        currentUserName = meta.stringFor("full_name")
            ?? meta.stringFor("name")
            ?? user.email?.components(separatedBy: "@").first
            ?? ""
        currentUserAvatarURL = meta.stringFor("avatar_url")
            ?? meta.stringFor("picture")

        // Debug: log what metadata keys we actually got
        let keys = meta.keys.joined(separator: ", ")
        print("[AuthService] user metadata keys: \(keys)")
        print("[AuthService] avatarURL: \(currentUserAvatarURL ?? "nil")")
    }

    // MARK: - Sign In with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        authError = nil
        isLoading = true
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            authError = "Couldn't read Apple credential"
            return
        }

        do {
            try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign In with Google

    func signInWithGoogle() async {
        authError = nil
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            authError = "Couldn't find window for Google Sign-In"
            return
        }

        do {
            let config = GIDConfiguration(clientID: Config.googleClientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                authError = "Couldn't get Google ID token"
                return
            }

            try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign In with Email

    func signInWithEmail(email: String, password: String) async {
        authError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signIn(email: email, password: password)
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Up with Email

    func signUpWithEmail(email: String, password: String) async {
        authError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signUp(email: email, password: password)
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async {
        authError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            // Delete all user data via server function
            try await supabase.rpc("delete_user_data").execute()
            // Sign out (Supabase doesn't allow client-side user deletion,
            // the user record stays but all data is gone and they can't sign back in
            // without re-creating. For full deletion, use a Supabase Edge Function.)
            try await supabase.auth.signOut()
        } catch {
            authError = error.localizedDescription
        }
    }
}

// MARK: - Metadata Helper

private extension [String: AnyJSON] {
    func stringFor(_ key: String) -> String? {
        guard let value = self[key] else { return nil }
        switch value {
        case .string(let s): return s.isEmpty ? nil : s
        default:
            // Fallback: try description in case it's wrapped differently
            let desc = String(describing: value)
            return desc.isEmpty || desc == "null" ? nil : desc
        }
    }
}
