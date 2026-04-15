import SwiftUI

struct DataSettingsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var showDeleteAlert = false

    private var skinCount: Int { dataStore.totalSkinScans() }
    private var foodCount: Int { dataStore.totalFoodScans() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Info card
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(GlowbiteColors.coral)
                    Text("Your data is stored for 90 days. Older data is automatically removed to keep the app fast.")
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                }
                .padding(14)
                .background(GlowbiteColors.peachWash)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Stats
                VStack(spacing: 0) {
                    statRow(label: "Skin Scans", value: "\(skinCount)")
                    Divider().foregroundStyle(GlowbiteColors.softTan)
                    statRow(label: "Food Logs", value: "\(foodCount)")
                }
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)

                // Delete button
                Button {
                    showDeleteAlert = true
                } label: {
                    Text("Delete All Data")
                        .font(.gbBodyM)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(GlowbiteColors.redAlert)
                        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.buttonCornerRadius))
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.top, 16)
        }
        .background(GlowbiteColors.creamBG.ignoresSafeArea())
        .navigationTitle("Data & Storage")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataStore.deleteAllData()
                HapticManager.notification(.warning)
            }
        } message: {
            Text("This will permanently remove all scan history, food logs, and progress data. This cannot be undone.")
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)
            Spacer()
            Text(value)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.warmBrown)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
