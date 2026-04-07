import SwiftUI
import StoreKit

struct AccountView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var showProgress = false
    @State private var showHistory = false
    @State private var showNotifications = false
    @State private var showDataSettings = false
    @State private var showAbout = false

    private var streak: Int { dataStore.calculateStreak() }
    private var totalScans: Int { dataStore.totalSkinScans() }
    private var totalMeals: Int { dataStore.totalFoodScans() }

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
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 100)
            }
            .background(SkinmaxColors.creamBG.ignoresSafeArea())
            .navigationDestination(isPresented: $showProgress) { ProgressView_() }
            .navigationDestination(isPresented: $showHistory) { ScanHistoryView() }
            .navigationDestination(isPresented: $showNotifications) { NotificationSettingsView() }
            .navigationDestination(isPresented: $showDataSettings) { DataSettingsView() }
            .navigationDestination(isPresented: $showAbout) { AboutView() }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(SkinmaxColors.peachLight)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("U")
                        .font(.custom("Nunito-Bold", size: 28))
                        .foregroundStyle(.white)
                )

            Text("User")
                .font(SkinmaxFonts.h2())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Text("Member since \(memberSince)")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)

            if streak > 0 {
                Text("🔥 \(streak) day streak")
                    .font(.custom("Nunito-SemiBold", size: 13))
                    .foregroundStyle(SkinmaxColors.coral)
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
                .font(.custom("Nunito-Bold", size: 20))
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text(label)
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Menu List
    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(icon: "camera.fill", label: "Progress Photos") { showProgress = true }
            Divider().foregroundStyle(SkinmaxColors.lightTan)
            menuRow(icon: "list.bullet", label: "Scan History") { showHistory = true }
            Divider().foregroundStyle(SkinmaxColors.lightTan)
            menuRow(icon: "bell.fill", label: "Notifications") { showNotifications = true }
            Divider().foregroundStyle(SkinmaxColors.lightTan)
            menuRow(icon: "externaldrive.fill", label: "Data & Storage") { showDataSettings = true }
            Divider().foregroundStyle(SkinmaxColors.lightTan)
            menuRow(icon: "info.circle.fill", label: "About Skinmax") { showAbout = true }
            Divider().foregroundStyle(SkinmaxColors.lightTan)
            menuRow(icon: "star.fill", label: "Rate the App") {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
        }
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private func menuRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
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
            .frame(height: 56)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        VStack(spacing: 4) {
            Text("Skinmax v1.0")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
            Text("Data stored for 90 days")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .padding(.top, 8)
    }
}
