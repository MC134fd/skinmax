import SwiftUI

struct HomeView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var viewModel = HomeViewModel()
    @State private var selectedFoodResult: FoodScan?
    @State private var nutrientPage: Int = 0

    var onViewFaceResult: (SkinScan) -> Void = { _ in }
    var onViewFoodResult: (FoodScan) -> Void = { _ in }
    var onScanMeal: () -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                topBar

                weekStrip

                heroRow
                skinNutrientsSection
                mealsSection
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.bottom, 120)
        }
        .background(GlowbiteColors.creamBG.ignoresSafeArea())
        .onAppear {
            viewModel.dataStore = dataStore
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
            onPageChanged: { _ in }
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
                        scan: viewModel.selectedDateScan,
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
        VStack(spacing: 8) {
            HStack {
                Text("SKIN NUTRIENTS")
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                Spacer()
            }

            TabView(selection: $nutrientPage) {
                nutrientRow(nutrients: viewModel.nutrientPages.indices.contains(0)
                    ? viewModel.nutrientPages[0] : [])
                    .tag(0)

                nutrientRow(nutrients: viewModel.nutrientPages.indices.contains(1)
                    ? viewModel.nutrientPages[1] : [])
                    .tag(1)

                lifeScorePage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 178)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(nutrientPage == index ? GlowbiteColors.coral : GlowbiteColors.lightTaupe.opacity(0.35))
                        .frame(width: 6, height: 6)
                        .animation(.easeOut(duration: 0.2), value: nutrientPage)
                }
            }
        }
    }

    private func nutrientRow(nutrients: [HomeViewModel.NutrientDisplayData]) -> some View {
        HStack(spacing: 8) {
            ForEach(nutrients) { nutrient in
                SkinNutrientCard(
                    label: nutrient.config.label,
                    remainingText: nutrient.remainingText,
                    statusLabel: nutrient.statusLabel,
                    isOver: nutrient.isOver,
                    descriptor: nutrient.config.descriptor,
                    signatureColor: nutrient.signatureColor,
                    signatureLightColor: nutrient.signatureLightColor,
                    barColor: nutrient.barColor,
                    progress: nutrient.progress
                )
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 2)
    }

    private var lifeScorePage: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("✦ LIFE SCORE")
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.coral)
                Spacer()
                Text("COMING SOON")
                    .font(.gbOverline)
                    .tracking(1.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("72")
                    .font(.gbDisplayM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                Text("/ 100")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }

            Text("Your overall wellness balance")
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.mediumTaupe)

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GlowbiteColors.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [GlowbiteColors.coral, GlowbiteColors.amberFair, GlowbiteColors.greenGood],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.72, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Glow + Nutrition + Habits")
                    .font(.gbOverline)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlowbiteColors.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(GlowbiteColors.border, lineWidth: 1)
        )
        .padding(.horizontal, 2)
    }

    // MARK: - Today's Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let meals = viewModel.selectedDateFoodScans.sorted { $0.createdAt < $1.createdAt }

            Text("\(viewModel.selectedDayName.uppercased()) · \(meals.count) MEALS")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)

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
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: coordinator.isActive)
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
