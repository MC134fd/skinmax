import SwiftUI

struct FoodLogView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var viewModel = FoodLogViewModel()
    @State private var showFoodLogSheet = false
    @State private var showFoodResult = false
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
        .sheet(isPresented: $showFoodLogSheet) {
            FoodLogSheet { result in
                selectedFoodScan = result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFoodResult = true
                }
            }
            .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $showFoodResult) {
            if let scan = selectedFoodScan {
                FoodScanResultView(scan: scan)
            }
        }
    }

    // MARK: - Title
    private var title: some View {
        Text("Food Log")
            .font(SkinmaxFonts.h2())
            .foregroundStyle(SkinmaxColors.darkBrown)
            .padding(.top, 12)
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
        let daysWithData = viewModel.daysWithData(in: viewModel.selectedMonth)

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

    // MARK: - Daily Summary
    private var dailySummary: some View {
        HStack {
            Text("\(viewModel.selectedDayName)'s average:")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.warmGray)

            if let avg = viewModel.averageScore {
                Text(String(format: "%.1f", avg))
                    .font(.custom("Nunito-SemiBold", size: 16))
                    .foregroundStyle(SkinmaxColors.trafficLight(for: avg * 10))
                Text("/10")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.mutedTan)
            } else {
                Text("No meals logged")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.mutedTan)
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
                            showFoodResult = true
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
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
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
