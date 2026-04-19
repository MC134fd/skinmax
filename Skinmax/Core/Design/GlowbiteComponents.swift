import SwiftUI

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Score Ring (gradient stroke, 12pt width)
struct ScoreRing: View {
    let score: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let trackColor: Color
    let showLabel: Bool

    init(score: Double, size: CGFloat = 140, lineWidth: CGFloat = 12, trackColor: Color = GlowbiteColors.softTan, showLabel: Bool = false) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.showLabel = showLabel
    }

    private var progress: Double { min(score / 100.0, 1.0) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    GlowbiteColors.heroGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            if showLabel {
                Text(String(format: "%.0f", score))
                    .font(.custom("Nunito-ExtraBold", size: size * 0.3))
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }
        }
    }
}

// MARK: - Week Day Strip (native scroll paging, Mon–Sun)
struct WeekDayStrip: View {
    let weeks: [[Date]]
    let currentWeekIndex: Int
    let selectedDate: Date
    let daysWithData: Set<Int>
    let onSelectDay: (Date) -> Void
    let onPageChanged: (Date) -> Void

    @State private var scrollPosition: Int?

    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                    weekRow(week)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition)
        .onAppear {
            scrollPosition = currentWeekIndex
        }
        .onChange(of: currentWeekIndex) { _, newIndex in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                scrollPosition = newIndex
            }
        }
        .onChange(of: scrollPosition) { _, newIndex in
            if let index = newIndex, index >= 0, index < weeks.count,
               let firstDay = weeks[index].first {
                onPageChanged(firstDay)
            }
        }
        .frame(height: 64)
    }

    // MARK: - Week Row

    private func weekRow(_ weekDays: [Date]) -> some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { date in
                let dayNum = calendar.component(.day, from: date)
                let hasData = daysWithData.contains(dayNum)
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())

                Button {
                    onSelectDay(date)
                } label: {
                    VStack(spacing: 4) {
                        Text(dayAbbreviation(date))
                            .font(.gbOverline)
                            .tracking(2.0)

                        Text("\(dayNum)")
                            .font(.gbBodyM)

                        Circle()
                            .fill(GlowbiteColors.coral)
                            .frame(width: 4, height: 4)
                            .opacity(hasData ? 1 : 0)
                    }
                    .foregroundStyle(
                        isSelected ? .white :
                        isFuture ? GlowbiteColors.lightTaupe.opacity(0.5) :
                        GlowbiteColors.warmBrown
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? GlowbiteColors.coral : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isToday && !isSelected ? GlowbiteColors.coral.opacity(0.5) : Color.clear,
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                            )
                    )
                }
                .disabled(isFuture)
            }
        }
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Tag Pill (fully rounded)
struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.gbCaption)
            .foregroundStyle(GlowbiteColors.coral)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(GlowbiteColors.peachWash.opacity(0.5))
            .clipShape(Capsule())
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(GlowbiteColors.peachWash)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(emoji)
                        .font(.gbTitleM)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text(message)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .lineSpacing(3)
            }
        }
        .padding(GlowbiteSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Tab Item
enum TabItem: Int, CaseIterable {
    case home, analytics, account

    var title: String {
        switch self {
        case .home: return "Home"
        case .analytics: return "Analytics"
        case .account: return "Account"
        }
    }

    var systemIcon: String {
        switch self {
        case .home: return "house.fill"
        case .analytics: return "chart.bar.fill"
        case .account: return "person.fill"
        }
    }
}

// MARK: - Scan Popup Overlay
struct ScanPopupOverlay: View {
    @Binding var isPresented: Bool
    var onScanFace: () -> Void
    var onLogFood: () -> Void

    var body: some View {
        ZStack {
            GlowbiteColors.darkBrown.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isPresented = false
                    }
                }

            VStack {
                Spacer()

                HStack(spacing: 14) {
                    // Scan Face bubble
                    Button {
                        HapticManager.impact(.light)
                        isPresented = false
                        onScanFace()
                    } label: {
                        VStack(spacing: 8) {
                            Text("\u{1F9D1}")
                                .font(.gbDisplayL)
                                .tracking(-1.0)
                            Text("Scan Face")
                                .font(.gbTitleM)
                                .foregroundStyle(GlowbiteColors.darkBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .fill(GlowbiteColors.peachWash.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }

                    // Log Food bubble
                    Button {
                        HapticManager.impact(.light)
                        isPresented = false
                        onLogFood()
                    } label: {
                        VStack(spacing: 8) {
                            Text("\u{1F37D}")
                                .font(.gbDisplayL)
                                .tracking(-1.0)
                            Text("Log Food")
                                .font(.gbTitleM)
                                .foregroundStyle(GlowbiteColors.darkBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .fill(GlowbiteColors.greenGood.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, GlowbiteSpacing.screenPadding)
                .padding(.bottom, 110)
            }
        }
        .transition(.opacity)
    }
}
