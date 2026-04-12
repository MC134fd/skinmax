import SwiftUI

struct HomeView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var viewModel = HomeViewModel()
    @State private var selectedScanResult: SkinScan?

    var onViewFaceResult: (SkinScan) -> Void = { _ in }
    var onViewFoodResult: (FoodScan) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header

                // Analysis in progress card
                if coordinator.isActive {
                    AnalysisHomeCard(
                        coordinator: coordinator,
                        onViewFaceResult: onViewFaceResult,
                        onViewFoodResult: onViewFoodResult,
                        onDismiss: {
                            coordinator.dismiss()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                monthNavigation
                dayPicker

                if viewModel.hasDataForSelectedDate {
                    glowScoreCard
                    scanHistoryList
                } else {
                    emptyScoreCard
                }

                todayFoodSummary
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.bottom, 100)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.isActive)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .onAppear {
            viewModel.dataStore = dataStore
        }
        .fullScreenCover(item: $selectedScanResult) { scan in
            FaceScanResultView(scan: scan)
                .environment(dataStore)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("skinmax")
                .h1Style()

            Spacer()

            Circle()
                .fill(SkinmaxColors.peachLight)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("\u{1F469}")
                        .font(.system(size: 18))
                )
        }
        .padding(.top, 8)
    }

    // MARK: - Month Navigation
    private var monthNavigation: some View {
        HStack {
            Button { viewModel.previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Spacer()

            Button { viewModel.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }
        }
    }

    // MARK: - Day Picker
    private var dayPicker: some View {
        let daysWithData = viewModel.daysWithSkinData(in: viewModel.selectedMonth)

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.weekDays, id: \.self) { date in
                    let dayNum = Calendar.current.component(.day, from: date)
                    let hasData = daysWithData.contains(dayNum)
                    let isSelected = viewModel.isSelected(date)
                    let isToday = viewModel.isToday(date)
                    let isFuture = viewModel.isFuture(date)

                    Button {
                        viewModel.selectDay(date)
                    } label: {
                        VStack(spacing: 4) {
                            Text(viewModel.dayAbbreviation(date))
                                .font(SkinmaxFonts.small())

                            Text(viewModel.dayNumber(date))
                                .font(.custom("Nunito-SemiBold", size: 14))

                            Circle()
                                .fill(SkinmaxColors.coral)
                                .frame(width: 4, height: 4)
                                .opacity(hasData ? 1 : 0)
                        }
                        .foregroundStyle(
                            isSelected ? .white :
                            isFuture ? SkinmaxColors.mutedTan.opacity(0.5) :
                            SkinmaxColors.warmGray
                        )
                        .frame(width: 44, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? SkinmaxColors.coral : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isToday && !isSelected ? SkinmaxColors.lightTan : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .disabled(isFuture)
                }
            }
        }
    }

    // MARK: - Glow Score Card
    private var glowScoreCard: some View {
        ScoreCard(
            score: viewModel.glowScoreForSelectedDate ?? 0,
            label: "Glow Score",
            trend: viewModel.selectedDayName,
            trendPositive: true
        )
    }

    // MARK: - Empty Score Card
    private var emptyScoreCard: some View {
        VStack(spacing: 12) {
            Text("--")
                .font(SkinmaxFonts.scoreDisplay())
                .foregroundStyle(SkinmaxColors.mutedTan)

            Text("GLOW SCORE")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .tracking(1.5)

            Text("No scan for \(viewModel.selectedDayName.lowercased())")
                .font(SkinmaxFonts.small())
                .foregroundStyle(SkinmaxColors.coral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, SkinmaxSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [SkinmaxColors.darkSurface, SkinmaxColors.darkMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
    }

    // MARK: - Scan History List
    private var scanHistoryList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.skinScansForSelectedDate) { scan in
                ScanHistoryRow(scan: scan) {
                    selectedScanResult = scan
                }
            }
        }
    }

    // MARK: - Today Food Summary
    private var todayFoodSummary: some View {
        HStack {
            Text("\u{1F37D}")
                .font(.system(size: 16))

            if viewModel.todayFoodCount > 0 {
                Text("Today: \(viewModel.todayFoodCount) meal\(viewModel.todayFoodCount == 1 ? "" : "s") logged")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.warmGray)

                if viewModel.foodScore > 0 {
                    Text("avg \(String(format: "%.1f", viewModel.foodScore))/10")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.trafficLight(for: viewModel.foodScore * 10))
                }
            } else {
                Text("No meals logged today")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }

            Spacer()
        }
        .padding(12)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}
