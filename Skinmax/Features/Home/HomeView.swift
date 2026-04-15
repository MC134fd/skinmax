import SwiftUI

struct HomeView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var viewModel = HomeViewModel()
    @State private var selectedScanResult: SkinScan?
    @State private var selectedFoodResult: FoodScan?

    var onViewFaceResult: (SkinScan) -> Void = { _ in }
    var onViewFoodResult: (FoodScan) -> Void = { _ in }
    var onScanMeal: () -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                topBar

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
                weekStrip

                heroRow
                skinNutrientsSection
                mealsSection
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.bottom, 100)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: coordinator.isActive)
        }
        .background(GlowbiteColors.creamBG.ignoresSafeArea())
        .onAppear {
            viewModel.dataStore = dataStore
        }
        .fullScreenCover(item: $selectedScanResult) { scan in
            FaceScanResultView(scan: scan)
                .environment(dataStore)
        }
        .fullScreenCover(item: $selectedFoodResult) { scan in
            FoodScanResultView(scan: scan)
                .environment(dataStore)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                Text(greetingText)
                    .font(.gbTitleL)
                    .tracking(-0.3)
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("🔥")
                    .font(.gbCaption)
                Text("\(viewModel.streak)")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(GlowbiteColors.paper)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(GlowbiteColors.border, lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button { viewModel.previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Spacer()

            Button { viewModel.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        WeekDayStrip(
            weeks: viewModel.allWeeks,
            currentWeekIndex: viewModel.currentWeekIndex,
            selectedDate: viewModel.selectedDate,
            daysWithData: viewModel.daysWithSkinData(),
            onSelectDay: { date in
                viewModel.selectDay(date)
            },
            onPageChanged: { date in
                viewModel.selectedMonth = date
            }
        )
    }

    // MARK: - Hero Row (2:1 split)

    private var heroRow: some View {
        GeometryReader { geo in
            let rightWidth = (geo.size.width - 8) / 3
            let leftWidth = geo.size.width - rightWidth - 8

            HStack(spacing: 8) {
                CalorieRingCard(
                    consumed: viewModel.consumedCalories,
                    goal: viewModel.dailyCalorieGoal
                )
                .frame(width: leftWidth, height: geo.size.height)

                VStack(spacing: 8) {
                    GlowScoreTile(
                        scan: viewModel.latestScan,
                        trendDiff: viewModel.glowTrendDiff
                    )

                    HydrationTile(
                        consumed: viewModel.hydration.consumed,
                        goal: viewModel.hydration.goal,
                        glasses: viewModel.hydration.glasses
                    )
                }
                .frame(width: rightWidth, height: geo.size.height)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Skin Nutrients

    private var skinNutrientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SKIN NUTRIENTS")
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                Spacer()

                Text("SWIPE →")
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(HomeViewModel.skinNutrients) { nutrient in
                        SkinNutrientCard(
                            label: nutrient.label,
                            value: nutrient.value,
                            target: nutrient.target,
                            descriptor: nutrient.descriptor,
                            color: nutrient.color,
                            lightColor: nutrient.lightColor,
                            progress: nutrient.progress
                        )
                    }
                }
            }
        }
    }

    // MARK: - Today's Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let meals = viewModel.todayFoodScans.sorted { $0.createdAt < $1.createdAt }

            Text("TODAY · \(meals.count) MEALS")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            if meals.isEmpty {
                mealsEmptyState
            } else {
                VStack(spacing: 5) {
                    ForEach(meals) { meal in
                        Button {
                            selectedFoodResult = meal
                        } label: {
                            MealRow(foodScan: meal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var mealsEmptyState: some View {
        VStack(spacing: 10) {
            Text("No meals logged yet")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            Button {
                onScanMeal()
            } label: {
                Text("Scan your first meal")
                    .font(.gbCaption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(GlowbiteColors.coral)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GlowbiteSpacing.lg)
        .background(GlowbiteColors.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    GlowbiteColors.lightTaupe.opacity(0.30),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 3])
                )
        )
    }
}
