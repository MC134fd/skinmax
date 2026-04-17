import SwiftUI

/// Lets the user pick between the two shipped app icons
/// (Scanner Classic — default, and Glow Aura — alternate).
struct AppearanceView: View {

    @State private var selected: AppIconManager.Option = AppIconManager.current
    @State private var errorMessage: String?
    @State private var showSavedToast = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header

                VStack(spacing: 14) {
                    ForEach(AppIconManager.Option.allCases) { option in
                        iconCard(for: option)
                    }
                }

                if !AppIconManager.supportsAlternateIcons {
                    unsupportedNote
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(GlowbiteColors.creamBG.ignoresSafeArea())
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showSavedToast {
                savedToast
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Couldn't switch icon",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            Text("Pick your vibe ✨")
                .font(.gbTitleL)
                .foregroundStyle(GlowbiteColors.darkBrown)
            Text("Switch your Glowbite icon anytime.")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.mediumTaupe)
        }
        .padding(.top, 8)
    }

    // MARK: - Icon Card
    private func iconCard(for option: AppIconManager.Option) -> some View {
        let isActive = selected == option
        return Button {
            pick(option)
        } label: {
            HStack(spacing: 16) {
                Image(option.previewAsset)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: GlowbiteColors.cardShadowColor, radius: 8, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.displayName)
                        .font(.gbTitleM)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                    Text(option.subtitle)
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.mediumTaupe)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isActive
                                      ? GlowbiteColors.coral
                                      : GlowbiteColors.softTan,
                                      lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isActive {
                        Circle()
                            .fill(GlowbiteColors.coral)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(16)
            .background(GlowbiteColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isActive ? GlowbiteColors.coral : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: GlowbiteColors.cardShadowColor,
                    radius: isActive ? 16 : 12,
                    x: 0,
                    y: isActive ? 6 : 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isActive)
    }

    // MARK: - Unsupported Note
    private var unsupportedNote: some View {
        Text("Your device doesn't support icon switching.")
            .font(.gbCaption)
            .foregroundStyle(GlowbiteColors.lightTaupe)
            .padding(.top, 8)
    }

    // MARK: - Saved Toast
    private var savedToast: some View {
        Text("Icon updated ✨")
            .font(.gbCaption)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(GlowbiteColors.coral)
            )
            .shadow(color: GlowbiteColors.cardShadowColor, radius: 10, x: 0, y: 4)
    }

    // MARK: - Actions
    private func pick(_ option: AppIconManager.Option) {
        guard option != selected else { return }
        HapticManager.impact(.medium)
        Task {
            do {
                try await AppIconManager.set(option)
                selected = option
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showSavedToast = true
                }
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                withAnimation { showSavedToast = false }
            } catch {
                errorMessage = error.localizedDescription
                HapticManager.notification(.error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
}
