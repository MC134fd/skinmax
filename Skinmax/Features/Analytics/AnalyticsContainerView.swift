import SwiftUI

struct AnalyticsContainerView: View {
    @State private var selectedTab: AnalyticsTab = .foodLog

    enum AnalyticsTab: String, CaseIterable {
        case foodLog = "Food Log"
        case trends = "Trends"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented picker
            HStack(spacing: 0) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.custom("Nunito-SemiBold", size: 13))
                            .foregroundStyle(selectedTab == tab ? .white : SkinmaxColors.darkBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedTab == tab
                                    ? SkinmaxColors.coral
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(4)
            .background(SkinmaxColors.lightTan)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.top, 8)

            // Content
            Group {
                switch selectedTab {
                case .foodLog:
                    FoodLogView()
                case .trends:
                    TrendsView()
                }
            }
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
    }
}
