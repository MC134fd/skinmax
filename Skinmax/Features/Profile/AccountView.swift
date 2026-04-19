import SwiftUI
import StoreKit
import Kingfisher

struct AccountView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AuthService.self) private var authService
    @State private var showProgress = false
    @State private var showHistory = false
    @State private var showNotifications = false
    @State private var showDataSettings = false
    @State private var showAbout = false
    @State private var showAppearance = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false

    private var streak: Int { dataStore.calculateStreak() }
    private var totalScans: Int { dataStore.totalSkinScans() }
    private var totalMeals: Int { dataStore.totalFoodScans() }

    private var userInitial: String {
        let name = authService.currentUserName
        if let first = name.first { return String(first).uppercased() }
        if let first = authService.currentUserEmail.first { return String(first).uppercased() }
        return "U"
    }

    private var memberSince: String {
        guard let date = dataStore.firstActivityDate() else { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileHeader
                    statsRow
                    menuList
                    footer
                }
                .padding(.horizontal, GlowbiteSpacing.screenPadding)
                .padding(.bottom, 120)
            }
            .background(GlowbiteColors.creamBG.ignoresSafeArea())
            .navigationDestination(isPresented: $showProgress) { ProgressView_() }
            .navigationDestination(isPresented: $showHistory) { ScanHistoryView() }
            .navigationDestination(isPresented: $showNotifications) { NotificationSettingsView() }
            .navigationDestination(isPresented: $showDataSettings) { DataSettingsView() }
            .navigationDestination(isPresented: $showAbout) { AboutView() }
            .navigationDestination(isPresented: $showAppearance) { AppearanceView() }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 8) {
            if let avatarURLString = authService.currentUserAvatarURL,
               let avatarURL = URL(string: avatarURLString) {
                KFImage(avatarURL)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(GlowbiteColors.peachLight)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(userInitial)
                            .font(.gbDisplayM)
                            .tracking(-0.5)
                            .foregroundStyle(.white)
                    )
            }

            Text(authService.currentUserName.isEmpty ? "User" : authService.currentUserName)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            if !authService.currentUserEmail.isEmpty {
                Text(authService.currentUserEmail)
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.mediumTaupe)
            }

            Text("Member since \(memberSince)")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            if streak > 0 {
                Text("🔥 \(streak) day streak")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.coral)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalScans)", label: "Scans")
            statCard(value: "\(totalMeals)", label: "Meals")
            statCard(value: "🔥 \(streak)", label: "Streak")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.gbTitleL)
                .tracking(-0.3)
                .foregroundStyle(GlowbiteColors.darkBrown)
            Text(label)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Menu List
    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(icon: "camera.fill", label: "Progress Photos") { showProgress = true }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "list.bullet", label: "Scan History") { showHistory = true }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "bell.fill", label: "Notifications") { showNotifications = true }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "sparkles", label: "App Icon") { showAppearance = true }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "externaldrive.fill", label: "Data & Storage") { showDataSettings = true }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "info.circle.fill", label: "About Glowbite") { showAbout = true }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "star.fill", label: "Rate the App") {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    AppStore.requestReview(in: scene)
                }
            }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            menuRow(icon: "rectangle.portrait.and.arrow.right", label: "Sign Out") {
                HapticManager.impact(.medium)
                showSignOutConfirm = true
            }
            Divider().foregroundStyle(GlowbiteColors.softTan)
            Button {
                HapticManager.impact(.heavy)
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.gbTitleM)
                        .foregroundStyle(GlowbiteColors.redAlert)
                        .frame(width: 24)
                    Text("Delete Account")
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.redAlert)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
            }
        }
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    dataStore.deleteAllData()
                    await authService.signOut()
                }
            }
        } message: {
            Text("Your data stays safe in the cloud. You can sign back in anytime.")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                Task {
                    dataStore.deleteAllData()
                    await authService.deleteAccount()
                }
            }
        } message: {
            Text("This permanently deletes all your scans, photos, and account data. This cannot be undone.")
        }
    }

    private func menuRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.gbTitleM)
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
            .frame(height: 56)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: 4) {
            Text("Glowbite v1.0")
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
            Text("Synced to cloud")
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
        .padding(.top, 8)
    }
}
