import SwiftUI

struct FoodLogView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var viewModel = FoodLogViewModel()
    @State private var showFoodLogSheet = false
    @State private var selectedFoodScan: FoodScan?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    title
                    monthNavigation
                    dayPicker
                    dailySummary
                    foodList
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 100)
            }

            // Floating add button
            floatingAddButton
        }
        .onAppear {
            viewModel.dataStore = dataStore
        }
        .fullScreenCover(isPresented: $showFoodLogSheet) {
            FoodLogSheet()
                .environment(dataStore)
        }
        .fullScreenCover(item: $selectedFoodScan) { scan in
            FoodScanResultView(scan: scan)
                .environment(dataStore)
        }
    }

    // MARK: - Title
    private var title: some View {
        Text("Food Log")
            .font(.gbTitleM)
            .foregroundStyle(SkinmaxColors.darkBrown)
            .padding(.top, 12)
    }

    // MARK: - Month Navigation
    private var monthNavigation: some View {
        HStack {
            Button { viewModel.previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Spacer()

            Button { viewModel.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }
        }
    }

    // MARK: - Day Picker
    private var dayPicker: some View {
        WeekDayStrip(
            weeks: viewModel.allWeeks,
            currentWeekIndex: viewModel.currentWeekIndex,
            selectedDate: viewModel.selectedDate,
            daysWithData: viewModel.daysWithData(),
            onSelectDay: { date in
                viewModel.selectDay(date)
            },
            onPageChanged: { date in
                viewModel.selectedMonth = date
            }
        )
    }

    // MARK: - Daily Summary
    private var dailySummary: some View {
        HStack {
            Text("\(viewModel.selectedDayName)'s average:")
                .font(.gbBodyM)
                .foregroundStyle(SkinmaxColors.warmBrown)

            if let avg = viewModel.averageScore {
                Text(String(format: "%.1f", avg))
                    .font(.gbBodyL)
                    .foregroundStyle(SkinmaxColors.trafficLight(for: avg * 10))
                Text("/10")
                    .font(.gbBodyM)
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            } else {
                Text("No meals logged")
                    .font(.gbBodyM)
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }

            Spacer()
        }
    }

    // MARK: - Food List
    private var foodList: some View {
        Group {
            let scans = viewModel.foodScansForSelectedDate
            if scans.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(scans) { scan in
                        Button {
                            selectedFoodScan = scan
                        } label: {
                            FoodRowView(foodScan: scan)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)

            Text("🍽")
                .font(.system(size: 40))

            Text("No meals logged")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Text("Tap the + button to log your first meal")
                .font(.gbBodyM)
                .foregroundStyle(SkinmaxColors.lightTaupe)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Button {
            showFoodLogSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(SkinmaxColors.coral)
                .clipShape(Circle())
                .shadow(color: SkinmaxColors.coral.opacity(0.3), radius: 6, x: 0, y: 4)
        }
        .padding(.trailing, SkinmaxSpacing.screenPadding)
        .padding(.bottom, 90)
    }
}
