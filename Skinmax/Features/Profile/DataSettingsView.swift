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
                        .foregroundStyle(SkinmaxColors.coral)
                    Text("Your data is stored for 90 days. Older data is automatically removed to keep the app fast.")
                        .font(SkinmaxFonts.body())
                        .foregroundStyle(SkinmaxColors.darkBrown)
                }
                .padding(14)
                .background(SkinmaxColors.peachWash)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Stats
                VStack(spacing: 0) {
                    statRow(label: "Skin Scans", value: "\(skinCount)")
                    Divider().foregroundStyle(SkinmaxColors.lightTan)
                    statRow(label: "Food Logs", value: "\(foodCount)")
                }
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)

                // Delete button
                Button {
                    showDeleteAlert = true
                } label: {
                    Text("Delete All Data")
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SkinmaxColors.redAlert)
                        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.buttonCornerRadius))
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.top, 16)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
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
                .font(.custom("Nunito-Regular", size: 14))
                .foregroundStyle(SkinmaxColors.darkBrown)
            Spacer()
            Text(value)
                .font(.custom("Nunito-SemiBold", size: 14))
                .foregroundStyle(SkinmaxColors.warmGray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
